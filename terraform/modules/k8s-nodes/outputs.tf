output "master_id" {
  value = aws_instance.master.id
}

output "master_private_ip" {
  value = aws_instance.master.private_ip
}

output "worker1_id" {
  value = aws_instance.worker1.id
}

output "worker1_private_ip" {
  value = aws_instance.worker1.private_ip
}
