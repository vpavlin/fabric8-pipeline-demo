#!/usr/bin/bash
indent() { sed 's/^/=> /'; }

. branches.sh
URI=$1
DIR=""


if [ -d ${URI} ]; then
 DIR=${URI}
else
 DIR=$(mktemp -d /tmp/pipeline-XXXX)
 git clone ${URI} ${DIR}
fi

pushd ${DIR}

REPO_BRANCH=$(git branch -a)
for b in ${BRANCHES}; do
  echo ${REPO_BRANCH} | grep -qw $b

  git checkout master 2>&1 | indent
  if [ "$?" -eq 0 ]; then
    echo "Branch $b already exists"
    git checkout $b
  else
    git checkout -b $b 2>&1 | indent
  fi

  sed -i.bckp "s#fabric8io/fabric8-pipeline-library@[^']*#vpavlin/fabric8-pipeline-library@$b#" Jenkinsfile
  git diff | indent
  git commit -a -m "Change library branch to $b" 2>&1 | indent
  git push --set-upstream origin $b 2>&1 | indent
  [ "$?" -eq 0 ] && echo "Succesfully pushed $b"
done

popd

