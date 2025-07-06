#!/bin/bash
set -e

EXPECTED=$1
NAMESPACE=${2:-httpbin}
LABEL_SELECTOR=${3:-app=httpbin}

echo "EXPECTED: ${EXPECTED}"
echo "NAMESPACE: ${NAMESPACE}"
echo "LABEL_SELECTOR: ${LABEL_SELECTOR}"

RUNNING=$(kubectl get pods -n "$NAMESPACE" -l "$LABEL_SELECTOR" --field-selector=status.phase=Running --no-headers | wc -l)

if [ "$RUNNING" -ne "$EXPECTED" ]; then
  echo "Error: Expected $EXPECTED running pods, but found $RUNNING"
  exit 1
else
  echo "Success: All $EXPECTED pods are running."
fi