# Master node (Control Plane)
resource "aws_instance" "master" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true # محتاجينه عشان ينزل packages، والـ SSH مقفول من الـ SG

  root_block_device {
    volume_size = var.disk_size
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.name}-master"
    Role = "master"
  }
}

# Worker Node 1 (في نفس الـ subnet A زي الرسمة)
resource "aws_instance" "worker1" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.disk_size
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.name}-worker-1"
    Role = "worker"
  }
}
