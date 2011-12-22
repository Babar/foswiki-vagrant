#!/bin/bash

# Check and define environment
[ -f env.sh ] && . ./env.sh

cd $FOSWIKI_HOME
sudo chown -R $LOGNAME $FOSWIKI_HOME
find . -type l -exec rm {} \;
perl -T pseudo-install.pl developer "$@"
# Grant admin privileges to myself
perl -i -ple 's/Set GROUP =.*$/Set GROUP = OlivierRaginel/' $FOSWIKI_HOME/data/Main/AdminGroup.txt
mkdir -p $FOSWIKI_HOME/{{data,working,pub},test/unit/{fake_{templates,data},},lib/Foswiki/Plugins}/
sudo chown -R www-data $FOSWIKI_HOME/{{data,working,pub},test/unit/{fake_{templates,data},},lib/Foswiki/Plugins}/
sudo rm -rf $FOSWIKI_HOME/data/Temp*
