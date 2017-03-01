# fabric8-pipeline-demo
## Prepare Branches

```
./prep-repos.sh [URI|PATH]
```

* `URI` - URI to the repository where you have push access
* `PATH` - path to a cloned repo

The above command will take a given repository and create, patch and push branches matching conent of `branches.sh` 

## Deploy & Build
You need to be logged in into OpenShift environment `oc login ...`. Then it *should* work to just run

```
./deploy-build.sh PROJECT_NAME [URI[@BRANCH]]
```

The command above will create 3 projects

* PROJECT_NAME
* PROJECT_NAME-staging
* PROJECT_NAME-production

Then it will start Jenkins and Content Cache in your OpenShift namespace, wait for Jenkins to come up and then it will create and start a build from a provided `URI` or `URI@BRANCH` (or from an example project https://github.com/rawlingsj/spring-boot-webmvc).

It will also print links to Jenkins instance and OpenShift Console Pipeline view at the end. 

## Deploy All Branches

```
./build_branches.sh PROJECT_NAME [URI[@BRANCH]]
```

Do **Deploy & Build** for all the branches specified in `branches.sh`

# Notes

Source for the OpenShift templates are:

* http://central.maven.org/maven2/io/fabric8/devops/apps/content-repository/2.2.324/content-repository-2.2.324-openshift.yml
* http://central.maven.org/maven2/io/fabric8/devops/apps/jenkins-openshift/2.2.324/jenkins-openshift-2.2.324-openshift.yml

