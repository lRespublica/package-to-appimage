#!/bin/bash 

# Checking if the plugin is correct
function plugin_is_correct()
{
    if [ $# -eq 1 ]
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

export TMPDIR=/tmp

# Declaration of parameters
DISTRIBUTION=""
PACKAGE=""
PACKAGE_FILE=""
PACKAGE_TYPE=""
PACKAGE_MANAGER_UPDATE=""
PACKAGE_MANAGER_REPO_INSTALL=""
PACKAGE_MANAGER_FILE_INSTALL=""
PLUGINS=""
PLUGINS_COUNT=0
KDE_ENABLED=""

while [ "$1" != "" ]
do
    case "$1" in 
    
    --distribution) if [ -n "$2" ]
                    then DISTRIBUTION="$2";

                    else printf "\tPlease, specify the distribution\n"; exit 1;
                fi;
                shift;shift;;

    --package-file) if [ -n "$2" ]
                    then PACKAGE_FILE="$2";

                    else printf "\tPlease, specify the package file\n"; exit 1;
                fi;
                shift;shift;;

    --package) if [ -n "$2" ]
                    then PACKAGE="$2";

                    else printf "\tPlease, specify the package\n"; exit 1;
                fi;
                shift;shift;;            

    --package-type) if [ -n "$2" ]
                    then PACKAGE_TYPE="$2";

                    else printf "\tPlease, specify the package type\n"; exit 1;
                fi;
                shift;shift;;

    --package-manager-update) if [ -n "$2" ]
                    then PACKAGE_MANAGER_UPDATE="$2";

                    else printf "\tPlease, specify the package manager update command\n"; exit 1;
                fi;
                shift;shift;;

    --package-manager-repo-install) if [ -n "$2" ]
                    then PACKAGE_MANAGER_REPO_INSTALL="$2";

                    else printf "\tPlease, specify the package manager command to install from repository \n"; exit 1;
                fi;
                shift;shift;;

    --package-manager-file-install) if [ -n "$2" ]
                    then PACKAGE_MANAGER_FILE_INSTALL="$2";

                    else printf "\tPlease, specify the package manager command to install from file \n"; exit 1;
                fi;
                shift;shift;;

    --mount-directory) if [ -n "$2" ]
                then MOUNT_DIRECTORY="$2";

                else printf "\tPlease, specify the mount directory\n"; exit 1;
                fi;
                shift;shift;;

    --plugin)  if [ -n "$2" ] && [ "$(plugin_is_correct "$2")" = "1" ]
                    then PLUGINS[PLUGINS_COUNT]="$2";
                        PLUGINS_COUNT=$((PLUGINS_COUNT + 1));

                    else printf "\tPlease, specify the plugin. $2 is not correct plugin\n";exit 1;
                fi;            
                shift;shift;;

    --kde)  KDE_ENABLED="--kde";
            shift;;

    *) printf "$1 is not an option\n"; exit 1;;
    esac
done

# Adding plugins with argument, like --plugin qt
plugins_with_arguments=""
for plugin in ${PLUGINS[*]}
    do plugins_with_arguments+=" --plugin "
       plugins_with_arguments+="${plugin}"
done

# Fixes the name of the distribution by removing the docker tag from there
DISTRIBUTION=$(printf "$DISTRIBUTION" | cut -d ':' -f 1)

if [ "$DISTRIBUTION" = "ubuntu" ] || [ "$DISTRIBUTION" = "debian" ]   
then
    export DEBIAN_FRONTEND=noninteractive                           # For noninteractive installation of tzdata and keyboard-configuration
fi
# Updating information about repositories 
$PACKAGE_MANAGER_UPDATE

# Installing additional dependencies
$PACKAGE_MANAGER_REPO_INSTALL wget file cpio

if [ "$DISTRIBUTION" = "alt" ]
    then $PACKAGE_MANAGER_REPO_INSTALL icon-theme-adwaita
