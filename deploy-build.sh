#!/usr/bin/bash

indent() { sed 's/^/=> /'; }

set -e  

PROJECT=$1
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
oc apply -f build.yaml

build_name=$(cat build.yaml | grep name: | sed 's/.*:\s//')

oc start-build ${build_name}

jenkins_route=$(oc get route jenkins --output jsonpath=http://{.spec.host})
pipeline=$(oc project | sed 's#.*project "\([^"]*\)".*server "\([^"]*\)".*#\2/console/project/\1/browse/pipelines#')
echo "Jenkins can be accessed at ${jenkins_route}"
echo "OpenShift Console Pipeline view can be accessed at ${pipeline}"
