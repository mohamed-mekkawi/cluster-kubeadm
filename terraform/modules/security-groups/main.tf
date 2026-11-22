# 1) Bastion: SSH من اللابتوب بتاعك بس
resource "aws_security_group" "bastion" {
  name        = "${var.name}-bastion-sg"
  description = "SSH from admin laptop only"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from my laptop"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-bastion-sg" }
}

# 2) ALB: HTTP من أي حد
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "HTTP from internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-alb-sg" }
}

# 3) Nodes (master + workers)
resource "aws_security_group" "nodes" {
  name        = "${var.name}-nodes-sg"
  description = "Kubernetes nodes"
  vpc_id      = var.vpc_id

  # SSH من الـ Bastion فقط (مش من cidr، من الـ SG نفسه)
  ingress {
    description     = "SSH from bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # الـ nodes تكلم بعض بحرية (API server 6443, kubelet, CNI ...)
  ingress {
    description = "All traffic between nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # الـ ALB يوصل للـ NodePort
  ingress {
    description     = "NodePort from ALB"
    from_port       = var.node_port
    to_port         = var.node_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-nodes-sg" }
}
