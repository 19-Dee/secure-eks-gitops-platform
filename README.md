# Secure Multi-Environment EKS GitOps Platform

A production-style AWS EKS platform built with Terraform, GitHub Actions and ArgoCD.

The project provisions a multi-AZ VPC with private EKS worker nodes, separate development and production Kubernetes environments, GitOps delivery, CI security controls, monitoring and autoscaling.

## Tech Stack

- **AWS** — VPC, EKS, ECR, IAM, ALB, S3 and CloudWatch
- **Terraform** — Infrastructure as Code and remote state management
- **Docker** — Application containerisation
- **Kubernetes / Amazon EKS** — Container orchestration
- **GitHub Actions** — Continuous Integration
- **ArgoCD** — GitOps Continuous Delivery
- **Trivy** — Container vulnerability scanning
- **Checkov** — Terraform security scanning
- **Prometheus** — Kubernetes and workload metrics
- **Grafana** — Monitoring dashboards
- **Metrics Server** — Resource metrics for Kubernetes HPA
- **Helm** — Installation of Kubernetes platform components

## Architecture

<img width="1427" height="1323" alt="Screenshot 2026-09-08 at 16 03 10" src="https://github.com/user-attachments/assets/026244c8-540b-4b70-9f58-34d639875a63" />


## Architecture Overview

1. **Networking**  
   The platform runs inside a multi-AZ VPC in `eu-west-2` with public and private subnets across two Availability Zones. EKS worker nodes run in private subnets, while separate internet-facing ALBs provide access to the dev and prod workloads.

2. **Amazon EKS**  
   AWS manages the Kubernetes control plane while EC2-backed worker nodes provide compute for the cluster. Development and production are separated using Kubernetes namespaces.

3. **Continuous Integration**  
   A developer push triggers GitHub Actions, which builds the application image for `linux/amd64`, scans it with Trivy and pushes an immutable SHA-tagged image to Amazon ECR.

4. **GitOps**  
   After a successful build, GitHub Actions updates the application image reference in the platform GitOps repository. ArgoCD monitors this repository and reconciles the desired Kubernetes state into EKS.

5. **Security**  
   GitHub Actions authenticates to AWS using OIDC instead of long-lived access keys. Trivy scans container images, Checkov scans Terraform configuration and ECR uses immutable image tags with scan-on-push enabled.

6. **Observability**  
   Prometheus and Grafana provide visibility into Kubernetes and workload health, Metrics Server exposes Kubernetes resource metrics used by the development HPA, while Prometheus and Grafana provide broader cluster and workload observability.

> Dev and prod are logical Kubernetes environments and are not tied to specific Availability Zones. Their Pods can be scheduled across worker nodes in either private subnet.

## Features

### Infrastructure as Code

- Terraform provisions the VPC, networking, IAM, EKS, ECR and supporting AWS infrastructure.
- Terraform state is stored remotely in Amazon S3.
- S3-native state locking is used instead of DynamoDB.
- Infrastructure can be recreated consistently from code.

### GitOps Delivery

- Application CI builds and scans the container image before pushing it to ECR.
- CI updates the dev Kubernetes manifest with the new immutable image SHA.
- ArgoCD manages Kubernetes deployment rather than GitHub Actions directly running `kubectl apply`.
- Dev uses automated synchronization, pruning and self-healing.
- Production uses deliberate manual synchronization to create a promotion boundary.

### Security

- GitHub OIDC instead of static AWS credentials.
- Least-privilege IAM permissions.
- Private EKS worker nodes.
- Immutable SHA-tagged ECR images.
- ECR scan-on-push.
- Trivy HIGH/CRITICAL vulnerability gating.
- Checkov Terraform scanning.
- Restricted EKS API access.
- EKS control-plane logging.
- VPC Flow Logs.

### Monitoring and Autoscaling

