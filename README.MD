# Package-to-appimage
Tool for conversion DEB and RPM packages into appimage format
## About
AppImages are a well known and quite popular format for distributing applications from developers to end users. 

Package-to-appimage is designed for automatic conversion of popular types of packages into appimage format. This is possible by using [linuxdeploy](https://github.com/linuxdeploy/linuxdeploy) for creation of appimages and [docker](https://www.docker.com/) for isolation of building.

Using docker allows you to convert a package of any format and vendor regardless of your distribution. The following distributions are currently supported:
* ALT Linux
* Fedora
* OpenSUSE
* CentOS
* Mageia
* Ubuntu
* Debian

## Usage
Help command output:
>        --package [package.rpm, package.deb]     specify the package to repackage
>        --plugin [plugin]                        specify the plugin to use
>                                                 available plugins - qt gtk ncurses gstreamer
>        --mount-directory                        specify directory for mounting into docker
>
>        --use-existants-container               use existance container, you need to create it before with "package-to-appimage-create-docker-image"
>         -E

Example of usage:
> ~/Projects/package-into-appimage/package-to-appimage.sh --package /tmp/xfce4-terminal-0.8.10-alt1.x86_64.rpm --plugin gstreamer -E --mount-directory /tmp/mnt   

Usage of *"-E"*  parameter is **highly** recomended. __Warning__, it creates new docker images on your computer.

## Troubleshooting ##
* Before running the script, make sure the docker system is running and the user is allowed to run it.