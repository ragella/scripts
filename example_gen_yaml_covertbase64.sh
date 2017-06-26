#!/usr/bin/env bash
# This script will generate the yml files from template with environment substitution and base64 encryption support for ${BASE64_VAR}
#  IMPORTANT: There can only be one ${BASE64_ variable per line
# Invocation:
#   source genyml.sh YML_TEMPLATE
#     Parameters:
#       - YML_TEMPLATE: like secret.yml
#       - YML_OUTPUT_FILE: like secret_out.yml
#       - BASEOS: true will use the base64 command for MAC OSX, false will use the Linux base64 comand.  Default false (Linux)

SCRIPTNAME='genyml.sh'
printf "%s: START: " "$SCRIPTNAME"
echo "     -ARGUMENTS: $@"

#Default argument values

YML_TEMPLATE="${1:-secret.yml}"
YML_OUTPUT_FILE="${2:-secret_out.yml}"
BASEOS=$(uname)

for BASE64_VAR in $(grep '${BASE64_' ${YML_TEMPLATE} | sed 's|^.*BASE64_||' | sed 's|\}.*$||')
do
    #printf "%s = %s\n" "${BASE64_VAR}" "${!BASE64_VAR}"
    if [[ -z "${!BASE64_VAR}" ]]; then
        printf "%s: ERROR: %s BASE64_VAR does not exist.  Cannot expand. Exiting\n" "${SCRIPTNAME}" "${BASE64_VAR}"
        exit 1
    fi
    if [[ "$BASEOS" == *"Darwin"* ]]; then
        export "BASE64_${BASE64_VAR}=$(echo -n "${!BASE64_VAR}" | base64)"
    else
        export "BASE64_${BASE64_VAR}=$(echo -n "${!BASE64_VAR}" | base64 --wrap=0)"
    fi
done

envsubst < "${YML_TEMPLATE}" > "${YML_OUTPUT_FILE}"

printf "%s: FINISH\n" "$SCRIPTNAME"
