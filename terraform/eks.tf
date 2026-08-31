resource "aws_eks_cluster" "multienv_eks_cluster" {
  name = "multienv_eks_cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.35"

  vpc_config {
    subnet_ids = [
      aws_subnet.privsub_a.id,
      aws_subnet.privsub_b.id,
    ]
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

resource "aws_eks_node_group" "my_eks_ng" {
  cluster_name    = aws_eks_cluster.multienv_eks_cluster.name
  node_group_name = "my_eks_ng"
  node_role_arn   = aws_iam_role.multienv_eks_cluster_iam_role.arn
  subnet_ids      = [aws_subnet.privsub_a.id, aws_subnet.privsub_b.id]

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
    aws_iam_role_policy_attachment.multienv_eks_cluster_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.multienv_eks_cluster_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.multienv_eks_cluster_AmazonEC2ContainerRegistryReadOnly,
  ]
}
