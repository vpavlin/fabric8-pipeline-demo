#!/usr/bin/bash

. branches.sh

#Don't create anything, just rebuild if REBUILD=true'
REBUILD=""
PROJECT=""
URI=""
BRANCH=""
MULTIPLIER=0
DELETE=""
BUILD_TIME=""
YES=false

while [ -n "$1" ]; do
  case "$1" in
    -h) echo "$0 [-hr] [-m BRANCH*MULTIPLIER] PROJECT [URI[@BRANCH]]"
        exit
        ;;
    -r|--rebuild) REBUILD=-r
        ;;
    -m|--multi) shift
                BRANCH=${1%%\**}
                MULTIPLIER=${1##*\*} 
        ;;
    -d|--delete) DELETE=-d
        ;;
    -t|--build-time) BUILD_TIME=-t
        ;;
    -y) YES=true
        ;;
    *) [ -z "${PROJECT}" ] && PROJECT=${1} && shift && continue
       [ -z "${URI}" ] && URI=${1} && shift && continue
       ;;
  esac
  shift
done

if [ -z "${BUILD_TIME}" ]; then
  if ! ${YES}; then
    oc projects
    echo -n "Are you logged in into a correct cluster? [Y/n] "
    read r
    [[ "$r" =~ ^[nN]$ ]] && exit
  fi
fi

if [ "${MULTIPLIER}" -gt 0 ]; then
  while [ "${MULTIPLIER}" -gt 0 ]; do
    ./deploy-build.sh ${BUILD_TIME} ${DELETE} ${REBUILD} ${PROJECT}${MULTIPLIER} $URI@${BRANCH}
    MULTIPLIER=$(( ${MULTIPLIER} - 1 ))
  done
  exit
fi

i=1
for b in ${BRANCHES}; do
  echo "Running 'deploy-build.sh' for $PROJECT${1} and $URI@$b"
  ./deploy-build.sh ${BUILD_TIME} ${DELETE} ${REBUILD} ${PROJECT}${i} $URI@$b
  i=$(( $i + 1 ))
done