- Prometheus and Grafana are deployed using `kube-prometheus-stack`.
- Metrics Server provides the Kubernetes resource Metrics API used by the HPA.
- The dev workload uses a CPU-based Horizontal Pod Autoscaler.
- The HPA scales between 1 and 4 replicas.
- Because the portfolio application is lightweight, the CPU target is set to 5% so scaling behaviour can be demonstrated reliably under controlled load.
- Scale-up and scale-down behaviour is rate-limited to one Pod every 30 seconds, producing a controlled scaling pattern rather than abrupt jumps.

During testing, sustained HTTP load was generated against the dev ALB. The workload scaled cleanly from:

`1 → 2 → 3 → 4 replicas`

After the load stopped and CPU utilization dropped below the target, the HPA automatically scaled the workload back down:

`4 → 3 → 2 → 1 replica`

This validated both scale-out and scale-in behaviour without manually changing the replica count during the test.

<img width="758" height="353" alt="Screenshot 2026-09-09 at 11 28 10" src="https://github.com/user-attachments/assets/3cde3b3f-5299-4d43-8242-133579239b17" />

## Prometheus and Grafana

Prometheus collects Kubernetes and workload metrics while Grafana provides dashboards for cluster visibility.

Monitoring includes:

- Pod CPU and memory usage
- Namespace resource usage
- Node health
- Kubernetes object state
- Workload behaviour

Grafana was accessed locally through port forwarding rather than being exposed publicly.

<img width="2526" height="1331" alt="grafana-dash" src="https://github.com/user-attachments/assets/003e4971-706b-4090-9a10-c5ca5e89b772" />

## ArgoCD

ArgoCD implements the GitOps deployment model.

The platform repository stores the desired Kubernetes configuration, while ArgoCD compares that desired state with the actual state running inside EKS and reconciles differences.

For development, synchronization is automated with pruning and self-healing enabled.

Production uses a separate ArgoCD Application with manual synchronization, preventing every application commit from automatically becoming a production deployment.

<img width="2563" height="1355" alt="Screenshot 2026-09-09 at 10 32 08" src="https://github.com/user-attachments/assets/a5fec270-a4a7-445e-98da-94d701347209" />

<img width="2585" height="969" alt="Screenshot 2026-09-09 at 10 31 19" src="https://github.com/user-attachments/assets/2dc510a8-6149-4ded-a2d2-c9c385d76973" />

<img width="2544" height="1069" alt="Screenshot 2026-09-09 at 10 32 11" src="https://github.com/user-attachments/assets/e23d1bfe-386e-4f0e-afbc-514e1cab2a59" />


## Key Engineering Challenges

- **ARM64 vs AMD64 container image mismatch**  
  The application was initially built on Apple Silicon and failed on AMD64 EKS worker nodes. Pod events identified the architecture mismatch, and the CI build was updated to explicitly target `linux/amd64`.

- **EKS authentication vs authorization**  
  AWS credentials were valid, but `kubectl` access was denied because the IAM principal had not been authorized by EKS. This was resolved using EKS Access Entries and access policies.

- **ArgoCD vs HPA replica ownership**  
  ArgoCD and the Horizontal Pod Autoscaler initially both attempted to control the Deployment replica count. The final configuration gives the HPA ownership of `/spec/replicas` while ArgoCD manages the rest of the Deployment.

## Project Status

**Complete**

My platform successfully demonstrates:

- Terraform-managed AWS infrastructure
- Private multi-AZ EKS worker nodes
- Separate dev and prod Kubernetes environments
- GitHub Actions CI
- GitHub-to-AWS OIDC authentication
- Immutable SHA-tagged images in ECR
- Trivy and Checkov security gates
- GitOps delivery through ArgoCD
- Separate internet-facing dev and prod ALBs
- Prometheus and Grafana monitoring
- Metrics Server
- HPA scale-out and scale-in
- EKS control-plane logging
- VPC Flow Logs
- Reproducible infrastructure lifecycle management
