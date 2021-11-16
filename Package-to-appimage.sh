#!/bin/bash

# Help function
function help()
{
    echo -e '\n\t--package [package.rpm, package.deb] \t specify the package to repackage'
    echo -e '\t--plugin [plugin]\t\t\t specify the plugin to use\n\t\t\t\t\t\t available plugins - qt gtk ncurses gstreamer'
}

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
PACKAGE=""
PLUGINS=""
PLUGINS_COUNT=0      

PACKAGE_TYPE=""

DISTRIBUTION=""
PACKAGE_MANAGER_FILE_INSTALL=""
PACKAGE_MANAGER_REPO_INSTALL=""
PACKAGE_MANAGER_UPDATE=""
VENDOR=""

# Close programm without arguments
if [ $# -eq 0 ]
then
    echo "There is no parameters"
    help
    exit 1
fi

# Enumerating options
while [ \"$1\" != \"\" ]
do
    case "$1" in 
    --package) if [ -n "$2" ]
                    then PACKAGE="$2";

                    else echo -e "\tPlease, specify the package"; exit 1;
                fi;
                shift;shift;;

    --plugin)  if [ -n "$2" ] && [[ $(plugin_is_correct "$2") = "1" ]]
                    then PLUGINS[PLUGINS_COUNT]="$2";
                        PLUGINS_COUNT=$(($PLUGINS_COUNT + 1));

                    else echo -e "\tPlease, specify the plugin. $2 is not correct plugin";exit 1;
                fi;            
                shift;shift;;

    --help) help;exit;;

    *) echo -e "$1 is not an option"; exit 1;;
    esac
done

# Adding plugins with argument, like --plugin qt
plugins_with_arguments=""
for plugin in ${PLUGINS[*]}
    do plugins_with_arguments+=" --plugin "
       plugins_with_arguments+="${plugin}"
done

# Checking if package exist and correct
if [ ! -f "$PACKAGE" ]
then echo -e "\tPackage is not exist"; exit 1;
fi

if [ "$PACKAGE" = \"\" ]
then echo -e "\tPlease, specify the package"; exit 1;
fi

# Parsing metadata
PACKAGE_TYPE=$(file -b "$PACKAGE" | cut -c 1-3)
if [ $PACKAGE_TYPE = "RPM" ]
    then 
    VENDOR=$(rpm -qip "$PACKAGE" | grep -e "Vendor" | awk -F : '{ print $2 }' | cut -c2-)
    PACKAGE_NAME=$(rpm -qip "$PACKAGE" | grep -e "Name" | awk -F : '{ print $2 }' | cut -c2-)

    if [ "$VENDOR" = "ALT Linux Team" ]
        then
        DISTRIBUTION="alt"
        PACKAGE_MANAGER_UPDATE="apt-get update"
        PACKAGE_MANAGER_REPO_INSTALL="apt-get install -y"
        PACKAGE_MANAGER_FILE_INSTALL="apt-get install -fy"
    elif [ "$VENDOR" = "Fedora Project" ]
        then
        DISTRIBUTION="fedora"
        PACKAGE_MANAGER_UPDATE="dnf update -y"
        PACKAGE_MANAGER_REPO_INSTALL="dnf install -y"
        PACKAGE_MANAGER_FILE_INSTALL="dnf install -y"
    elif [ "$VENDOR" = "openSUSE" ]
        then
        DISTRIBUTION="opensuse/leap"
        PACKAGE_MANAGER_UPDATE="zypper update -y"
        PACKAGE_MANAGER_REPO_INSTALL="zypper install -y"
        PACKAGE_MANAGER_FILE_INSTALL="zypper install -y"
    else
        echo "ERROR: Unsupported vendor"
        exit 1
    fi

    else
    echo "ERROR: Wrong type of package"
    exit 1
fi

# Running docker
cp $PACKAGE ./mnt/
# Saving name of package
PACKAGE_FILE=$(echo "$PACKAGE" | awk -F / '{print $NF}')

docker run -ti --rm -v "$(pwd)/mnt:/mnt" --security-opt seccomp=unconfined $DISTRIBUTION /bin/bash /mnt/conversion.sh  \
--package-manager-update "$PACKAGE_MANAGER_UPDATE"  --package-manager-file-install "$PACKAGE_MANAGER_FILE_INSTALL" \
--package-manager-repo-install "$PACKAGE_MANAGER_REPO_INSTALL" --package-file "$PACKAGE_FILE" --package-type "$PACKAGE_TYPE" \
--package "$PACKAGE_NAME" --distribution "$DISTRIBUTION" $plugins_with_arguments

rm -f ./mnt/$PACKAGE_FILE