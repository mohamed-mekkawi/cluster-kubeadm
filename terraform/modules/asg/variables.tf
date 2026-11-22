variable "name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "disk_size" {
  type    = number
  default = 20
}

variable "key_name" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "subnet_ids" {
  description = "الـ subnets اللي الـ ASG يشغل فيها instances"
  type        = list(string)
}

variable "target_group_arns" {
  description = "الـ Target Groups بتاعة الـ ALB"
  type        = list(string)
  default     = []
}

variable "min_size" {
  type    = number
  default = 1
}

variable "desired_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}
