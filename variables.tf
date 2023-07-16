variable "profile" {
  default = "default"
}

variable "region" {
  default = "ap-northeast-1"
}

variable "env" {
  default = "dev"
}

# CloudFront 
variable "dev_bucket"{
  default = ""
}
variable "admin_bucket"{
  default = ""
}
variable "dev_cloudfront_certificate_arn"{
  default = ""
}
variable "admin_cloudfront_certificate_arn"{
  default = ""
}

# RDS
variable "db_name"{
  default = "postgres"
}
variable "engine_version"{
  default = "12.8"
}
variable "identifier"{
  default = "project-postgres"
}
variable "instance_class"{
  default = "db.m6g.large"
}
variable "username" {
  default = "postgres"
}
variable "family"{
  default = "postgres12"
}

# launch_configuration, autoscaling group
variable "source_ami_id"{
  default = ""
}
variable "instance_type"{
  default = "t3a.large"
}

# alb
variable "alb_certificate_arn"{
  default = ""
}

# lambda
variable "project_bucket"{
  default = "project-bucket"
}