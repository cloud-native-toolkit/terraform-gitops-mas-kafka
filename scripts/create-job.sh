#!/usr/bin/env bash

CHARTNAME="$1"
DEST_DIR="$2"
NAMESPACE="$3"
CLUSTERID="$4"
SECRETNAME="$5"
MASID="$6"

apiVersion: batch/v1
kind: Job
metadata:
  labels:
    mas.ibm.com/configScope: system
    mas.ibm.com/instanceId: {$MASID}
  annotations:
    argocd.argoproj.io/sync-wave: "3"   
  name: kafkaconfig-job
  namespace: ${NAMESPACE}
spec:
  template:
    spec:
      containers:
        - image: registry.redhat.io/openshift4/ose-cli:v4.4
          command:
            - /bin/bash
            - -c
            - |
              export HOME=/tmp/mascfg

              echo "wait for kafka server to finish deploying, if yes continue or timeout"

              kafkastatus=$(oc get kafkas ${CLUSTERID} -n ${NAMESPACE} --no-headers -o custom-columns=":status.conditions[0].type")
              count=0
              until [[  $kafkastatus = "Ready" ]] || [[ $count -eq 20 ]]; do
                echo "Waiting for ${CLUSTERID} in ${NAMESPACE}"
                count=$((count + 1))
                sleep 60
                kafkastatus=$(oc get kafkas ${CLUSTERID} -n ${NAMESPACE} --no-headers -o custom-columns=":status.conditions[0].type")
              done

              if [[ $count -eq 20 ]]; then
                echo "Timed out waiting for ${CLUSTERID} top become ready in ${NAMESPACE}"
                exit 1
              fi

              boothost=$(oc get kafkas ${CLUSTERID} -o jsonpath='{.status.listeners[0].addresses[0].host}' -n ${NAMESPACE})
              bootcert=$(oc get kafkas ${CLUSTERID} -o jsonpath='{.status.listeners[0].certificates[0]}' -n ${NAMESPACE})

              mkdir -p "/tmp"
              cat > /tmp/cfgjob.yaml << EOL
apiVersion: config.mas.ibm.com/v1
kind: KafkaCfg
metadata:
  name: ${MASID}-kafka-system
  namespace: ${NAMESPACE}
  labels:
    mas.ibm.com/configScope: system
    mas.ibm.com/instanceId: ${MASID}
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
oc apply -f /tmp/cfgjob.yaml -n ${NAMESPACE}

          imagePullPolicy: Always
          name: installplan-approver
      dnsPolicy: ClusterFirst
      restartPolicy: OnFailure
      serviceAccount: cfgjob-sa
      serviceAccountName: cfgjob-sa
      terminationGracePeriodSeconds: 30
