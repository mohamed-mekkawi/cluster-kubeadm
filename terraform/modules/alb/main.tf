resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  tags = { Name = "${var.name}-alb" }
}

# Target Group: الـ ALB هيبعت الـ traffic على NodePort للـ workers
resource "aws_lb_target_group" "this" {
  name     = "${var.name}-tg"
  port     = var.node_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path    = "/"
    port    = "traffic-port"
    matcher = "200-404" # لحد ما التطبيق يتنشر، الـ ingress بيرجع 404 وده معناه إنه شغال
  }
}

# Listener: أي request على بورت 80 يروح للـ Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# ضم الـ worker1 (instance عادية مش من الـ ASG) للـ Target Group
resource "aws_lb_target_group_attachment" "worker1" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.worker1_id
  port             = var.node_port
}
