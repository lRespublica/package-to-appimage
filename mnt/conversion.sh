#!/bin/bash 

# Checking if the plugin is correct
function plugin_is_correct()
{
    if [[ $# -eq 1 ]]
    then 
        for plugin in qt python gtk ncurses gstreamer
        do 
            if [[ "$1" = "$plugin" ]]
                then echo 1; exit;
            fi
        done
        echo 0; exit;
    else echo 0; exit;
    fi
}

# Declaration of parameters
DISTRIBUTION=""
PACKAGE=""
PACKAGE_FILE=""
PACKAGE_NAME=""
PACKAGE_TYPE=""
PACKAGE_MANAGER_UPDATE=""
PACKAGE_MANAGER_REPO_INSTALL=""
PACKAGE_MANAGER_FILE_INSTALL=""
PLUGINS=""
PLUGINS_COUNT=0

while [ \"$1\" != \"\" ]
do
    case "$1" in 
    
    --distribution) if [ -n "$2" ]
                    then DISTRIBUTION="$2";

                    else echo -e "\tPlease, specify the distribution"; exit 1;
                fi;
                shift;shift;;

    --package-file) if [ -n "$2" ]
                    then PACKAGE_FILE="$2";

                    else echo -e "\tPlease, specify the package file"; exit 1;
                fi;
                shift;shift;;

    --package) if [ -n "$2" ]
                    then PACKAGE="$2";

                    else echo -e "\tPlease, specify the package"; exit 1;
                fi;
                shift;shift;;            

    --package-type) if [ -n "$2" ]
                    then PACKAGE_TYPE="$2";

                    else echo -e "\tPlease, specify the package type"; exit 1;
                fi;
                shift;shift;;

    --package-manager-update) if [ -n "$2" ]
                    then PACKAGE_MANAGER_UPDATE="$2";

                    else echo -e "\tPlease, specify the package manager update command"; exit 1;
                fi;
                shift;shift;;

    --package-manager-repo-install) if [ -n "$2" ]
                    then PACKAGE_MANAGER_REPO_INSTALL="$2";

                    else echo -e "\tPlease, specify the package manager command to install from repository "; exit 1;
                fi;
                shift;shift;;

    --package-manager-file-install) if [ -n "$2" ]
                    then PACKAGE_MANAGER_FILE_INSTALL="$2";

                    else echo -e "\tPlease, specify the package manager command to install from file "; exit 1;
                fi;
                shift;shift;;

    --plugin)  if [ -n "$2" ] && [[ $(plugin_is_correct "$2") = "1" ]]
                    then PLUGINS[PLUGINS_COUNT]="$2";
                        PLUGINS_COUNT=$(($PLUGINS_COUNT + 1));

                    else echo -e "\tPlease, specify the plugin. $2 is not correct plugin";exit 1;
                fi;            
                shift;shift;;

    *) echo -e "$1 is not an option"; exit 1;;
    esac
done

# Adding plugins with argument, like --plugin qt
plugins_with_arguments=""
for plugin in ${PLUGINS[*]}
    do plugins_with_arguments+=" --plugin "
       plugins_with_arguments+="${plugin}"
done

# Fixes the name of the distribution by removing the docker tag from there
DISTRIBUTION=$(echo "$DISTRIBUTION" | awk -F : '{ print $1 }')

# Updating information about repositories 
$PACKAGE_MANAGER_UPDATE

# Installing additional dependencies
$PACKAGE_MANAGER_REPO_INSTALL wget file cpio

if [ "$DISTRIBUTION" = "alt" ]
    then $PACKAGE_MANAGER_REPO_INSTALL icon-theme-adwaita
elif [ "$DISTRIBUTION" = "fedora" ] || [ "$DISTRIBUTION" = "opensuse" ] || [ "$DISTRIBUTION" = "centos" ] || [ "$DISTRIBUTION" = "mageia" ] || [ "$DISTRIBUTION" = "debian" ]
    then $PACKAGE_MANAGER_REPO_INSTALL adwaita-icon-theme
elif [ "$DISTRIBUTION" = "ubuntu" ] 
    then $PACKAGE_MANAGER_REPO_INSTALL adwaita-icon-theme-full
fi

# DEBIAN_FRONTEND variable for installation of tzdata without interactive choice
# Installing required package
DEBIAN_FRONTEND=noninteractive $PACKAGE_MANAGER_FILE_INSTALL /mnt/$PACKAGE_FILE

#Preparing LinuxDeploy
cd /tmp
wget -c -N https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x ./linuxdeploy-x86_64.AppImage
./linuxdeploy-x86_64.AppImage --appimage-extract
mv ./squashfs-root ./linuxdeploy
rm -f linuxdeploy-x86_64.AppImage
cd -

