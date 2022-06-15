#!/usr/bin/env bash

NAMESPACE="$1"
DEST_DIR="$2"
CLUSTERID="$3"


mkdir -p "${DEST_DIR}"

kubectl create secret generic "${CLUSTERID}-credentials" \
  -n "${NAMESPACE}" \
  --from-literal="username=${KAFKA_USER}" \
  --from-literal="password=${KAFKA_PASS}" \
  --dry-run=client \
  --output=yaml > "${DEST_DIR}/masconfigcredentials.yaml"