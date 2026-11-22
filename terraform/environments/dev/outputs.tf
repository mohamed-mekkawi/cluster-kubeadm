output "bastion_public_ip" {
  description = "اتصل بيه: ssh -i key-mo.pem ubuntu@<ip>"
  value       = module.bastion.public_ip
}

output "master_private_ip" {
  value = module.k8s_nodes.master_private_ip
}

output "worker1_private_ip" {
  value = module.k8s_nodes.worker1_private_ip
}

output "alb_dns_name" {
  description = "رابط الموقع"
  value       = module.alb.alb_dns_name
}
