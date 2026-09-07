# Secure Multi-Environment EKS GitOps Platform

A production-style AWS platform engineering project that provisions Kubernetes infrastructure with Terraform, deploys applications through GitOps, integrates CI security controls, separates development and production environments, and adds monitoring and autoscaling.

The project was built end-to-end to demonstrate practical ownership of infrastructure, CI/CD, Kubernetes, security, observability, troubleshooting, and platform lifecycle management.

---

## Architecture

The platform separates responsibilities across infrastructure provisioning, continuous integration, GitOps delivery, Kubernetes operations, security, and observability.


<img width="1644" height="1138" alt="Screenshot 2026-09-07 at 20 59 39" src="https://github.com/user-attachments/assets/503577c5-eb7d-4923-a411-57f1ca1c4fa0" />


> **Architecture note:** Dev and prod namespaces are logical Kubernetes environments and are not pinned to specific Availability Zones. Their Pods can be scheduled across worker nodes in either private subnet. The Dev and Prod ALBs are separate internet-facing load balancers, and each spans both public subnets for multi-AZ availability.
>
> With `target-type: ip`, inbound application traffic is effectively `User → Internet → ALB → registered Pod IP target`. Kubernetes Ingress and Service objects define the desired backend routing, while the AWS Load Balancer Controller reconciles that configuration into AWS ALBs and target groups. Private workload egress uses `Pod/worker → NAT Gateway → Internet Gateway → Internet`.

### Application delivery flow

```text
Application commit
      ↓
GitHub Actions
      ↓
Docker image build (linux/amd64)
      ↓
Trivy image scan
      ↓
GitHub OIDC → AWS IAM role
      ↓
Push immutable SHA-tagged image to Amazon ECR
      ↓
Update dev Kubernetes manifest in Platform/GitOps repository
      ↓
ArgoCD detects Git change
      ↓
Automatic dev reconciliation
```

GitHub Actions handles continuous integration and artifact delivery.

ArgoCD owns deployment into Kubernetes, so CI does not directly run `kubectl apply`.

### Infrastructure flow

```text
Engineer
   ↓
Terraform CLI
   ↓
AWS infrastructure
```

Terraform uses an S3 remote backend with S3-native state locking.

Terraform provisioning is performed manually from the local engineering environment rather than from GitHub Actions.

### Platform security CI

```text
Platform repository
      ↓
GitHub Actions
      ↓
Checkov
      ↓
Terraform IaC security scan
```

---

## What I Built

The platform includes:

- Terraform-managed AWS infrastructure
- Multi-AZ VPC across `eu-west-2a` and `eu-west-2b`
- Public and private subnets
- One NAT Gateway per Availability Zone
- Private Amazon EKS worker nodes
- AWS-managed EKS control plane
- Amazon ECR
- GitHub Actions CI
- GitHub-to-AWS OIDC authentication
- Trivy container vulnerability scanning
- Checkov Terraform scanning
- ArgoCD GitOps delivery
- Separate `dev` and `prod` Kubernetes namespaces
- AWS Load Balancer Controller
- Separate internet-facing dev and prod ALBs
- Prometheus and Grafana
- Kubernetes Metrics Server
- Horizontal Pod Autoscaling in dev
- Terraform remote state in S3 with S3-native locking
- EKS control-plane logging
- VPC Flow Logs

---

## Tech Stack

| Area | Technology |
|---|---|
| Cloud | AWS |
| IaC | Terraform |
| Containers | Docker |
| Kubernetes | Amazon EKS |
| Registry | Amazon ECR |
| CI | GitHub Actions |
| GitOps | ArgoCD |
| Security | Trivy, Checkov |
| Monitoring | Prometheus, Grafana |
| Autoscaling | Kubernetes HPA |
| Authentication | GitHub OIDC, IAM |
| Logging | Amazon CloudWatch Logs |

---

## AWS Networking

The platform uses a VPC with CIDR:

```text
10.0.0.0/16
```

across two Availability Zones.

### `eu-west-2a`

```text
Public Subnet A
10.0.1.0/24

Private Subnet A
10.0.11.0/24
```

### `eu-west-2b`

```text
Public Subnet B
10.0.2.0/24

Private Subnet B
10.0.12.0/24
```

Each public subnet contains a NAT Gateway used for outbound Internet access from the corresponding private subnet.

The worker nodes run in private subnets. Internet-facing ALBs span both public subnets.

### Inbound application traffic

```text
User
  ↓
Internet
  ↓
Internet-facing Dev or Prod ALB
  ↓
Registered Pod IP target
```

The Ingress and Service objects are configuration inputs rather than literal packet-processing hops.

The AWS Load Balancer Controller watches Kubernetes Ingress, Service, and endpoint information, then configures AWS ALBs and target groups.

### Outbound private workload traffic

```text
Private Pod / worker
  ↓
NAT Gateway
  ↓
Internet Gateway
  ↓
Internet
```

The NAT Gateway is not part of the inbound user traffic path.

---

## EKS Architecture

The EKS control plane is managed by AWS.

