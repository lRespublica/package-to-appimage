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

# Updating information about repositories 
$PACKAGE_MANAGER_UPDATE

# Installing wget
$PACKAGE_MANAGER_REPO_INSTALL wget file cpio

# Installing required package
$PACKAGE_MANAGER_FILE_INSTALL /mnt/$PACKAGE_FILE

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
        elif [ "$DISTRIBUTION" = "fedora" ]
        then $PACKAGE_MANAGER_REPO_INSTALL qt5-qtbase-devel qt5-qtdeclarative-devel
        elif [ "$DISTRIBUTION" = "opensuse" ]
        then $PACKAGE_MANAGER_REPO_INSTALL libqt5-qtbase-devel libqt5-qtdeclarative-devel
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
        elif [ "$DISTRIBUTION" = "fedora" ] || [ "$DISTRIBUTION" = "opensuse" ]
        then $PACKAGE_MANAGER_REPO_INSTALL gtk3-devel librsvg2-devel patchelf
        fi

        cd /tmp/linuxdeploy/usr/bin/ && wget https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh
        chmod +x ./linuxdeploy-plugin-gtk.sh && cd -

    elif [[ "$plugin" = "ncurses" ]]
        #Downloading ncurses plugin and adding it in linuxdeploy

        if [ "$DISTRIBUTION" = "alt" ]
        then $PACKAGE_MANAGER_REPO_INSTALL libncurses-devel libncurses++-devel termutils-devel
        elif [ "$DISTRIBUTION" = "fedora" ]
        then $PACKAGE_MANAGER_REPO_INSTALL ncurses-devel ncurses-c++-libs
        elif [ "$DISTRIBUTION" = "opensuse" ]
        then $PACKAGE_MANAGER_REPO_INSTALL ncurses-devel 
        fi

        then
        cd /tmp/linuxdeploy/usr/bin/ && wget https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-ncurses/master/linuxdeploy-plugin-ncurses.sh 
        chmod +x ./linuxdeploy-plugin-ncurses.sh && cd -
    elif [[ "$plugin" = "gstreamer" ]]
        #Downloading gstreamer plugin and adding it in linuxdeploy
        then

        if [ "$DISTRIBUTION" = "alt" ]
        then $PACKAGE_MANAGER_REPO_INSTALL gstreamer-devel patchelf
        elif [ "$DISTRIBUTION" = "fedora" ] || [ "$DISTRIBUTION" = "opensuse" ]
        then $PACKAGE_MANAGER_REPO_INSTALL gstreamer-devel patchelf
        fi

        cd /tmp/linuxdeploy/usr/bin/ && wget https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gstreamer/master/linuxdeploy-plugin-gstreamer.sh
        chmod +x ./linuxdeploy-plugin-gstreamer.sh && cd -
    fi
done



# Preparing AppDir
mkdir /tmp/AppDir

# Declaration of parameters
DESKTOP_FILE=""
PACKAGE_NAME=""
PACKAGE_TITLE=""
ICON_NAME=""
EXECUTABLE=""
ICON=""


if [[ $PACKAGE_TYPE = "RPM" ]]
    then
    # Unpacking archive
    cd /tmp/AppDir && rpm2cpio /mnt/$PACKAGE_FILE | cpio -idmv && cd -

    # Getting desktop file of package
    DESKTOP_FILE+="/tmp/AppDir"
    DESKTOP_FILE+=$(rpmquery --list $PACKAGE | grep -e .desktop -m 1)

    echo "DESKTOP_FILE=$DESKTOP_FILE"

    # Parsing it for executable, icon and name
    PACKAGE_NAME=$(cat $DESKTOP_FILE | grep -e ^Exec= -m 1 | sed 's/Exec=//g' | cut -d' ' -f1 | sed 's/ /_/g')
    echo "PACKAGE_NAME=$PACKAGE_NAME"
    
    PACKAGE_TITLE=$(cat $DESKTOP_FILE | grep -e ^Name= -m 1 | sed 's/Name=//g')
    echo "PACKAGE_TITLE=$PACKAGE_TITLE"

    ICON_NAME=$(cat $DESKTOP_FILE | grep -e ^Icon= -m 1 | sed 's/Icon=//g')
    echo "ICON_NAME=$ICON_NAME"

    # Finding executable and icon files
    EXECUTABLE+="/tmp/AppDir"
    EXECUTABLE+=$(rpmquery --list $PACKAGE | grep -e /bin/$PACKAGE_NAME -m 1)
    echo "EXECUTABLE=$EXECUTABLE"

    ICON+="/tmp/AppDir"
    ICON+=$(rpmquery --list $PACKAGE | grep -e $ICON_NAME.png -m 1)
    echo "ICON=$ICON"

    # If icon is not found
    if [[ "$ICON" = "/tmp/AppDir" ]]
        then
        # Install adwaita icons
        echo "Icon not found"

        if [ "$DISTRIBUTION" = "alt" ]
        then $PACKAGE_MANAGER_REPO_INSTALL icon-theme-adwaia
        elif [ "$DISTRIBUTION" = "fedora" ] || [ "$DISTRIBUTION" = "opensuse" ]
        then $PACKAGE_MANAGER_REPO_INSTALL adwaita-icon-theme
        fi
        
        # And set is as default
        # If there are no Icon name
        if [[ "$ICON_NAME" = "" ]]
        then
            # Set same name like 
            ICON_NAME="$PACKAGE"
        fi
        mkdir /tmp/AppDir/usr/share/icons
        cp /usr/share/icons/Adwaita/256x256/legacy/user-info.png /tmp/AppDir/usr/share/icons/$ICON_NAME.png
        ICON="/tmp/AppDir/usr/share/icons/$ICON_NAME.png"
    fi

    else
    echo "$PACKAGE_TYPE is wrong type of package"
fi

# If there are no desktop file
if [ "$DESKTOP_FILE" = "/tmp/AppDir" ]
    then
    # Use --create-desktop-file option
    echo "/tmp/linuxdeploy/AppRun --appdir /tmp/AppDir --executable $EXECUTABLE --create-desktop-file --icon-file $ICON $plugins_with_arguments --output appimage"
    cd /tmp && /tmp/linuxdeploy/AppRun --appdir /tmp/AppDir/ --executable $EXECUTABLE --create-desktop-file --icon-file $ICON $plugins_with_arguments --output appimage
    else
    # Use .desktop file if it exists
    echo "/tmp/linuxdeploy/AppRun --appdir /tmp/AppDir --executable $EXECUTABLE --desktop-file $DESKTOP_FILE --icon-file $ICON $plugins_with_arguments --output appimage"
    cd /tmp && /tmp/linuxdeploy/AppRun --appdir /tmp/AppDir/ --executable $EXECUTABLE --desktop-file $DESKTOP_FILE --icon-file $ICON $plugins_with_arguments --output appimage
fi

# Copy AppImage file to host directory
cp /tmp/*.AppImage /mnt/

echo -e "\n\nNow you can find your AppImage in ./mnt/$(ls /mnt/ | grep -e $PACKAGE_TITLE -m 1)"