data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_vpc" "lab" {
  cidr_block           = "10.70.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "terraform-ospf-vpc" }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "terraform-ospf-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.70.10.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "terraform-ospf-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }
  tags = { Name = "terraform-ospf-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "lab" {
  name_prefix = "terraform-ospf-no-inbound-"
  description = "No inbound access; administration through SSM Session Manager"
  vpc_id      = aws_vpc.lab.id
  tags        = { Name = "terraform-ospf-sg" }
}

resource "aws_vpc_security_group_egress_rule" "ipv4" {
  security_group_id = aws_security_group.lab.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Lab outbound access for package installs and SSM"
}

resource "aws_iam_role" "ec2_ssm" {
  name_prefix = "terraform-ospf-ssm-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name_prefix = "terraform-ospf-profile-"
  role        = aws_iam_role.ec2_ssm.name
}

resource "aws_instance" "lab" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.lab.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/bootstrap.sh")
  user_data_replace_on_change = false
  depends_on                  = [aws_route_table_association.public]

  root_block_device {
    volume_size = 16
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = { Name = "terraform-ospf-lab" }
}