The EC2-backed managed node group runs in the private subnets.

Final node-group configuration:

```text
min:     1
desired: 1
max:     2
```

The node group spans both private subnets across the two Availability Zones.

The `dev` and `prod` namespaces are logical Kubernetes environments. They are not tied to a particular Availability Zone or worker node.

---

## CI/CD and GitOps

### Development

The `dev` environment uses:

- automated ArgoCD sync
- pruning
- self-healing
- Horizontal Pod Autoscaling

Application CI updates the image SHA in the dev Kubernetes manifest after a successful image build and Trivy scan.

ArgoCD detects that Git change and reconciles the dev environment automatically.

### Production

Production uses separate Kubernetes manifests and a separate ArgoCD Application.

Unlike dev, production does **not** use automated ArgoCD synchronization.

Changes must be deliberately synchronized into production through manual ArgoCD sync, creating an explicit promotion boundary and preventing every application commit from automatically becoming a production deployment.

---

## Security

Security controls implemented in the platform include:

- GitHub Actions authentication to AWS using OIDC
- no long-lived AWS access keys in CI
- least-privilege IAM policies
- EKS Pod Identity for AWS-integrated Kubernetes workloads
- immutable ECR image tags
- ECR scan-on-push
- Trivy HIGH/CRITICAL vulnerability gating
- Checkov Terraform scanning in GitHub Actions
- restricted EKS public API CIDRs
- EKS control-plane logging
- VPC Flow Logs
- locked-down default VPC security group

Checkov findings were reviewed individually rather than blindly suppressed. Accepted exceptions are explicitly defined in the CI workflow.

---

## Observability

The cluster used `kube-prometheus-stack`, installed into a `monitoring` namespace with Helm.

This provided:

- Prometheus
- Grafana
- kube-state-metrics
- node-exporter
- Alertmanager
- Prometheus Operator

This provided visibility into:

- pod CPU and memory
- namespace resource usage
- node health
- Kubernetes object state
- workload behaviour

Grafana was accessed locally through port forwarding rather than being exposed publicly.

Amazon CloudWatch Logs was used specifically for:

- EKS control-plane logs
- VPC Flow Logs

CloudWatch was not the primary application or workload metrics platform in this project.

> The monitoring stack was installed operationally with Helm and was not stored as a `k8s/monitoring/` directory in the repository.

---

## Metrics Server and Horizontal Pod Autoscaling

Metrics Server was installed separately in `kube-system` to provide the Kubernetes resource Metrics API used by `kubectl top` and the HPA.

The development workload uses an `autoscaling/v2` HPA.

Final configuration:

```text
Minimum replicas: 1
Maximum replicas: 4
Metric: CPU utilization
Target: 50%
```

The application defines CPU and memory requests so Kubernetes can calculate CPU utilization correctly.

Because the Flask workload is lightweight and did not naturally exceed the final 50% CPU target during a practical demonstration, the threshold was temporarily lowered to validate autoscaling behaviour.

During the test:

```text
1 replica
   ↓
sustained HTTP traffic
   ↓
CPU utilization increased
   ↓
HPA scaled to 4 replicas
   ↓
traffic stopped
   ↓
Kubernetes scale-down stabilization
   ↓
returned to 1 replica
```

The HPA was then restored to its final 50% CPU target.

This validated both scale-out and scale-in behaviour.

---

## Repository Structure

```text
secure-eks-gitops-platform/
├── .github/
│   └── workflows/
│       └── checkov.yml
├── bootstrap/
│   └── Terraform remote-state infrastructure
├── k8s/
│   ├── argocd/
│   ├── dev/
│   ├── prod/
│   └── system/
├── terraform/
├── .gitignore
└── README.md
```

The application source and application CI workflow are maintained in a separate repository.

Monitoring components such as `kube-prometheus-stack` and Metrics Server were installed operationally using Helm rather than being fully represented by committed monitoring manifests.

---

## Key Engineering Challenges

### EKS Authentication

AWS credentials were valid, but `kubectl` could not access the cluster.

The issue was EKS authorization rather than IAM authentication.

The final access path was:

```text
IAM principal
   ↓
EKS Access Entry
   ↓
EKS Access Policy
   ↓
Kubernetes permissions
```

### ARM64 vs AMD64 Images

The application was initially built on Apple Silicon and failed on AMD64 EKS worker nodes.

Pod events revealed a container platform mismatch.

The Docker build was updated to explicitly target:

```text
linux/amd64
```

### AWS Load Balancer Controller Startup

The AWS Load Balancer Controller initially failed while attempting to discover its VPC through instance metadata.

Controller logs were used to identify the problem.

Explicit region and VPC configuration allowed the controller to start successfully.

### Terraform State and Existing AWS Resources

An AWS Load Balancer Controller IAM policy already existed in AWS but was not present in Terraform state.

Terraform attempted to create it and AWS returned an existing-resource error.

The resource was imported into Terraform state rather than unnecessarily recreated.

This reinforced the distinction between:

```text
resource exists in AWS
≠
Terraform manages the resource
```

### Terraform Teardown

