resource "aws_eks_cluster" "multienv_eks_master" {
  name = "multienv_eks_master"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.multienv_eks_master_iam_role.arn
  version  = "1.35"

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.admin_cidr
    subnet_ids = [
      aws_subnet.privsub_a.id,
      aws_subnet.privsub_b.id,
    ]
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.master_AmazonEKSClusterPolicy,
  ]
}

resource "aws_eks_node_group" "my_eks_ng" {
  cluster_name    = aws_eks_cluster.multienv_eks_master.name
  node_group_name = "my_eks_ng"
  node_role_arn   = aws_iam_role.multienv_eks_worker_node_iam_role.arn
  subnet_ids      = [aws_subnet.privsub_a.id, aws_subnet.privsub_b.id]
  instance_types  = ["m7i-flex.large"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.multienv_eks_worker_node_iam_role_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.multienv_eks_worker_node_iam_role_AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_eks_addon" "multienv_eks_addon" {
  cluster_name = aws_eks_cluster.multienv_eks_master.name
  addon_name   = "eks-pod-identity-agent"
}

resource "aws_eks_pod_identity_association" "multienv_eks_pod_identity" {
  cluster_name    = aws_eks_cluster.multienv_eks_master.name
  namespace       = "kube-system"
  service_account = "aws-node"
  role_arn        = aws_iam_role.multienv_eks_cni_iam_role.arn

  depends_on = [
    aws_eks_addon.multienv_eks_addon,
    aws_iam_role_policy_attachment.multienv_eks_cni_iam_role_AmazonEKS_CNI_Policy
  ]
}

resource "aws_eks_pod_identity_association" "multienv_eks_lb_controller_pod_identity" {
  cluster_name    = aws_eks_cluster.multienv_eks_master.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.multienv_eks_lb_controller_iam_role.arn
}

resource "aws_eks_access_policy_association" "multienv_eks_access_policy_association" {
  cluster_name  = aws_eks_cluster.multienv_eks_master.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::142969859154:user/devops-user"

  access_scope {
    type = "cluster"
  }
}