elif [ "$DISTRIBUTION" = "fedora" ] || [ "$DISTRIBUTION" = "opensuse" ] || [ "$DISTRIBUTION" = "centos" ] || [ "$DISTRIBUTION" = "mageia" ] || [ "$DISTRIBUTION" = "debian:testing
" ]
    then $PACKAGE_MANAGER_REPO_INSTALL adwaita-icon-theme
elif [ "$DISTRIBUTION" = "ubuntu" ] 
    then $PACKAGE_MANAGER_REPO_INSTALL adwaita-icon-theme-full 
fi

# Installing required package
$PACKAGE_MANAGER_FILE_INSTALL /mnt/"$PACKAGE_FILE"

#Preparing LinuxDeploy
cd $TMPDIR
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
        then $PACKAGE_MANAGER_REPO_INSTALL qtbase5-dev qtbase5-dev-tools qtpositioning5-dev libqt5sql5-mysql libqt5texttospeech5-dev libqt5multimedia5-plugins
        fi

        cd $TMPDIR/linuxdeploy/plugins
        wget https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
        chmod +x ./linuxdeploy-plugin-qt-x86_64.AppImage && ./linuxdeploy-plugin-qt-x86_64.AppImage --appimage-extract 
        mv ./squashfs-root ./linuxdeploy-plugin-qt
        cd -
        ln -s $TMPDIR/linuxdeploy/plugins/linuxdeploy-plugin-qt/AppRun $TMPDIR/linuxdeploy/usr/bin/linuxdeploy-plugin-qt

    elif [[ "$plugin" = "gtk" ]]
        #Downloading gtk plugin and adding it in linuxdeploy
        then

        #Installing dependencies
        if [ "$DISTRIBUTION" = "alt" ]
        then $PACKAGE_MANAGER_REPO_INSTALL libgtk+3-devel librsvg-devel patchelf gobject-introspection-devel
        elif [ "$DISTRIBUTION" = "fedora" ] || [ "$DISTRIBUTION" = "opensuse" ] || [ "$DISTRIBUTION" = "centos" ] || [ "$DISTRIBUTION" = "mageia" ]
        then $PACKAGE_MANAGER_REPO_INSTALL gtk3-devel librsvg2-devel patchelf gobject-introspection-devel
        elif [ "$DISTRIBUTION" = "ubuntu" ] || [ "$DISTRIBUTION" = "debian" ]
        then $PACKAGE_MANAGER_REPO_INSTALL libgtk-3-dev librsvg2-dev pkg-config patchelf libgirepository1.0-dev
        fi

        cd $TMPDIR/linuxdeploy/usr/bin/ && wget https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh
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
        cd $TMPDIR/linuxdeploy/usr/bin/ && wget https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-ncurses/master/linuxdeploy-plugin-ncurses.sh 
        chmod +x ./linuxdeploy-plugin-ncurses.sh && cd -
    elif [[ "$plugin" = "gstreamer" ]]
        #Downloading gstreamer plugin and adding it in linuxdeploy
        then

        if [ "$DISTRIBUTION" = "alt" ] || [ "$DISTRIBUTION" = "fedora" ] || [ "$DISTRIBUTION" = "opensuse" ] || [ "$DISTRIBUTION" = "centos" ] || [ "$DISTRIBUTION" = "mageia" ]
        then $PACKAGE_MANAGER_REPO_INSTALL gstreamer-devel patchelf
        elif [ "$DISTRIBUTION" = "ubuntu" ] || [ "$DISTRIBUTION" = "debian" ]
        then $PACKAGE_MANAGER_REPO_INSTALL libgstreamer1.0-dev patchelf 
        fi

        cd $TMPDIR/linuxdeploy/usr/bin/ && wget https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gstreamer/master/linuxdeploy-plugin-gstreamer.sh
        chmod +x ./linuxdeploy-plugin-gstreamer.sh && cd -
    fi
done

# Preparing AppDir
mkdir $TMPDIR/AppDir

# Unpack package
/mnt/unpack.sh -D $TMPDIR/AppDir --with-dependencies --package-type $PACKAGE_TYPE "$PACKAGE" &> /dev/null

if [ "$KDE_ENABLED" != "" ]
then
    if [ "$DISTRIBUTION" = "alt"  ]
    then
        $PACKAGE_MANAGER_REPO_INSTALL kde5-runtime
        /mnt/unpack.sh --package-type $PACKAGE_TYPE -D $TMPDIR/AppDir -q --with-dependencies kde5-runtime &> /dev/null
    fi

    if [ "$PACKAGE_TYPE" == "RPM" ]
    then
        cp -r $TMPDIR/AppDir/usr/lib64/qt5/plugins/ $TMPDIR/AppDir/usr/plugins

    else
        cp -r $TMPDIR/AppDir/usr/lib/x86_64-linux-gnu/qt5/plugins/ $TMPDIR/AppDir/usr/plugins
    fi
fi

if [ "$PACKAGE_TYPE" = "RPM" ]
then
    GET_FILES_LIST_COMMAND="rpmquery --list"
elif [ "$PACKAGE_TYPE" = "DEB" ]
then
    GET_FILES_LIST_COMMAND="dpkg -L"
else
    printf "Error unknown package type $PACKAGE_TYPE\n"
fi

# Getting desktop file of package
DESKTOP_FILE+="$TMPDIR/AppDir"
DESKTOP_FILE+=$($GET_FILES_LIST_COMMAND "$PACKAGE" | grep -e "application" | grep -e ".desktop" -m 1)

# Parsing it for executable, icon and name
PACKAGE_NAME=$(cat "$DESKTOP_FILE" | grep -e ^Exec= -m 1 | sed 's/Exec=//g' | cut -d' ' -f1 | sed 's/ /_/g')

PACKAGE_TITLE=$(cat "$DESKTOP_FILE" | grep -e ^Name= -m 1 | sed 's/Name=//g')

ICON_NAME=$(cat "$DESKTOP_FILE" | grep -e ^Icon= -m 1 | sed 's/Icon=//g')

ICON+="$TMPDIR/AppDir"
ICON+=$($GET_FILES_LIST_COMMAND "$PACKAGE" | grep -e "icon" | grep -v "1024x1024" | grep -e "$ICON_NAME".png -m 1)

# WARNING, IT IS A KLUDGE
if [ -f "$ICON_NAME" ]                                                                                              # If icon name is a file
then                                                                                                                # For case like "/usr/share/icons/breeze/applets/16/car.svg"
    ICON=$TMPDIR/AppDir$(printf "$ICON_NAME" | sed 's/\/[^/]*$//')/"$PACKAGE".$(echo "$ICON_NAME" | sed 's/^.*\.//')     # New icon file should have be in same dir with older one, and have same extension, but different name
    mv $TMPDIR/AppDir"$ICON_NAME" "$ICON"                                                                              # Move icon with same name as package. Required for auto-generated .desktop file
    ICON_NAME=$PACKAGE                                                                                              # Turn "/usr/share/icons/breeze/applets/16/car.svg" into "car"
    DESKTOP_FILE="$TMPDIR/AppDir"                                                                                      # Clean desktop file, instead of the existing one create a new one
fi
# END OF WARNING          

# Finding executable and icon files
EXECUTABLE+="$TMPDIR/AppDir"
EXECUTABLE+=$($GET_FILES_LIST_COMMAND $PACKAGE | grep -e /bin/ | grep -e "$PACKAGE_NAME$" -m 1 )

if [ "$EXECUTABLE" = "$TMPDIR/AppDir" ]
    then
    printf "Executable not found, searching by the name of package...\n"
    EXECUTABLE+=$($GET_FILES_LIST_COMMAND "$PACKAGE" | grep -e /bin/ | grep -e "$PACKAGE$" -m 1)

    # Clear desktop file information to create a new one when creating appimage
    DESKTOP_FILE="$TMPDIR/AppDir"
    PACKAGE_NAME=$PACKAGE
    
    if [ "$EXECUTABLE" = "$TMPDIR/AppDir" ]
        then
        printf "Executable not found, appimage creation aborted...\n"
        exit 1
    fi
fi

# If icon is not found
if [ "$ICON" = "$TMPDIR/AppDir" ]
    then
    # Set adwaita icon as default
    # If there are no Icon name
    if [ "$ICON_NAME" = "" ]
        then
        # Set same name like package
        ICON_NAME="$PACKAGE"
    fi
    mkdir $TMPDIR/AppDir/usr/share/icons
    cp /usr/share/icons/Adwaita/512x512/places/folder-documents.png $TMPDIR/AppDir/usr/share/icons/"$ICON_NAME".png
    ICON="$TMPDIR/AppDir/usr/share/icons/$ICON_NAME.png"
fi

# If desktop file not contains "Categories" key value, then use --create-desktop-file flag for linuxdeploy
if [ "$(grep -e "Categories=" $DESKTOP_FILE)" = "" ]
then
    DESKTOP_FILE="$TMPDIR/AppDir"
fi

LINUXDEPLOY=$TMPDIR/linuxdeploy/AppRun 

# If there are no desktop file
if [ "$DESKTOP_FILE" = "$TMPDIR/AppDir" ]
    then
    # Use --create-desktop-file option
    printf "$TMPDIR/linuxdeploy/AppRun --appdir $TMPDIR/AppDir --executable $EXECUTABLE --create-desktop-file --icon-file $ICON $plugins_with_arguments --output appimage\n"
    cd $TMPDIR && $LINUXDEPLOY --appdir $TMPDIR/AppDir/ --executable "$EXECUTABLE" --create-desktop-file --icon-file "$ICON" $plugins_with_arguments --output appimage
else
    # Use .desktop file if it exists
    printf "$TMPDIR/linuxdeploy/AppRun --appdir $TMPDIR/AppDir --executable $EXECUTABLE --desktop-file $DESKTOP_FILE --icon-file $ICON $plugins_with_arguments --output appimage\n"
    cd $TMPDIR && $LINUXDEPLOY --appdir $TMPDIR/AppDir/ --executable "$EXECUTABLE" --desktop-file "$DESKTOP_FILE" --icon-file "$ICON" $plugins_with_arguments --output appimage
fi

# Copy AppImage file to host directory
cp $TMPDIR/*.AppImage /mnt/

printf "\n\nNow you can find your AppImage in $MOUNT_DIRECTORY/$(ls /mnt/ | grep -e "$PACKAGE_TITLE" -m 1)\n"