# Adding plugins in linuxdeploy
for plugin in ${PLUGINS[*]}
    do

    if [ "$plugin" = "qt" ] 
        # Downloading qt plugin and adding it in linuxdeploy 
        then

        #Installing dependencies
        if [ "$DISTRIBUTION" = "alt" ]
        then $PACKAGE_MANAGER_REPO_INSTALL qt5-base-devel qt5-declarative-devel
        elif [ "$DISTRIBUTION" = "fedora" ] || [ "$DISTRIBUTION" = "centos" ]
        then $PACKAGE_MANAGER_REPO_INSTALL qt5-qtbase-devel qt5-qtdeclarative-devel
        elif [ "$DISTRIBUTION" = "opensuse" ]
        then $PACKAGE_MANAGER_REPO_INSTALL libqt5-qtbase-devel libqt5-qtdeclarative-devel
        elif [ "$DISTRIBUTION" = "mageia" ]
        then $PACKAGE_MANAGER_REPO_INSTALL libqwt-qt5-devel
        elif [ "$DISTRIBUTION" = "ubuntu" ] || [ "$DISTRIBUTION" = "debian" ]
        then $PACKAGE_MANAGER_REPO_INSTALL qtbase5-dev qtbase5-dev-tools
        fi

        cd /tmp/linuxdeploy/plugins
        wget https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
        chmod +x ./linuxdeploy-plugin-qt-x86_64.AppImage && ./linuxdeploy-plugin-qt-x86_64.AppImage --appimage-extract 
        mv ./squashfs-root ./linuxdeploy-plugin-qt
        cd -
        ln -s /tmp/linuxdeploy/plugins/linuxdeploy-plugin-qt/AppRun /tmp/linuxdeploy/usr/bin/linuxdeploy-plugin-qt

    elif [[ "$plugin" = "gtk" ]]
        #Downloading gtk plugin and adding it in linuxdeploy
        then

        #Installing dependencies
        if [ "$DISTRIBUTION" = "alt" ]
        then $PACKAGE_MANAGER_REPO_INSTALL libgtk+3-devel librsvg-devel patchelf
        elif [ "$DISTRIBUTION" = "fedora" ] || [ "$DISTRIBUTION" = "opensuse" ] || [ "$DISTRIBUTION" = "centos" ] || [ "$DISTRIBUTION" = "mageia" ]
        then $PACKAGE_MANAGER_REPO_INSTALL gtk3-devel librsvg2-devel patchelf
        elif [ "$DISTRIBUTION" = "ubuntu" ] || [ "$DISTRIBUTION" = "debian" ]
        then $PACKAGE_MANAGER_REPO_INSTALL libgtk3-dev librsvg2-dev patchelf
        fi

        cd /tmp/linuxdeploy/usr/bin/ && wget https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh
        chmod +x ./linuxdeploy-plugin-gtk.sh && cd -

    elif [[ "$plugin" = "ncurses" ]]
        #Downloading ncurses plugin and adding it in linuxdeploy

        if [ "$DISTRIBUTION" = "alt" ]
        then $PACKAGE_MANAGER_REPO_INSTALL libncurses-devel libncurses++-devel termutils-devel
        elif [ "$DISTRIBUTION" = "fedora" ] || [ "$DISTRIBUTION" = "centos" ]
        then $PACKAGE_MANAGER_REPO_INSTALL ncurses-devel ncurses-c++-libs
        elif [ "$DISTRIBUTION" = "opensuse" ] || [ "$DISTRIBUTION" = "mageia" ]
        then $PACKAGE_MANAGER_REPO_INSTALL ncurses-devel 
        elif [ "$DISTRIBUTION" = "ubuntu" ] || [ "$DISTRIBUTION" = "debian" ]
        then $PACKAGE_MANAGER_REPO_INSTALL libncurses5-dev libncursesw5-dev
        fi

        then
        cd /tmp/linuxdeploy/usr/bin/ && wget https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-ncurses/master/linuxdeploy-plugin-ncurses.sh 
        chmod +x ./linuxdeploy-plugin-ncurses.sh && cd -
    elif [[ "$plugin" = "gstreamer" ]]
        #Downloading gstreamer plugin and adding it in linuxdeploy
        then

        if [ "$DISTRIBUTION" = "alt" ] || [ "$DISTRIBUTION" = "fedora" ] || [ "$DISTRIBUTION" = "opensuse" ] || [ "$DISTRIBUTION" = "centos" ] || [ "$DISTRIBUTION" = "mageia" ]
        then $PACKAGE_MANAGER_REPO_INSTALL gstreamer-devel patchelf
        elif [ "$DISTRIBUTION" = "ubuntu" ] || [ "$DISTRIBUTION" = "debian" ]
        then $PACKAGE_MANAGER_REPO_INSTALL libgstreamer1.0-dev patchelf
        fi

        cd /tmp/linuxdeploy/usr/bin/ && wget https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gstreamer/master/linuxdeploy-plugin-gstreamer.sh
        chmod +x ./linuxdeploy-plugin-gstreamer.sh && cd -
    fi
done


# Preparing AppDir
mkdir /tmp/AppDir

# Starting conversion
/mnt/conversion-$PACKAGE_TYPE.sh --package-file $PACKAGE_FILE --package $PACKAGE --distribution $DISTRIBUTION $plugins_with_arguments

# Copy AppImage file to host directory
cp /tmp/*.AppImage /mnt/

echo -e "\n\nNow you can find your AppImage in /tmp/mount/$(ls /mnt/ | grep -e $PACKAGE_TITLE -m 1)"