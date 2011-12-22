#!/bin/bash

LOGFILE=${0%sh}log
exec 3>$LOGFILE
exec > >(tee -a /proc/$$/fd/3)
exec 2>&1
set -e

# Check and define environment
[ -f env.sh ] && . ./env.sh

OPTIONS='release -auto'
for arg in "$@"; do
    if [ -d $arg ]; then
        INSTALL_ARGS="$INSTALL_ARGS $arg"
    fi
    case $arg in
    -*) OPTIONS="$OPTIONS $arg";;
    *)  if [ -n "$ARGS" ]; then ARGS="$ARGS $arg"; else ARGS="$arg";fi;;
    esac
done
pushd $FOSWIKI_HOME >&3
[ -f lib/LocalSite.cfg ] || hasNoLocalSite=1
if [ -n "$hasNoLocalSite" ]; then
    if [ -f lib/LocalSite.cfg.save ]; then
        cp -p lib/LocalSite.cfg.save lib/LocalSite.cfg
    elif [ -f ../LocalSite.cfg ]; then
        cp -p ../LocalSite.cfg lib/LocalSite.cfg
    else
        echo "You haven't configured Foswiki yet, or you didn't backup your LocalSite.cfg in LocalSite.cfg.save."
        echo "I will use pseudo-install.pl -A to get a dummy one..."
        INSTALL_ARGS="-A $INSTALL_ARGS"
    fi
fi
#FOSWIKI_ASSERTS=1
#export FOSWIKI_ASSERTS
#echo ASSERT set to $FOSWIKI_ASSERTS
find . -type l -exec rm {} \;
rm -rf $FOSWIKI_HOME/data/Temp*
perl $TAINT pseudo-install.pl $INSTALL_ARGS developer >&3
mkdir -p $FOSWIKI_HOME/{{data,working{,/logs},pub},test/unit/{fake_{templates,data},},lib/Foswiki/Plugins}/
date '+Starting build at %Y-%m-%d %H:%M:%S'
cd tools && perl build.pl $OPTIONS
RETURN_CODE=$?
cd -
date '+Finished build at %Y-%m-%d %H:%M:%S'
perl $TAINT pseudo-install.pl -u ${INSTALL_ARGS/-A /} developer >&3
rm -f $FOSWIKI_HOME/working/tmp/{Foswiki,cgisess_}*
[ -n "$hasNoLocalSite" ] && rm lib/LocalSite.cfg
popd >&3
exec 3>&-
if [ -f $FOSWIKI_HOME/Foswiki-*.tgz ]; then
  echo -e '\e[32mBuild successful'
  # Cleaning up
  find . -name LocalSite.cfg -prune -o -group www-data -type f -exec rm {} \; -print
  find . -depth -name LocalSite.cfg -prune -o -group www-data -type d -exec rmdir {} \; -print
else
  echo -ne '\e[31mBuild failed'
  if [ $RETURN_CODE -eq 0 ]; then
    echo -n ', but build was successful!'
    RETURN_CODE=1
  fi
fi
echo -ne '\e[0m'
exit $RETURN_CODE
