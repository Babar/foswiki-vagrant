#!/bin/bash

LOGFILE=${0%sh}log
PERL=$(which perl)
exec 4>&1
exec 5>&2
exec > >(tee $LOGFILE)
exec 2>&1
exec 3>>$LOGFILE

trap 'kill -15 %2 %1' 0 2 3 15

if head -1 core/pseudo-install.pl | GREP_OPTIONS= grep -- -wT; then
    TAINT=-T
else
    TAINT=''
fi
apacheUser=`awk -F: '/^w/{print $1}' /etc/passwd`
id -u $apacheUser >/dev/null || (echo -e "Could not determine apache user. Found:\n$apacheUser";exit 1)
[ -z "$FOSWIKI_HOME" ] && (echo "No FOSWIKI_HOME set. Please set it and restart this script"; exit 1)
[ -d $FOSWIKI_HOME ] || (echo "FOSWIKI_HOME points to $FOSWIKI_HOME, which is not a directory. Please check it and restart this script"; exit 1)

OPTIONS='-clean'
for arg in "$@"; do
    if [ -d $arg ]; then
        INSTALL_ARGS="$INSTALL_ARGS $arg"
    fi
    case $arg in
    -*) OPTIONS="$OPTIONS $arg";;
    *)  if [ -n "$ARGS" ]; then ARGS="$ARGS $arg"; else ARGS="$arg";fi;;
    esac
done
Xvfb :1 >&3 2>&1 &
DISPLAY=:1 java -jar ../selenium/selenium-server-1.0.3/selenium-server.jar >&3 &
pushd $FOSWIKI_HOME >&3
[ -f lib/LocalSite.cfg ] || hasNoLocalSite=1
if [ -n "$hasNoLocalSite" ]; then
    if [ -f lib/LocalSite.cfg.save ]; then
        cp -p lib/LocalSite.cfg.save lib/LocalSite.cfg
    else
        echo "You haven't configured Foswiki yet, or you didn't backup your LocalSite.cfg in LocalSite.cfg.save."
        echo "I will use pseudo-install.pl -A to get a dummy one..."
        INSTALL_ARGS="-A $INSTALL_ARGS"
    fi
fi
FOSWIKI_ASSERTS=0
export FOSWIKI_ASSERTS
echo ASSERT set to $FOSWIKI_ASSERTS
sudo chown -R $LOGNAME $FOSWIKI_HOME >&3
find . -type l -exec rm {} \;
rm -rf $FOSWIKI_HOME/data/Temp*
$PERL $TAINT pseudo-install.pl $INSTALL_ARGS developer >&3
mkdir -p $FOSWIKI_HOME/{{data,working{,/logs},pub},test/unit/{fake_{templates,data},},lib/Foswiki/Plugins}/
sudo chown -R $apacheUser $FOSWIKI_HOME/{{data,working{,/logs},pub},test/unit/{fake_{templates,data},},lib/Foswiki/Plugins}/
date '+Starting tests at %Y-%m-%d %H:%M:%S'
#cd test/unit && $PERL $TAINT ../bin/TestRunner.pl $OPTIONS ${ARGS:-FoswikiSuite.pm}
cd test/unit && sudo -u $apacheUser $PERL $TAINT ../bin/TestRunner.pl $OPTIONS "${ARGS:-FoswikiSuite.pm}"
cd -
date '+Finished tests at %Y-%m-%d %H:%M:%S'
sudo chown -R $LOGNAME $FOSWIKI_HOME/{{data,working,pub},test/unit/,lib/Foswiki/Plugins}/
$PERL $TAINT pseudo-install.pl -u ${INSTALL_ARGS/-A /} developer >&3
rm -f $FOSWIKI_HOME/working/tmp/{Foswiki,cgisess_}*
[ -n "$hasNoLocalSite" ] && rm lib/LocalSite.cfg
popd >&3
exec 1>&4
exec 2>&5
exec 3>&-
exec 4>&-
exec 5>&-
if grep 'All tests passed' $LOGFILE >/dev/null; then
  echo -ne '\e[32m'
  GREP_OPTIONS= grep 'All tests passed' $LOGFILE
  if [ -d core/data/TestStoreWeb ]; then
    RETURN_CODE=1
  else
    RETURN_CODE=0
  fi
  # Cleaning up
  find . -name LocalSite.cfg -prune -o -group www-data -type f -exec rm {} \; -print
  find . -depth -name LocalSite.cfg -prune -o -group www-data -type d -exec rmdir {} \; -print
  [ -d .git ] && git diff --quiet
else
  echo -ne '\e[31m'
  $PERL -nle 'if(/^(-+|\d+ failures:)$/ ... /^$/){push @a, $_ if /^[^-]+$/}
print join "\n", @a, $_ if /test cases passed/' $LOGFILE
  RETURN_CODE=1
fi
echo -ne '\e[0m'
exit $RETURN_CODE
