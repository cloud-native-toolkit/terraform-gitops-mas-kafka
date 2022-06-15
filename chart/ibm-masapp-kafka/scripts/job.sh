#!/usr/bin/env bash

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

boothost=$(oc get kafkas ${CLUSTERID} -o jsonpath='{.status.listeners[0].addresses[0].host}' -n ${NAMESPACE})
bootcert=$(oc get kafkas ${CLUSTERID} -o jsonpath='{.status.listeners[0].certificates[0]}' -n ${NAMESPACE})

cat > ./cfgjob.yaml << EOL
apiVersion: config.mas.ibm.com/v1
kind: KafkaCfg
metadata:
  name: ${INSTANCEID}-kafka-system
  namespace: ${CORENAMESPACE}
  labels:
    mas.ibm.com/configScope: system
    mas.ibm.com/instanceId: ${INSTANCEID}
spec:
  displayName: "Kafka - ${CLUSTERID}"
  config:
    hosts:
      - host: "$boothost"
        port: 443
    credentials:
      secretName: ${SECRETNAME}
    saslMechanism: SCRAM-SHA-512
  certificates:
    - alias: ${CLUSTERID}-ca
      crt: |
$(echo | awk -v ca_var="$bootcert" '{ printf ca_var; }' | sed 's/^/        /')  
EOL
oc apply -f ./cfgjob.yaml -n ${CORENAMESPACE}