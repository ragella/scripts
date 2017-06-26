#!/usr/bin/env bash
#This script will create a repository in ECS if it doesn't exist
#Invocation:
#  ./ecr_createrepo.sh $SERVICE $Var2 $Var3 $Var4
#	Parameters:
#	  - SERVICE: Name of the microservice
#	  - Var2: project name
#	  - Var3: aws profile name, in which we have the appropriate credentials to create the repository
#	  - Var4: aws region in which repo has to be checked and created

SCRIPTNAME='ecr_createrepo.sh'
printf "%s: START: " "$SCRIPTNAME"
echo "		-ARGUMENTS: $@"

#Default argument values
SERVICE="${1:-compose}"
Var2="${2:-dmdp}"
Var3="${3:-default}"
Var4="${4:-us-east-2}"

#Check if the repo exists or not and creates it if doesn't exist
if [[ ${SERVICE} = "compose" ]]
then
	docker-compose config --services | tee ${WORKSPACE}/services.txt
	while IFS='' read -r SERVICE || [[ -n "$SERVICE" ]];do
		aws ecr describe-repositories --repository-name $Var2/$SERVICE --profile $Var3 --region $Var4
		status=$?
		if [[ "$status" == "0" ]]
		then
			echo "Repo exists"
		else
			echo "Repo doesn't exists"
			aws ecr create-repository --repository-name $Var2/$SERVICE --profile $Var3 --region $Var4
		fi
	done< ${WORKSPACE}/services.txt
else
	aws ecr describe-repositories --repository-name ${Var2}/${SERVICE} --profile $Var3 --region $Var4
	status=$?
	if [[ "$status" == "0" ]]
	then
		echo "Repo exists"
	else
		echo "Repo doesn't exists"
		aws ecr create-repository --repository-name $Var2/$SERVICE --profile $Var3 --region $Var4
	fi
fi

printf "%s: FINISH\n" "$SCRIPTNAME"
