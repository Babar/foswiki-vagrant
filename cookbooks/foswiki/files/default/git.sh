#!/bin/bash

apacheUser=`awk -F: '/^w/{print $1}' /etc/passwd`
id -u $apacheUser >/dev/null || (echo -e "Could not determine apache user. Found:\n$apacheUser";exit 1)
[ -z "$FOSWIKI_HOME" ] && (echo "No FOSWIKI_HOME set. Please set it and restart this script"; exit 1)
[ -d $FOSWIKI_HOME ] || (echo "FOSWIKI_HOME points to $FOSWIKI_HOME, which is not a directory. Please check it and restart this script"; exit 1)
cd $FOSWIKI_HOME
sudo chown -R $LOGNAME $FOSWIKI_HOME
sudo rm -rf $FOSWIKI_HOME/data/Temp*
# Remove admin privileges
[ -w $FOSWIKI_HOME/data/Main/AdminGroup.txt ] && perl -i -ple 's/Set GROUP = OlivierRaginel/Set GROUP =/' $FOSWIKI_HOME/data/Main/AdminGroup.txt
perl -T pseudo-install.pl -u developer "$@"
rm -f $FOSWIKI_HOME/working/tmp/cgisess_*
find . -type l -print0 | xargs -r0 rm -v
find . -name LocalSite.cfg -prune -o -group www-data -type f -exec sudo rm {} \;
find . -depth -name LocalSite.cfg -prune -o -group www-data -type d -exec sudo rmdir {} \;
git rev-parse --git-dir >/dev/null 2>&1 && git diff --quiet
