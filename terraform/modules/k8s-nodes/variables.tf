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

variable "subnet_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "security_group_id" {
  type = string
}
