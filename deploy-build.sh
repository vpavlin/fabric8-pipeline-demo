#!/usr/bin/bash

indent() { sed 's/^/=> /'; }

set -e

#Project to be created in OpenShift
PROJECT=""
#URI of Git repository containing code and Jenkinsfile
URI=""
FULL_URI=""

#Don't create anything, just rebuild if REBUILD=true'
REBUILD=false

DELETE=false
BUILD_TIME=false

while [ -n "$1" ]; do
  case "$1" in
    -h) echo "$0 [-hr] PROJECT [URI[@BRANCH]]"
        exit
        ;;
    -r|--rebuild) REBUILD=true
        ;;
    -d|--delete) DELETE=true
        ;;
    -t|--build-time) BUILD_TIME=true
        ;;
    *) [ -z "${PROJECT}" ] && PROJECT=$1 && shift && continue
       [ -z "${URI}" ] && URI=${1%%@*} && FULL_URI=${1} && shift && continue
       ;;
  esac
  shift
done

[[ "${URI}" =~ /$ ]] && URI=${URI%%/}

BRANCH=${FULL_URI##*@}
BUILD_FILE="build.yaml"
BUILD_NAME=$(echo ${URI##*/} | tr "_" "-")
if [ -n "${URI}" ]; then
  NEW_BF="build-${BUILD_NAME}.yaml"
  sed 's#uri: .*#uri: '${URI}'#' ${BUILD_FILE} > ${NEW_BF}
  if [ "${URI}" != "${BRANCH}" ]; then
    sed -i 's@ref: .*@ref: '${BRANCH}'@' ${NEW_BF}
  fi
     
  sed -i 's/name: .*/name: '${BUILD_NAME}'/' ${NEW_BF}
  BUILD_FILE=${NEW_BF}
else
  BUILD_NAME=$(cat ${BUILD_FILE} | sed 's/.*name:\s*\(\S*\)/\1/')
fi

if ${BUILD_TIME}; then
  BUILD_ITEM=$(cat build.items) 2> /dev/null
  echo -n "Build time of ${PROJECT}/${BUILD_NAME} is "
  oc --namespace ${PROJECT} get build ${BUILD_ITEM} --output jsonpath={.status.duration}" / "{.status.phase};
  echo
  exit
fi

if ${DELETE}; then
  oc delete project ${PROJECT} ${PROJECT}-staging ${PROJECT}-production
  exit
fi

if ${REBUILD}; then
  oc project ${PROJECT}
  oc start-build ${BUILD_NAME} | sed 's/.*build "\([^"]*\)" started.*/\1/' > build.items
  exit
fi

STAGING="staging"
PROD="production"

oc new-project ${PROJECT} > /dev/null
echo "Created ${PROJECT}"

oc new-project ${PROJECT}-${STAGING} > /dev/null
echo "Created ${PROJECT}-${STAGING}"

oc new-project ${PROJECT}-${PROD} > /dev/null
echo "Created ${PROJECT}-${PROD}"

oc project ${PROJECT} > /dev/null
echo "Switched to project ${PROJECT}"

oc policy add-role-to-user view system:serviceaccount:${PROJECT}:jenkins --namespace ${PROJECT}-${STAGING}
oc policy add-role-to-user edit system:serviceaccount:${PROJECT}:jenkins --namespace ${PROJECT}-${STAGING}
echo "Added roles for ${PROJECT}-${STAGING}"

oc policy add-role-to-user view system:serviceaccount:${PROJECT}:jenkins --namespace ${PROJECT}-${PROD}
oc policy add-role-to-user edit system:serviceaccount:${PROJECT}:jenkins --namespace ${PROJECT}-${PROD}
echo "Added roles for ${PROJECT}-${PROD}"

echo "Deploying Jenkins"
oc apply -f jenkins-openshift-2.2.324-openshift.yml | indent

echo "Deploying Content Repository"
oc apply -f content-repository-2.2.324-openshift.yml | indent

echo -n "Waiting for Jenkins to become available."
while true; do
  status=$(oc get dc/jenkins --output jsonpath={.status.conditions[1].reason})
  [ "NewReplicationControllerAvailable" == "${status}" ] && echo -e "\nStatus for DC Jenkins is ${status}" && break
  echo -n "."
  sleep 3
done

echo "Adding Build Config"
oc apply -f ${BUILD_FILE}

oc start-build ${BUILD_NAME} | sed 's/.*build "\([^"]*\)" started.*/\1/' > build.items

jenkins_route=$(oc get route jenkins --output jsonpath=http://{.spec.host})
pipeline=$(oc project | sed 's#.*project "\([^"]*\)".*server "\([^"]*\)".*#\2/console/project/\1/browse/pipelines#')
echo "Jenkins can be accessed at ${jenkins_route}"
echo "OpenShift Console Pipeline view can be accessed at ${pipeline}"
