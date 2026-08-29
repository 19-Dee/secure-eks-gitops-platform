# Secure Multi-Environment EKS GitOps Platform

A production-style platform engineering project focused on building a secure, automated, and observable Kubernetes deployment platform on AWS.

The platform will use Infrastructure as Code, CI/CD, and GitOps to provision infrastructure, build and scan container images, and deploy applications consistently across development and production environments.

---

## Project Scenario

A growing software team currently deploys its containerised application manually.

This creates several problems:

- Infrastructure can become inconsistent between environments
- Deployments are manual and error-prone
- Security checks are not consistently enforced
- Application releases are difficult to track and roll back
- There is limited visibility into application and cluster health

The goal of this project is to design and build a reusable AWS-based Kubernetes platform that addresses these problems through automation and GitOps practices.

---

## Objectives

The platform should:

- Provision AWS infrastructure using Terraform
- Run containerised workloads on Amazon EKS
- Support separate development and production environments
- Build and scan container images automatically
- Store container images in Amazon ECR
- Use GitHub Actions for CI
- Use ArgoCD for GitOps-based continuous delivery
- Package Kubernetes workloads using Helm
- Enforce container and Infrastructure as Code security checks
- Provide application and cluster observability
- Avoid long-lived AWS credentials in GitHub

---

## Planned Technology Stack

| Area | Technology |
|---|---|
| Cloud | AWS |
| Infrastructure as Code | Terraform |
| Containerisation | Docker |
| Container Registry | Amazon ECR |
| Container Orchestration | Amazon EKS / Kubernetes |
| CI | GitHub Actions |
| GitOps / CD | ArgoCD |
| Kubernetes Packaging | Helm |
| Container Security | Trivy |
| IaC Security | Checkov |
| Monitoring | Prometheus |
| Visualisation | Grafana |
| Source Control | Git / GitHub |

---

## High-Level Delivery Flow

```text
Developer pushes code
        |
        v
GitHub Repository
        |
        v
GitHub Actions
        |
        +--> Validation / Tests
        |
        +--> Security Scanning
        |
        +--> Docker Image Build
        |
        v
Amazon ECR
        |
        v
GitOps Configuration Update
        |
        v
ArgoCD
        |
        v
Amazon EKS
        |
        +--> Development Environment
        |
        +--> Production Environment
        |
        v
Prometheus / Grafana
```

---

## Repository Structure

```text
secure-eks-gitops-platform/
├── app/          # Containerised application
├── terraform/    # AWS infrastructure
├── helm/         # Helm chart for the application
├── gitops/       # ArgoCD and environment configuration
├── .gitignore
└── README.md
```

---

## Planned Infrastructure

The AWS environment will include the core resources required to operate the platform, including:

- VPC and networking
- Public and private subnets
- IAM roles and policies
- Amazon EKS
- EKS worker nodes
- Amazon ECR
- Terraform remote state
- Application ingress and load balancing

The exact architecture will be refined as the project is implemented.

---

## Environments

The platform will initially use a single EKS cluster with separate Kubernetes namespaces:

- `dev`
- `prod`

This provides logical environment separation while keeping the infrastructure appropriate for the scope and cost of the project.

---

## CI/CD and GitOps

The intended workflow is:

```text
Code Change
    ↓
GitHub Actions
    ↓
Validate / Test / Scan
    ↓
Build Docker Image
    ↓
Push Image to Amazon ECR
    ↓
Update GitOps Configuration
    ↓
ArgoCD Detects Desired-State Change
    ↓
Synchronise Kubernetes Resources
    ↓
Application Runs on EKS
```

GitHub Actions will handle **continuous integration**, while ArgoCD will own **continuous delivery** into Kubernetes.

---

## Security

Security will be incorporated throughout the delivery process rather than added only after deployment.

Planned controls include:

- Trivy container vulnerability scanning
- Checkov Terraform scanning
- Least-privilege IAM
- GitHub Actions authentication to AWS using OIDC
- No long-lived AWS credentials committed to the repository
- Kubernetes security configuration where appropriate

---

## Observability

Prometheus and Grafana will provide basic platform and workload monitoring.

The platform should make it possible to investigate questions such as:

- Is the application available?
- Are pods healthy?
- Are containers restarting?
- What CPU and memory resources are workloads consuming?
- Is the Kubernetes environment operating normally?

---

## Definition of Done

The project will be considered complete when:

- AWS infrastructure can be reproduced from Terraform
- EKS is operational
- The application is containerised and stored in ECR
- GitHub Actions successfully runs the CI pipeline
- Security scans are integrated into CI
- Development and production environments are separated
- ArgoCD manages application deployment through GitOps
- The application can be accessed successfully
- Monitoring is available through Prometheus and Grafana
- The architecture and deployment workflow can be explained and troubleshot independently

---

## Project Status

🚧 **In Progress**

**Current phase:** Architecture and infrastructure design
