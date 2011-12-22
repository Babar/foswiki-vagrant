#!/bin/bash

apacheUser=`awk -F: '/^w/{print $1}' /etc/passwd`
id -u $apacheUser >/dev/null || (echo -e "Could not determine apache user. Found:\n$apacheUser";exit 1)
[ -z "$FOSWIKI_HOME" ] && (echo "No FOSWIKI_HOME set. Please set it and restart this script"; exit 1)
[ -d $FOSWIKI_HOME ] || (echo "FOSWIKI_HOME points to $FOSWIKI_HOME, which is not a directory. Please check it and restart this script"; exit 1)
cd $FOSWIKI_HOME
sudo chown -R $LOGNAME $FOSWIKI_HOME
find . -type l -exec rm {} \;
perl -T pseudo-install.pl developer "$@"
# Grant admin privileges to myself
perl -i -ple 's/Set GROUP =.*$/Set GROUP = OlivierRaginel/' $FOSWIKI_HOME/data/Main/AdminGroup.txt
mkdir -p $FOSWIKI_HOME/{{data,working,pub},test/unit/{fake_{templates,data},},lib/Foswiki/Plugins}/
sudo chown -R www-data $FOSWIKI_HOME/{{data,working,pub},test/unit/{fake_{templates,data},},lib/Foswiki/Plugins}/
sudo rm -rf $FOSWIKI_HOME/data/Temp*
