variable "region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_a_cidr" {
  type = string
}

variable "public_subnet_b_cidr" {
  type = string
}

variable "my_ip" {
  description = "IP اللابتوب بتاعك /32"
  type        = string
}

variable "key_name" {
  description = "اسم الـ Key Pair على AWS (من غير .pem)"
  type        = string
}

variable "node_instance_type" {
  type = string
}

variable "bastion_instance_type" {
  type = string
}

variable "node_port" {
  type = number
}

variable "asg_min_size" {
  type = number
}

variable "asg_desired_size" {
  type = number
}

variable "asg_max_size" {
  type = number
}
variable "aws_profile" {
  description ="new-user"
  type        = string
}