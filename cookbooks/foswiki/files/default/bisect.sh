#! /bin/bash

branch=$1
test=$2

echo Looking for $test on $branch
git checkout $branch
git clean -fdx */
git bisect start
while ! ./run-tests.sh $test; do
  git bisect bad
  git checkout HEAD~100
done
git bisect good
git bisect run ./run-tests.sh $test | tee output
commit=$(perl -wnle 'print $1 if /0m([a-f0-9]+) is the first bad commit/' output)
if [ -n "$commit" ]; then
  (echo "$test on $branch was broken by $commit:";git log -1 --pretty=medium $commit)|tee -a Result.log
else
  echo "$test is OK on $branch!"
fi
git bisect reset
