variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "my_ip" {
  description = "الـ IP بتاعك بصيغة x.x.x.x/32"
  type        = string
}

variable "node_port" {
  description = "الـ NodePort اللي الـ ALB هيكلمه"
  type        = number
  default     = 30080
}
