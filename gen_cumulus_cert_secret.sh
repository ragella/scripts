#!/usr/bin/env bash
# This script is used to generate the keystore secret from the certs that are checked in to mcc-process/ops/certs
# Invocation:
#   gen_cumulus_keystore_secret.sh ${GE_FQN} ${GE_STORE_PASSWORD} ${GE_KEY_PASSWORD} ${GE_KEY_ALIAS}
#     Parameters:
#       - GE_FQN: Fully qualified name with underscores
#       - GE_STORE_PASSWORD: The destination key store password
#       - GE_KEY_PASSWORD: The key entry password
#       - GE_KEY_ALIAS: The key alias

SCRIPTNAME='gen_cumulus_keystore_secret.sh'
printf "%s: START: " "$SCRIPTNAME"
echo "     -ARGUMENTS: $@"

#Default argument values
GE_FQN="${1:-api_dev01_cloud_astrazeneca_com}"
GE_STORE_PASSWORD="${2:-4DevSt0r3_-!}"
GE_KEY_PASSWORD="${3:-4DevSt0r3_-!}"
GE_KEY_ALIAS="${4:-cumulus-dev01}"

#Creating the .p12 and .jks files from the certs
if [ ! -f ${AZ_MCC_PROCESS_DIR}/ops/certs/${GE_FQN}.p12 ]
then
    certs_to_jks_store.sh ${GE_FQN} ${GE_STORE_PASSWORD} ${GE_KEY_PASSWORD} ${GE_KEY_ALIAS}
fi

#List the details of the keystore
cd ${AZ_MCC_PROCESS_DIR}/ops/certs/
keytool -list -keystore ./${GE_FQN}.p12 -storepass ${GE_KEY_PASSWORD}

#Create the keystore secret
kubectl --kubeconfig=${AZ_KUBE_CONFIG} --namespace=${AZ_NAMESPACE} create secret generic cumulus-ssl-keystore --from-file=keystore=./${GE_FQN}.p12



