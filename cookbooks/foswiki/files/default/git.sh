#!/bin/bash

# Check and define environment
[ -f env.sh ] && . ./env.sh

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
