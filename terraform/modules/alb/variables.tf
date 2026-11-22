variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "node_port" {
  type    = number
  default = 30080
}

variable "worker1_id" {
  type = string
}
