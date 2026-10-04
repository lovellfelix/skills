#!/usr/bin/env bash
set -euo pipefail

# rollback-deploy.sh
# Simple rollback helper that re-deploys a previous tag or performs a kubernetes rollout undo.
# Usage: rollback-deploy.sh --env staging --to-tag v1.2.3 [--k8s-deployment myapp] [--dry-run]

ENV=""
TO_TAG=""
K8S_DEPLOYMENT=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENV="$2"; shift 2 ;;
    --to-tag) TO_TAG="$2"; shift 2 ;;
    --k8s-deployment) K8S_DEPLOYMENT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ -z "$ENV" ]]; then
  echo "--env is required (staging|production)" >&2
  exit 2
fi

if [[ -z "$TO_TAG" ]]; then
  echo "--to-tag is required. Example: --to-tag v1.2.3" >&2
  exit 2
fi

# Example: For Kubernetes, we assume images use tags with git tags. The actual rollback mechanism
# will depend on your deployment system. Here we provide guarded commands and instructions.

echo "Preparing rollback in env=$ENV to tag=$TO_TAG"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY RUN: would perform rollback steps for $ENV -> $TO_TAG"
  echo "If using Kubernetes and images are tagged by git tag, you can set image: myrepo/myapp:$TO_TAG and kubectl apply or use kubectl rollout undo"
  if [[ -n "$K8S_DEPLOYMENT" ]]; then
    echo "DRY RUN: kubectl -n $ENV set image deployment/$K8S_DEPLOYMENT mycontainer=myrepo/myapp:$TO_TAG"
  fi
  exit 0
fi

# If k8s deployment provided, try to set image
if [[ -n "$K8S_DEPLOYMENT" ]]; then
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl not found; cannot perform k8s rollback. Provide manual instructions or install kubectl." >&2
    exit 2
  fi
  echo "Setting image for deployment/$K8S_DEPLOYMENT to tag $TO_TAG in namespace $ENV"
  kubectl -n "$ENV" set image deployment/$K8S_DEPLOYMENT mycontainer=myrepo/myapp:$TO_TAG || true
  echo "Triggered rollout. Monitor with: kubectl -n $ENV rollout status deployment/$K8S_DEPLOYMENT"
  exit 0
fi

# Generic instruction fallback
echo "No Kubernetes deployment provided. To rollback, re-deploy artifacts for tag $TO_TAG to $ENV using your CI/CD system."
exit 0
