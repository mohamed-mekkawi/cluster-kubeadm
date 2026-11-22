variable "name" {
  description = "اسم المشروع (بيتحط في أول كل Name tag)"
  type        = string
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
