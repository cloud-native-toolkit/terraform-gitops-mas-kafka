#!/usr/bin/env bash

CHARTNAME="$1"
DEST_DIR="$2"
NAMESPACE="$3"
CLUSTERID="$4"


SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
MODULE_DIR=$(cd "${SCRIPT_DIR}/.."; pwd -P)
CHART_DIR=$(cd "${MODULE_DIR}/chart/${CHARTNAME}"; pwd -P)

mkdir -p "${DEST_DIR}"

## put the yaml resource content in DEST_DIR
cp -R "${CHART_DIR}"/* "${DEST_DIR}"


# first test if kafka server has finished deploying, if yes continue or timeout
export KAFKASTATUS=$(oc get kafkas ${CLUSTERID} -n ${NAMESPACE} --no-headers -o custom-columns=":status.conditions[0].type")

count=0
until [[ "${KAFKASTATUS}" = "Ready" ]] || [[ $count -eq 20 ]]; do
  echo "Waiting for ${CLUSTERID} in ${NAMESPACE}"
  count=$((count + 1))
  export KAFKASTATUS=$(oc get kafkas ${CLUSTERID} -n ${NAMESPACE} --no-headers -o custom-columns=":status.conditions[0].type")
  sleep 60
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for ${CLUSTERID} top become ready in ${NAMESPACE}"
  kubectl get all -n "${NAMESPACE}"
  exit 1
fi

host=$(oc get kafkas ${CLUSTERID} -o jsonpath='{.status.listeners[0].addresses[0].host}' -n ${NAMESPACE})
cert=$(oc get kafkas ${CLUSTERID} -o jsonpath='{.status.listeners[0].certificates[0]}' -n ${NAMESPACE})

# adds the kafka bootstrap host and cert used for mas config creation
cat >> ${DEST_DIR}/values.yaml << EOL
boothost: ${host}
bootcert: ${cert}

EOL
