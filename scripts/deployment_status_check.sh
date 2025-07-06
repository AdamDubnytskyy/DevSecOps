#!/bin/bash
set -e

EXPECTED=$1
NAMESPACE=${2:-httpbin}
LABEL_SELECTOR=${3:-app=httpbin}

TIMEOUT=120  # seconds
INTERVAL=5  # seconds between checks
ELAPSED=0

kubectl get po -n $NAMESPACE
while true; do
    RUNNING=$(kubectl get pods -n "$NAMESPACE" -l "$LABEL_SELECTOR" --field-selector=status.phase=Running --no-headers | wc -l)
    echo "Currently running pods: $RUNNING"

    if [ "$RUNNING" -eq "$EXPECTED" ]; then
        echo "Success: All $EXPECTED pods are running."
        break
    fi

    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "Error: Timeout after $TIMEOUT seconds. Only $RUNNING/$EXPECTED pods are running."
        exit 1
    fi

    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done
