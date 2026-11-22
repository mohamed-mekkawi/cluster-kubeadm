# أحدث Ubuntu 22.04 AMI من Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_a_cidr = var.public_subnet_a_cidr
  public_subnet_b_cidr = var.public_subnet_b_cidr
}

module "security_groups" {
  source = "../../modules/security-groups"

  name      = var.project_name
  vpc_id    = module.vpc.vpc_id
  my_ip     = var.my_ip
  node_port = var.node_port
}

module "bastion" {
  source = "../../modules/bastion"

  name              = var.project_name
  ami_id            = data.aws_ami.ubuntu.id
  instance_type     = var.bastion_instance_type
  subnet_id         = module.vpc.public_subnet_a_id
  key_name          = var.key_name
  security_group_id = module.security_groups.bastion_sg_id
}

# Master + Worker 1 في Subnet A
module "k8s_nodes" {
  source = "../../modules/k8s-nodes"

  name              = var.project_name
  ami_id            = data.aws_ami.ubuntu.id
  instance_type     = var.node_instance_type
  subnet_id         = module.vpc.public_subnet_a_id
  key_name          = var.key_name
  security_group_id = module.security_groups.nodes_sg_id
}

module "alb" {
  source = "../../modules/alb"

  name              = var.project_name
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = [module.vpc.public_subnet_a_id, module.vpc.public_subnet_b_id]
  security_group_id = module.security_groups.alb_sg_id
  node_port         = var.node_port
  worker1_id        = module.k8s_nodes.worker1_id
}

# ASG: Worker 2 (وأي workers زيادة) في Subnet B
module "asg" {
  source = "../../modules/asg"

  name              = var.project_name
  ami_id            = data.aws_ami.ubuntu.id
  instance_type     = var.node_instance_type
  key_name          = var.key_name
  security_group_id = module.security_groups.nodes_sg_id
  subnet_ids        = [module.vpc.public_subnet_b_id]
  target_group_arns = [module.alb.target_group_arn]

  min_size     = var.asg_min_size
  desired_size = var.asg_desired_size
  max_size     = var.asg_max_size
}
