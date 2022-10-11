#!/bin/bash

# Help function
function help()
{
    printf 'unpack-rpm [--PARAMETERS] [name of installed package]\n'
    printf '\n\t/--directory [/path/to/directory]\t\tUnpack package to setted directory'
    printf '\n\t\-D [/path/to/directory]\n'
    printf '\n\t/--with-dependencies\t\t\t\tUnpack package and it`s direct dependencies'
    printf '\n\t\-W\n'
    printf '\n'
}

WITH_DEPENDENCIES="0"
UNPACK_DIRECTORY=""
PACKAGES=""

# Close programm without arguments
if [ $# -eq 0 ]
then
    echo "There is no parameters"
    help
    exit 1
fi

# Enumerating options
while [ "$1" != "" ]
do
    case "$1" in 
    "--directory" | "-D") if [ -n "$2" ]
                    then UNPACK_DIRECTORY="$2";

                    else printf "\tPlease, specify the directory\n"; exit 1;
                fi;
                shift;shift;;

    "--with-dependencies" | "-W") WITH_DEPENDENCIES="1";
                shift;;

    --help) help;exit;;

    *) PACKAGES+="$1 ";shift;;
    esac
done

echo "$WITH_DEPENDENCIES"
echo "$UNPACK_DIRECTORY"
echo "$PACKAGES"

if [ "$UNPACK_DIRECTORY" = "" ]
    then 
    printf "Please, specify directory with -D [/path/to/directory]\n"
    exit 1;
fi

if [ "$PACKAGES" = "" ]
    then
    printf "Please, specify PACKAGES\n"
fi

mkdir -p "$UNPACK_DIRECTORY"

function unpack_package()
{
    cp --parents -r -t $UNPACK_DIRECTORY $(rpm -ql $1)     
    if [ "$2" = "1" ]
    then
        DEPENDENCIES_LIST=$(rpm -qR $1 | cut -f 1 -d ' ' | sed "s/ /\n/")
        for DEPENDENCY in ${DEPENDENCIES_LIST[@]}
        do
            if [ "${DEPENDENCY:0:1}" = "/" ]
            then
                unpack_package $(rpm -qf $DEPENDENCY) "1"

            elif [ "$(echo "$DEPENDENCY" | head -c 3)" = "lib" ] && [ $(echo "$DEPENDENCY" | grep -e "so") != "" ] && [ "$3" != "nolib" ]
            then
                unpack_package $(rpm -qf $(whereis "$(echo $DEPENDENCY | cut -d "(" -f 1)" | cut -d " " -f 2-)) "1" "nolib"
            
            elif [ "$(echo "$DEPENDENCY" | head -c 3)" = "lib" ] && [ $(echo "$DEPENDENCY" | grep -e "so") != "" ] && [ "$3" = "nolib" ]
            then
                cp --parents -t "$UNPACK_DIRECTORY" $(whereis "$(echo $DEPENDENCY | cut -d "(" -f 1)" | cut -d " " -f 2-)

            elif [ "$(echo $DEPENDENCY | grep -e "rpmlib")" != "" ]
            then
                printf "Found rpmlib, skipping...\n"    

            else
                unpack_package "$(echo "$DEPENDENCY" | cut -d " " -f 1)" "0"
            fi 
        done
    fi                   
}

for PACKAGE in "${PACKAGES[@]}"
do
    unpack_package "$PACKAGE" $WITH_DEPENDENCIES
done