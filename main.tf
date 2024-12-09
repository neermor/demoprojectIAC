resource "aws_vpc" "demovpc" {
  cidr_block = var.cidr_block
  tags = {
    name = "demovpc"
  }
}

resource "aws_subnet" "awsSubnet1" {
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "awsSubnet2" {
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "aws_internet_gateway" {
  vpc_id = aws_vpc.demovpc.id

}

resource "aws_route_table" "aws_route" {
  vpc_id = aws_vpc.demovpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_internet_gateway.id
  }

}

resource "aws_route_table_association" "rta1" {
  route_table_id = aws_route_table.aws_route.id
  subnet_id      = aws_subnet.awsSubnet1.id

}

resource "aws_route_table_association" "rta2" {
  route_table_id = aws_route_table.aws_route.id
  subnet_id      = aws_subnet.awsSubnet2.id

}
resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.demovpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "trafing from ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Web-sg"
  }

}

resource "aws_s3_bucket" "aws_s3_bucket" {
  bucket = "mybucketneermor"


}

resource "aws_instance" "webserver1" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.awsSubnet1.id
  user_data              = base64encode(file("userdata.sh"))
  tags = {
    name = "machine1"
  }
}
resource "aws_instance" "webserver2" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.awsSubnet2.id
  user_data              = base64encode(file("userdata1.sh"))
  tags = {
    name = "machine2"
  }
}

resource "aws_lb" "myalb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webSg.id]
  subnets            = [aws_subnet.awsSubnet1.id, aws_subnet.awsSubnet2.id]

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demovpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_alb_target_group_attachment" "attachment1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}
resource "aws_alb_target_group_attachment" "attachment2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}
output "lo" {
  value = aws_lb.myalb.dns_name
}
