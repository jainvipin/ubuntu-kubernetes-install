#!/bin/sh

# if /opt/bin binaries exist then avoid copying
if [ ! -d /opt/bin ]
then
    mkdir -p /opt/bin
    cp bin/* /opt/bin/
fi

# copy /etc/init files
cp init_conf/* /etc/init/

# copy /etc/initd/ files
cp initd_scripts/* /etc/init.d/

# copy default configs
cp default_scripts/* /etc/default/


