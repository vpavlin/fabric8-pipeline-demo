# fabric8-pipeline-demo

You need to be logged in into OpenShift environment `oc login ...`. Then it *should* work to just run

```
./deploy-build.sh PROJECT_NAME
```

The command above will create 2 projects

* PROJECT_NAME
* PROJECT_NAME-staging
* PROJECT_NAME-production

Then it will start Jenkins and Content Cache in your OpenShift namespace, wait for Jenkins to come up and then it will start build of an example project https://github.com/rawlingsj/spring-boot-webmvc.

It will also print links to Jenkins instance and OpenShift Console Pipeline view at the end. 

# Notes

Source for the OpenShift templates are:

* http://central.maven.org/maven2/io/fabric8/devops/apps/content-repository/2.2.324/content-repository-2.2.324-openshift.yml
* http://central.maven.org/maven2/io/fabric8/devops/apps/jenkins-openshift/2.2.324/jenkins-openshift-2.2.324-openshift.yml

