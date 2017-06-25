#!/usr/bin/env bash
# This script should be executed in the mcc-process/ops/certs directory.  This will decrypt the key, and generate the jks keystore from the key, _cert.cer and .cer file
#
# Invocation:
#   certs_to_jks_stor.sh ${GE_FQN} ${GE_STORE_PASSWORD} ${GE_KEY_PASSWORD} ${GE_KEY_ALIAS}
#     Parameters:
#       - GE_FQN: Fully qualified name with underscores
#       - GE_STORE_PASSWORD: The destination key store password
#       - GE_KEY_PASSWORD: The key entry password
#       - GE_KEY_ALIAS: The key alias

SCRIPTNAME='certs_to_jks_stor.sh'
printf "%s: START: " "$SCRIPTNAME"
echo "     -ARGUMENTS: $@"

#Default argument values
GE_FQN="${1:-portal_dmdp-dev01_dev_cloud_astrazeneca_com}"
GE_STORE_PASSWORD="${2:-password}"
GE_KEY_PASSWORD="${3:-password}"
GE_KEY_ALIAS="${4:-server}"

GE_KEYFILE="${GE_FQN}.key"

#Check if the file exists.  If it doesn't print error and exit 1
if [ ! -f ${GE_KEYFILE} ]; then
    printf "%s: INFO: %s : does not exist,  Trying encrypted file.\n" "$SCRIPTNAME" "${GE_KEYFILE}"
    GE_KEYFILE_ENCRYPTED="${GE_KEYFILE}.encrypted"
    if [ ! -f ${GE_KEYFILE_ENCRYPTED} ]; then printf "%s: ERROR: %s file does not exist and encrypted file does not exist. Exiting\n" "$SCRIPTNAME" "${GE_KEYFILE_ENCRYPTED}"; exit 1; fi

    kmsdecrypt.sh "${GE_KEYFILE_ENCRYPTED}"
    if [ ! -f ${GE_KEYFILE} ]; then printf "%s: ERROR: %s file does not exist and encrypted file does not exist. Exiting\n" "$SCRIPTNAME" "${GE_KEYFILE}"; exit 1; fi
fi

GE_CER_ONLY_FILE="${GE_FQN}_cert.cer"
if [ ! -f ${GE_CER_ONLY_FILE} ]; then printf "%s: ERROR: %s file does not exist and encrypted file does not exist. Exiting\n" "$SCRIPTNAME" "${GE_CER_ONLY_FILE}"; exit 1; fi

GE_INTERM_FILE="${GE_FQN}.cer"
if [ ! -f ${GE_INTERM_FILE} ]; then printf "%s: ERROR: %s file does not exist and encrypted file does not exist. Exiting\n" "$SCRIPTNAME" "${GE_INTERM_FILE}"; exit 1; fi

GE_P12_STORE="${GE_FQN}.p12"
[ -f ${GE_P12_STORE} ] && rm -f ${GE_P12_STORE}

GE_JKS_STORE="${GE_FQN}.jks"
[ -f ${GE_JKS_STORE} ] && rm -f ${GE_JKS_STORE}

echo "openssl pkcs12 -export -in ${GE_CER_ONLY_FILE}  -inkey ${GE_KEYFILE}  -out ${GE_P12_STORE} -name ${GE_KEY_ALIAS} -CAfile ${GE_INTERM_FILE} -caname root -chain -password pass:${GE_STORE_PASSWORD}"
openssl pkcs12 -export -in ${GE_CER_ONLY_FILE}  -inkey ${GE_KEYFILE}  -out ${GE_P12_STORE} -name ${GE_KEY_ALIAS} -CAfile ${GE_INTERM_FILE} -caname root -chain -password pass:${GE_STORE_PASSWORD}
rc=$?; if [[ $rc != 0 ]]; then  printf "%s: ERROR: openssl pkcs12 -export -in : $rc" "$AE_SCRIPTNAME"; exit $rc; fi

echo "keytool -importkeystore -deststorepass ${GE_STORE_PASSWORD} -destkeypass ${GE_KEY_PASSWORD} -destkeystore ${GE_JKS_STORE} -srckeystore ${GE_P12_STORE} -srcstoretype PKCS12 -srcstorepass ${GE_STORE_PASSWORD} -alias ${GE_KEY_ALIAS}"
keytool -importkeystore -deststorepass ${GE_STORE_PASSWORD} -destkeypass ${GE_KEY_PASSWORD} -destkeystore ${GE_JKS_STORE} -srckeystore ${GE_P12_STORE} -srcstoretype PKCS12 -srcstorepass ${GE_STORE_PASSWORD} -alias ${GE_KEY_ALIAS}
rc=$?; if [[ $rc != 0 ]]; then  printf "%s: ERROR: keytool -importkeystore : $rc" "$AE_SCRIPTNAME"; exit $rc; fi

printf "%s: FINISH\n" "$SCRIPTNAME"
