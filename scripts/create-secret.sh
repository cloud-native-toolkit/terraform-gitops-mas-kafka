#!/usr/bin/env bash

NAMESPACE="$1"
DEST_DIR="$2"


mkdir -p "${DEST_DIR}"

kubectl create secret generic "${KAFKA_USER}" \
  -n "${NAMESPACE}" \
  --from-literal="password=${KAFKA_PASS}" \
  --from-literal='sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="${KAFKA_USER}" password="${KAFKA_PASS}";' \
  --dry-run=client \
  --output=yaml > "${DEST_DIR}/usercredentials.yaml"