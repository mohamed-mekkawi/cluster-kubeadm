region       = "eu-west-1"
project_name = "library-dev"
aws_profile = "new-user"

# الشبكة
vpc_cidr             = "10.0.0.0/16"
public_subnet_a_cidr = "10.0.1.0/24"
public_subnet_b_cidr = "10.0.2.0/24"

# غيّر ده لـ IP بتاعك: افتح https://checkip.amazonaws.com وحط الناتج + /32
my_ip = "197.54.177.2/32"

# اسم الـ Key Pair على AWS (من غير .pem)
key_name = "key-mo"

# السيرفرات
node_instance_type    = "t3.small"
bastion_instance_type = "t3.micro"
node_port             = 30080

# الـ ASG
asg_min_size     = 1
asg_desired_size = 1
asg_max_size     = 3
