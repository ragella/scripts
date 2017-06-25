#!/usr/bin/env bash
#This script will substitute the environment variables in rc.yml and service.yml 
#Invocation:
#  ./portal_rc_sub.sh MICROSERVICE
#	Parameters:
#	  - MICROSERVICE: Name of the microservice if it is compose then it points to all the services in compose file if not we can specify one service

SCRIPTNAME='gen_rc_sub.sh'
printf "%s: START: " "$SCRIPTNAME"
echo "		-ARGUMENTS: $@"

#Default argument values
MICROSERVICE="${1:-web-platform-client}"

#first step is to substitute the environment variables in rc.yml and service.yml
AZ_PROJECT_SERVICES_DIR=${AZ_MCC_PROCESS_DIR}/ops/projects/${AZ_PROJECT_NAME}/services/
[ ! -d "${AZ_PROJECT_SERVICES_DIR}/output" ] && mkdir -p ${AZ_PROJECT_SERVICES_DIR}/output 
if [ -d "$AZ_PROJECT_SERVICES_DIR/$MICROSERVICE" ]; then
	echo "creating the rc.yml and service.yml for $MICROSERVICE"
	envsubst < ${AZ_PROJECT_SERVICES_DIR}/$MICROSERVICE/rc.yml > ${AZ_PROJECT_SERVICES_DIR}/output/${MICROSERVICE}_rc.yml
	envsubst < ${AZ_PROJECT_SERVICES_DIR}/$MICROSERVICE/service.yml > ${AZ_PROJECT_SERVICES_DIR}/output/${MICROSERVICE}_service.yml
fi

#second step is to check for the service and if it doesn't exist create it
kubectl --kubeconfig=$AZ_KUBE_CONFIG  get services --namespace=${AZ_NAMESPACE} | awk '{print $1}' | tail -n+2 > servicelist.txt
SERVICE_COUNT=`grep ${MICROSERVICE} servicelist.txt | wc -l | sed 's/ //g'`
if [ "$SERVICE_COUNT" = "0" ]
then
	kubectl --kubeconfig=$AZ_KUBE_CONFIG  create -f ${AZ_PROJECT_SERVICES_DIR}/output/${MICROSERVICE}_service.yml
elif [ "$SERVICE_COUNT" = "1" ]
then
    echo "Service already exists"
else
    echo "ERROR: SERVICE_COUNT greater than 1, cannot create the service"
    exit 1
fi

#check for the rc and if doesn't exist create, if exist do the rolling update
kubectl --kubeconfig=$AZ_KUBE_CONFIG  get rc --namespace=${AZ_NAMESPACE} | awk '{print $1}' | tail -n+2 > rclist.txt
RC_COUNT=`grep ${MICROSERVICE} rclist.txt | wc -l | sed 's/ //g'`
echo "RC_COUNT=$RC_COUNT"
if [ "$RC_COUNT" = "0" ]
then
	echo "creating RC for the service $service"
	kubectl --kubeconfig=$AZ_KUBE_CONFIG  create -f ${AZ_PROJECT_SERVICES_DIR}/output/${MICROSERVICE}_rc.yml
elif [ "$RC_COUNT" = "1" ]
then
	echo "Doing the rolling update of RC $MICROSERVICE"
  	RC=`grep ${MICROSERVICE} rclist.txt`
   	echo "This is the RC $RC"
   	kubectl --kubeconfig=$AZ_KUBE_CONFIG  rolling-update $RC --namespace=${AZ_NAMESPACE} -f ${AZ_PROJECT_SERVICES_DIR}/output/${MICROSERVICE}_rc.yml
else
   	echo "ERROR: RC_COUNT greater than 1, cannot do a kubectl --kubeconfig=$AZ_KUBE_CONFIG  rolling-update or create"
   	exit 2
fi

printf "%s: FINISH\n" "$SCRIPTNAME"
