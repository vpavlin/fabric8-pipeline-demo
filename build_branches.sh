#!/usr/bin/bash

. branches.sh
PROJECT=$1
URI=$2

oc project
echo -n "Are you logged in into a correct cluster? [Y/n] "
read r
[[ "$r" =~ ^[nN]$ ]] && exit
i=1
for b in ${BRANCHES}; do
  echo "$PROJECT $URI@$b"
  ./deploy-build.sh ${PROJECT}${i} $URI@$b
  i=$(( $i + 1 ))
done