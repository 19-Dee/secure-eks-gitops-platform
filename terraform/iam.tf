resource "aws_iam_role" "multienv_eks_worker_node_iam_role" {
  name = "multienv_eks_worker_node_iam_role"

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

resource "aws_iam_role" "multienv_eks_cni_iam_role" {
  name = "multienv_eks_cni_iam_role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = ["sts:AssumeRole", "sts:TagSession"]
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role" "multienv_eks_lb_controller_iam_role" {
  name = "multienv_eks_lb_controller_iam_role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = ["sts:AssumeRole", "sts:TagSession"]
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_policy" "multienv_eks_lb_controller_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/policies/aws-load-balancer-controller.json")
}

resource "aws_iam_role_policy_attachment" "multienv_eks_lb_controller_policy_attachment" {
  role       = aws_iam_role.multienv_eks_lb_controller_iam_role.name
  policy_arn = aws_iam_policy.multienv_eks_lb_controller_policy.arn
}

resource "aws_iam_role_policy_attachment" "multienv_eks_worker_node_iam_role_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.multienv_eks_worker_node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "multienv_eks_cni_iam_role_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.multienv_eks_cni_iam_role.name
}

resource "aws_iam_role_policy_attachment" "multienv_eks_worker_node_iam_role_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.multienv_eks_worker_node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "master_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.multienv_eks_master_iam_role.name
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

resource "aws_eks_access_entry" "aws_devopsuser_eks_access_entry" {
  cluster_name  = aws_eks_cluster.multienv_eks_master.name
  principal_arn = "arn:aws:iam::142969859154:user/devops-user"
}
