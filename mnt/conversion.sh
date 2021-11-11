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
PACKAGE_MANAGER_COMMAND=""
PLUGINS=""
PLUGINS_COUNT=0

while [ \"$1\" != \"\" ]
do
    case "$1" in 
    --package-manager) if [ -n "$2" ]
                    then PACKAGE_MANAGER_COMMAND="$2";

                    else echo -e "\tPlease, specify the package"; exit 1;
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

