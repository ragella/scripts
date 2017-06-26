#!/usr/bin/env bash
#### Author: ctodevops - ctodevops@astrazeneca.com on 12/04/2017
#### Description: This script will check whether the boolean parameter to tag the git repo(in jenkins job) is enabled and when the condition is met it should tag the codebase to GIT repo.

GT_SCRIPTNAME='gittag.sh'
printf "%s: START: " "$GT_SCRIPTNAME"
echo "     -ARGUMENTS: $@"
GT_IMAGE_VERSION="${1:-default-value}"
GT_TAG_GIT_REPOS="${2:-default-value}"
GT_DIR="${3:-${WORKSPACE}}"
HOTFIX="${4:-deafult-value}"

#Validate whether the tagging parameter is enabled in the Jenkins build job.
if [ ${GT_TAG_GIT_REPOS} = true ]
#When the condition is met tag the codebase to GIT repo and push it to the specific branch.	
then
	if GT_DIR=${WORKSPACE}/.git git show-ref --tags | grep -q "refs/tags/${GT_IMAGE_VERSION}"
	then
		echo "TAG already exists"
	else
		echo "TAG doesn't exists, creating the tag"
		git tag ${GT_IMAGE_VERSION}
		git push origin -f ${GT_IMAGE_VERSION}
	fi
    #If this is a Promotion (BUILD_HOTFIX=false), force push the ${ENV}
    if [ "${HOTFIX}" = "false" ]
    then
      	#We need to preserve the BRANCH if it has been patched, get last tag and check whether patch number is not 0, then save the branch
      	if [ "${PATCH}" != "0" ]
      	then
      		git push origin -f ${ENV}:refs/heads/${LAST_TAG}
      	fi
        git push origin -f ${ENV}:refs/heads/${ENV}
    fi
fi

printf "%s: FINISH\n" "${AV_SCRIPTNAME}"
