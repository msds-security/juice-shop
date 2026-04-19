#!/usr/bin/env bash
set -e

NS="${1:-juice-shop}"

echo "Deleting namespace: $NS"
set +e
kubectl delete namespace "$NS" --ignore-not-found --wait=true --timeout=60s
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo "Normal delete failed or timed out. Checking if namespace still exists..."
  if kubectl get namespace "$NS" >/dev/null 2>&1; then
    echo "Namespace stuck. Force-clearing finalizers (likely metrics-server bug)..."
    kubectl get namespace "$NS" -o json \
      | jq '.spec.finalizers = []' \
      | kubectl replace --raw "/api/v1/namespaces/$NS/finalize" -f -
    sleep 5
  fi
fi

if kubectl get namespace "$NS" >/dev/null 2>&1; then
  echo "FAILED: Namespace $NS still exists."
  exit 1
fi

echo "Namespace $NS removed successfully."