`terraform destroy` initially failed because AWS Load Balancer Controller-managed resources still existed inside the VPC.

This highlighted an important ownership boundary:

```text
Terraform
   → underlying AWS infrastructure

AWS Load Balancer Controller
   → ALB-related AWS resources derived from Kubernetes Ingress
```

The correct teardown order is to remove Ingress resources while the controller is still alive, allow it to clean up its AWS resources, and only then destroy the underlying EKS/VPC infrastructure.

### Checkov Local vs CI

Checkov passed locally but initially failed in GitHub Actions because a Terraform variable value existed only in the local environment.

A safe CI-specific `tfvars` file was added so the remote runner could evaluate the same Terraform configuration.

### ArgoCD vs HPA

ArgoCD and the HPA initially both affected the Deployment replica count.

The final design gives the HPA ownership of:

```text
/spec/replicas
```

while ArgoCD manages the rest of the Deployment.

ArgoCD is configured to ignore differences in the replica field for the dev Deployment.

### Metrics Server vs Prometheus

Prometheus and Grafana were successfully collecting cluster metrics, but `kubectl top` initially failed because the Kubernetes Metrics API was unavailable.

Metrics Server was installed separately to provide `metrics.k8s.io`, which the HPA uses for CPU-based scaling.

### HPA Scale-Down Stabilization

After load stopped, the HPA remained at four replicas temporarily.

`kubectl describe hpa` showed that Kubernetes was intentionally applying its scale-down stabilization window rather than malfunctioning.

After the stabilization period elapsed, the workload returned from four replicas to one.

### Git Repository Boundary

A Git repository was accidentally rooted too high in the local filesystem, which caused unrelated directories to appear as potential repository content.

The issue was detected before sensitive files were pushed.

This reinforced the habit of checking:

```bash
git rev-parse --show-toplevel
git status
git remote -v
```

before broad staging operations.

---

## Reproducing the Platform

### 1. Bootstrap remote state

```bash
cd bootstrap
terraform init
terraform apply
```

### 2. Provision AWS infrastructure

```bash
cd ../terraform
terraform init
terraform plan
terraform apply
```

### 3. Configure kubectl

```bash
aws eks update-kubeconfig \
  --region eu-west-2 \
  --name multienv_eks_master
```

### 4. Install platform components

Install:

- AWS Load Balancer Controller
- ArgoCD
- `kube-prometheus-stack`
- Metrics Server

### 5. Apply ArgoCD applications

```bash
kubectl apply -f k8s/argocd/dev-application.yaml
kubectl apply -f k8s/argocd/prod-application.yaml
```

---

## Validation

Useful checks:

```bash
kubectl get nodes
kubectl get pods -A
kubectl get applications -n argocd
kubectl get hpa -n dev
kubectl top pods -n dev
terraform plan
```

A fully reconciled Terraform environment should return:

```text
No changes. Your infrastructure matches the configuration.
```

---

## Evidence

Useful project evidence includes:

- ArgoCD showing healthy dev and prod Applications
- Grafana Kubernetes dashboards
- HPA scaling from 1 to 4 replicas
- HPA scaling back from 4 to 1
- successful GitHub Actions Trivy pipeline
- successful Checkov GitHub Actions workflow
- final Terraform zero-drift plan

---

## Business Impact

The platform was designed to replace manual, inconsistent infrastructure and deployment practices with repeatable automation and controlled delivery.

The resulting platform:

- reduces configuration drift through Terraform-managed infrastructure
- reduces deployment risk through GitOps reconciliation
- removes long-lived AWS credentials from CI through OIDC
- shifts security checks earlier into CI with Trivy and Checkov
- improves release traceability through immutable SHA-tagged container images
- creates a deliberate production promotion boundary
- improves operational visibility through Prometheus and Grafana
- demonstrates workload resilience through Horizontal Pod Autoscaling
- improves recoverability by allowing the AWS platform to be destroyed and recreated from code

No artificial business percentages or cost savings are claimed because these were not measured in a real production organization.

---

## Scope

This version intentionally does **not** include:

- Route 53
- custom domains
- TLS / certificate management
- AWS Secrets Manager
- multiple EKS clusters
- node autoscaling with Karpenter or Cluster Autoscaler
- service mesh
- database infrastructure
- application Helm packaging
- custom application Prometheus instrumentation

The goal was to demonstrate a focused, production-style EKS platform without adding unnecessary technology.

---

## Project Status

**Complete**

Validated outcomes include:

- reproducible AWS infrastructure
- secure EKS deployment
- CI using short-lived AWS credentials through OIDC
- immutable SHA-tagged container images
- Trivy and Checkov security gates
- GitOps deployment through ArgoCD
- separate dev and prod environments
- separate multi-AZ internet-facing ALBs
- Prometheus and Grafana monitoring
- Kubernetes Metrics Server
- HPA scale-out from 1 to 4 replicas
- HPA scale-in back to 1 replica
- EKS control-plane logging
- VPC Flow Logs
- zero Terraform drift after final reconciliation
- successful teardown and cleanup of the platform
