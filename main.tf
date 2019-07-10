provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_internet_gateway" "lamp_igw" {
  tags = {
    "Name" = "lamp-gateway"
  }
  vpc_id   = "${aws_vpc.lamp.id}"
}

resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_vpc.lamp.default_route_table_id}"
  route {
    gateway_id = "${aws_internet_gateway.lamp_igw.id}"
    cidr_block = "0.0.0.0/0"
  }
  tags = {
    Name = "default route table"
  }
}

resource "aws_vpc" "lamp" {
  cidr_block = "10.0.0.0/20"
}

resource "aws_subnet" "rds1" {
  vpc_id     = "${aws_vpc.lamp.id}"
  availability_zone = "${var.aws_region}a"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "RDS"
  }
}

resource "aws_subnet" "rds2" {
  vpc_id     = "${aws_vpc.lamp.id}"
  availability_zone = "${var.aws_region}b"
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "RDS"
  }
}

resource "aws_subnet" "beanstalk-ec2-a" {
  vpc_id     = "${aws_vpc.lamp.id}"
  availability_zone = "${var.aws_region}a"
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "beanstalk"
  }
}

resource "aws_subnet" "beanstalk-ec2-b" {
  vpc_id     = "${aws_vpc.lamp.id}"
  availability_zone = "${var.aws_region}b"
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "beanstalk"
  }
}

resource "aws_iam_instance_profile" "eb-ec2-profile" {
  name        = "aws-elasticbeanstalk-ec2-role"
  path        = "/"
  role        = "aws-elasticbeanstalk-ec2-role"
}

resource "aws_elastic_beanstalk_environment" "lamp-stack" {
      setting {
          name      = "AssociatePublicIpAddress"
          namespace = "aws:ec2:vpc"
          resource  = ""
          value     = "false"
            }
      setting {
          name      = "Automatically Terminate Unhealthy Instances"
          namespace = "aws:elasticbeanstalk:monitoring"
          resource  = ""
          value     = "true"
            }
      setting {
          name      = "Availability Zones"
          namespace = "aws:autoscaling:asg"
          resource  = ""
          value     = "Any"
            }
      setting {
          name      = "ELBScheme"
          namespace = "aws:ec2:vpc"
          resource  = ""
          value     = "public"
            }
      setting {
          name      = "ELBSubnets"
          namespace = "aws:ec2:vpc"
          resource  = ""
          value     = "${aws_subnet.beanstalk-ec2-a.id},${aws_subnet.beanstalk-ec2-b.id}"
            }
      setting {
          name      = "EnvironmentType"
          namespace = "aws:elasticbeanstalk:environment"
          resource  = ""
          value     = "SingleInstance"
            }
      setting {
          name      = "EnvironmentVariables"
          namespace = "aws:cloudformation:template:parameter"
          resource  = ""
          value     = ""
            }
      setting {
          name      = "IamInstanceProfile"
          namespace = "aws:autoscaling:launchconfiguration"
          resource  = ""
          value     = "aws-elasticbeanstalk-ec2-role"
            }
      setting {
          name      = "InstanceType"
          namespace = "aws:autoscaling:launchconfiguration"
          resource  = ""
          value     = "t2.micro"
            }
      setting {
          name      = "InstanceTypeFamily"
          namespace = "aws:cloudformation:template:parameter"
          resource  = ""
          value     = "t2"
            }
      setting {
          name      = "MinSize"
          namespace = "aws:autoscaling:asg"
          resource  = ""
          value     = "1"
            }
      setting {
          name      = "Subnets"
          namespace = "aws:ec2:vpc"
          resource  = ""
          value     = "${aws_subnet.beanstalk-ec2-a.id},${aws_subnet.beanstalk-ec2-b.id}"
            }
      setting {
          name      = "VPCId"
          namespace = "aws:ec2:vpc"
          resource  = ""
          value     = "${aws_vpc.lamp.id}"
            }
  name                  = "lamp-stack"
  application           = "LAMP"
  cname_prefix           = "lampstack"
  solution_stack_name    = "64bit Amazon Linux 2018.03 v2.8.12 running PHP 7.2"
  tags                   = {}
  tier                   = "WebServer"
  # version_label          = "Sample Application"
  wait_for_ready_timeout = "5m"
}

resource "aws_elastic_beanstalk_application" "lampstack-app" {
  name = "LAMP"
  tags = {}
}

resource "aws_db_instance" "mysqldb" {
  allocated_storage                     = 20
  auto_minor_version_upgrade            = true
  availability_zone                     = "${var.aws_region}b"
  backup_retention_period               = 0
  backup_window                         = "05:12-05:42"
  copy_tags_to_snapshot                 = true
  db_subnet_group_name                  = "${aws_db_subnet_group.rds.id}"
  deletion_protection                   = false
  enabled_cloudwatch_logs_exports       = []
  engine                                = "mysql"
  engine_version                        = "5.7.22"
  iam_database_authentication_enabled   = true
  identifier                            = "rds"
  instance_class                        = "db.t2.micro"
  iops                                  = 0
  license_model                         = "general-public-license"
  maintenance_window                    = "wed:04:29-wed:04:59"
  max_allocated_storage                 = 0
  monitoring_interval                   = 0
  multi_az                              = false
  name                                  = "db"
  option_group_name                     = "default:mysql-5-7"
  parameter_group_name                  = "default.mysql5.7"
  performance_insights_enabled          = false
  performance_insights_retention_period = 0
  port                                  = 3306
  publicly_accessible                   = false
  security_group_names                  = []
  skip_final_snapshot                   = true
  storage_encrypted                     = false
  storage_type                          = "gp2"
  tags                                  = {
      "workload-type" = "other"
  }
  username                              = "master"
  password                              = "${var.db_password}"
  vpc_security_group_ids                = [
      "${aws_security_group.rds-sg.id}",
  ]
  timeouts {}
}

resource "aws_db_subnet_group" "rds" {
  description = "RDS subnet group"
  name        = "rds"
  subnet_ids  = [
      "${aws_subnet.rds1.id}",
      "${aws_subnet.rds2.id}",
  ]
  tags        = {}
}

resource "aws_security_group" "rds-sg" {
  description            = "Created from the RDS Management Console: 2019/07/06 11:18:22"
  name                   = "rds-launch-wizard-1"
  revoke_rules_on_delete = false
  tags                   = {}
  vpc_id                 = "${aws_vpc.lamp.id}"
  timeouts {}
}

resource "aws_security_group_rule" "rds-sg-ingress" {
  cidr_blocks       = [
    "99.245.206.50/32",
  ]
  from_port         = 3306
  ipv6_cidr_blocks  = []
  prefix_list_ids   = []
  protocol          = "tcp"
  security_group_id = "${aws_security_group.rds-sg.id}"
  self              = false
  to_port           = 3306
  type              = "ingress"
}

resource "aws_security_group_rule" "rds-sg-egress" {
  cidr_blocks       = [
    "0.0.0.0/0",
  ]
  from_port         = 0
  ipv6_cidr_blocks  = []
  prefix_list_ids   = []
  protocol          = "-1"
  security_group_id = "${aws_security_group.rds-sg.id}"
  self              = false
  to_port           = 0
  type              = "egress"
}
