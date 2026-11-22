# Launch Template = "قالب" الـ instance اللي الـ ASG هيعمل منه نسخ
resource "aws_launch_template" "worker" {
  name_prefix   = "${var.name}-worker-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.disk_size
      volume_type = "gp3"
    }
  }

  # بيتنفذ أول ما الـ instance تقوم (هنا بس بنظبط الـ hostname)
  user_data = base64encode(file("${path.module}/user-data.sh"))

  # الـ tags دي بتتحط على الـ instances نفسها (Ansible dynamic inventory هيستخدمها)
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name}-asg-worker"
      Role = "worker"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "workers" {
  name                = "${var.name}-workers-asg"
  min_size            = var.min_size
  desired_capacity    = var.desired_size
  max_size            = var.max_size
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns

  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }
}
