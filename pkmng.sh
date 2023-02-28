#!/bin/bash

#whiptail --msgbox --title "This is a title" --backtitle "I'm a backtitle" --fb "Hello, world!" 10 50

name="GOAT package installer"
working_directory="/usr/local/src"


echo "checking permissions..." 
permissions=$(stat -c '%a' $working_directory)

# If permission is not sufficien, try to change it or advice user to run script with sudo privileges
if [ "$permissions" -lt "777" ]; then
    if chmod 777 $working_directory; then 
        echo "Changed permissions"
    else
        echo "Run script with sudo privileges"
        exit 1
    fi
fi

# Take package name as input and create directory 
input_package_name=$(whiptail --inputbox --title "$name" "Choose a package name" 10 70 3>&1 1>&2 2>&3)

function clean_up(){
    package=$working_directory/$input_package_name
    rm -rf --no-preserve-root "$package"
}

# Create working directory for package installation files
mkdir -p $working_directory/"$input_package_name"

installation_method=$(whiptail \
                                --title "$name"  \
                                --menu "Choose installation method" \
                                15 60 4 \
                                "1" "Install from source code" \
                                "2" "Install from dpkg/rpm" \
                                3>&1 1>&2 2>&3)

    case $installation_method in
    1)
# Install from source code
    #local_or_remote_installation

        local_or_remote_source=$(whiptail \
                                        --title "$name"  \
                                        --menu "Local or remote source?" \
                                        15 60 4 \
                                        "1" "Install from local tarball" \
                                        "2" "Install from remote tarball" \
                                        3>&1 1>&2 2>&3)

        case $local_or_remote_source in
        1)
            # Local tarball installation
            path_to_local_tarball=$(whiptail --inputbox --title "Installation with dpkg/rpm" "Path to local tarball" 10 70 3>&1 1>&2 2>&3)
        ;;

        2)
            # Remote tarball installation
            link_to_remote_tarball=$(whiptail --inputbox --title "Installation with dpkg/rpm" "Link to remote tarball" 10 70 3>&1 1>&2 2>&3)
            if ! wget -P $working_directory/"$input_package_name" "$link_to_remote_tarball"; then
                clean_up
                exit 5
            fi
            filename=$(ls $working_directory/"$input_package_name"/)

            # Check which is compression used
            if [[ $filename = *.tar.gz ]]; then
                echo ".gz file compression detected"
                tar zxvf $working_directory/"$input_package_name"/"$filename"

            elif [[ $filename = *.tar.bz2 ]]; then
                echo ".bz2 file compression detected"
                tar jxvf $working_directory/"$input_package_name"/"$filename" --directory=$working_directory/"$input_package_name"/
                rm $working_directory/"$input_package_name"/"$filename"
                extraction_directory=$(ls $working_directory/"$input_package_name"/)
                echo "ECEX: " "$extraction_directory"
                cd $working_directory/"$input_package_name"/"$extraction_directory" || exit
                ./configure

                if cd $working_directory/"$input_package_name"/"$extraction_directory" || exit; make; then
                    echo "Dependency requirement met"
                    make install
                else
                    echo "Install required dependencies and run script again"
                    exit 6
                fi
                

            elif [[ $filename = *.tar.xz ]]; then
                echo ".xz file compression detected"
                tar jxvf "$filename"

            else
                echo "This package manager does not support extration of $filename"
                rm -rf "$filename"
            fi

        ;;
        esac
        ;;

# Install with dpkg/rpm
    2)  
        link_to_deb_rpm=$(whiptail --inputbox --title "Installation with dpkg/rpm" "link to deb/rpm file" 10 70 3>&1 1>&2 2>&3)
        
        if ! wget -P $working_directory/"$input_package_name" "$link_to_deb_rpm"; then
            clean_up
            exit 4
        fi
        if find $working_directory/"$input_package_name"/*.rpm; then

            # Check if alien is installed on the system, if not, promt the user to intall it.
            if dpkg -s alien; then
            echo "converting .rpm to .deb package..." 
            else echo -e "
            \a \033[0;31m Alien needs to be installed on the system in order for this intaller to handle .rpm packages. 

                    The dependency can be installed with sudo apt install alien.
                    "
                clean_up
                exit 2;
            fi

            filename=$(find $working_directory/"$input_package_name"/*.rpm)

            if alien "$filename";  then
                downloaded_filename=$(find *.deb)
                echo "Convertion to .deb completed"
                mv "$downloaded_filename" /$working_directory/"$input_package_name"/
                rm "$filename"
            else
                clean_up
                exit 3
            fi
        fi
        if find $working_directory/"$input_package_name"/*.deb; then
            filename=$(find $working_directory/"$input_package_name"/*.deb)
            if dpkg -i "$filename"; then
                echo "Installation successfull"
            fi
        fi
        ;;
    esac