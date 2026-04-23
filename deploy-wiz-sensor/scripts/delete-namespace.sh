#!/usr/bin/env bash
# Force-delete a Kubernetes namespace, working around the EKS metrics-server
# stale-GroupVersion bug that leaves namespaces stuck in Terminating.
#
# Usage: delete-namespace.sh <namespace>
# Mirrors deploy/scripts/delete-namespace.sh but uses python3 (ubiquitous on
# Jenkins agents) rather than jq (not always installed).

set -e

NS="${1:-wiz}"

echo "Deleting namespace: $NS"
set +x
set +e
kubectl delete namespace "$NS" --ignore-not-found --wait=true --timeout=60s
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo "Normal delete failed or timed out. Checking if namespace still exists..."
  if kubectl get namespace "$NS" >/dev/null 2>&1; then
    echo "Namespace stuck in Terminating. Force-clearing finalizers (EKS metrics-server bug)..."
    kubectl get namespace "$NS" -o json \
      | python3 -c "import sys, json; d=json.load(sys.stdin); d['spec']['finalizers']=[]; print(json.dumps(d))" \
      | kubectl replace --raw "/api/v1/namespaces/$NS/finalize" -f -
    sleep 5
  fi
fi

if kubectl get namespace "$NS" >/dev/null 2>&1; then
  echo "FAILED: Namespace $NS still exists after force-clear attempt."
  exit 1
fi

echo "Namespace $NS removed successfully."
