resource "aws_eks_cluster" "multienv_eks_master" {
  name = "multienv_eks_master"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.multienv_eks_master_iam_role.arn
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
  cluster_name    = aws_eks_cluster.multienv_eks_master.name
  node_group_name = "my_eks_ng"
  node_role_arn   = aws_iam_role.multienv_eks_master_iam_role.arn
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
    aws_iam_role_policy_attachment.multienv_eks_master_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.multienv_eks_master_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.multienv_eks_master_AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "multienv_eks_master_iam_role" {
  name = "multienv_eks_master_iam_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "master_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.multienv_eks_master_iam_role.name
}
