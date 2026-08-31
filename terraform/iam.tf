resource "aws_iam_role" "multienv_eks_cluster_iam_role" {
  name = "multienv_eks_cluster_node_group_iam_role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "multienv_eks_cluster_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.multienv_eks_cluster_iam_role.name
}

resource "aws_iam_role_policy_attachment" "multienv_eks_cluster_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.multienv_eks_cluster_iam_role.name
}

resource "aws_iam_role_policy_attachment" "multienv_eks_cluster_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.multienv_eks_cluster_iam_role.name
}
