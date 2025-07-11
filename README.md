# DevSecOps lab

![DevSecOps release (latest SemVer)](https://img.shields.io/github/v/tag/AdamDubnytskyy/DevSecOps?sort=semver)

## Prerequisites
Either options will satisfy development environment:

- running kubernetes cluster. See [control-plane-ref](https://github.com/AdamDubnytskyy/k8s-controller/blob/main/docs/control-plane/README.md) to spin up kubernetes cluster for dev environment.

- running kind cluster. See [kind docs](https://kind.sigs.k8s.io/docs/user/quick-start/).

## Requirements
[Step 1](docs/step1-create-kubernetes-deployment/README.md). Create a Kubernetes deployment. ✅

[Step 2](docs/step2-ensure-deployment-even-distribution-across-cluster/README.md). Ensure the deployment is evenly distributed across the cluster. ✅

[Step 3](docs/step3-follow-security-best-practices/README.md). Follow Kubernetes, container, and security best practices. ✅
