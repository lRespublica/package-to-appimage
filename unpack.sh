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
PACKAGE_TYPE=""
QUIET=""

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
    
    --package-type) if [ -n "$2" ]
                    then PACKAGE_TYPE="$2";

                    else printf "\tPlease, specify the package type\n"; exit 1;
                fi;
                shift;shift;;

    -q) QUIET="1";shift;;

    --help) help;exit;;

    *) PACKAGES+="$1 ";shift;;
    esac
done

function get_requirements()
{
    if [ "$PACKAGE_TYPE" = "RPM" ]
    then rpm -qR $1 | grep -v "rtld" | grep -v "rpmlib" | cut -f 1 -d ' ' | sed "s/ /\n/g"
    elif [ "$PACKAGE_TYPE" = "DEB" ]
    then apt-cache depends $1 | grep -e "Depends" -e "Recommends" | cut -d ':' -f 2- | sed "s/ //g" | grep -v "<" | grep -v "gles"
    fi
}

function get_files()
{
    if [ "$PACKAGE_TYPE" = "RPM" ]
    then rpm -ql $1

    elif [ "$PACKAGE_TYPE" = "DEB" ]
    then 
        for OUT in $(dpkg -L $1)
        do
            if [ -f $OUT ]
            then
                echo $OUT
            fi
        done
    fi
}

function quiet()
{
    if [ "$QUIET" != "" ]
    then
        "$@" >/dev/null 2>&1
    else
        "$@"
    fi
}

if [ "$PACKAGE_TYPE" != "RPM" ] && [ "$PACKAGE_TYPE" != "DEB" ]
then
    exit 1;
fi

quiet echo "$WITH_DEPENDENCIES" 
quiet echo "$UNPACK_DIRECTORY" 
quiet echo "$PACKAGES" 

if [ "$UNPACK_DIRECTORY" = "" ]
    then 
    printf "Please, specify directory with -D [/path/to/directory]\n"
    exit 1;zzz
fi

if [ "$PACKAGES" = "" ]
    then
    printf "Please, specify PACKAGES\n"
fi

quiet mkdir -p "$UNPACK_DIRECTORY"

INSTALLED_PACKAGES=""

function unpack_package()
{
    quiet cp --parents -t $UNPACK_DIRECTORY $(get_files $1) 
    INSTALLED_PACKAGES+=" $1"     
    if [ "$2" = "1" ]
    then
        DEPENDENCIES_LIST=$(get_requirements $1)
        for DEPENDENCY in ${DEPENDENCIES_LIST[@]}
        do
            if [ $PACKAGE_TYPE = "RPM" ] 
            then
                if [ "${DEPENDENCY:0:1}" = "/" ]
                then
                    unpack_package $(rpm -qf $DEPENDENCY) "1"

                elif [ "$(echo "$DEPENDENCY" | head -c 3)" = "lib" ] && [ $(echo "$DEPENDENCY" | grep -e "so") != "" ] && [ "$3" != "nolib" ]
                then
                    unpack_package $(rpm -qf $(whereis "$(echo $DEPENDENCY | cut -d "(" -f 1)" | cut -d " " -f 2-)) "1" "nolib"
                
                elif [ "$(echo "$DEPENDENCY" | head -c 3)" = "lib" ] && [ $(echo "$DEPENDENCY" | grep -e "so") != "" ] && [ "$3" = "nolib" ]
                then
                    quiet cp --parents -t "$UNPACK_DIRECTORY" $(whereis "$(echo $DEPENDENCY | cut -d "(" -f 1)" | cut -d " " -f 2-)  

                else
                    unpack_package "$(echo "$DEPENDENCY" | cut -d " " -f 1)" "0"
                fi 
            elif [ "$PACKAGE_TYPE" = "DEB" ]
            then
                if [ "$(echo $DEPENDENCY | head -c 3)" = "lib" ] && [ "$3" != "nolib" ]
                then
                    unpack_package "$DEPENDENCY" "1" "nolib"
                else
                    unpack_package "$DEPENDENCY" "0"
                fi
            fi
        done
    fi                   
}

for PACKAGE in "${PACKAGES[@]}"
do
    unpack_package "$PACKAGE" $WITH_DEPENDENCIES
done