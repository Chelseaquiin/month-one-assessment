####################################
# VARIABLES
####################################

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "web_instance_type" {
  description = "Instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "Instance type for database server"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of EC2 key pair"
  type        = string
}

variable "my_ip" {
  description = "Your public IP address"
  type        = string
}
