variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "my_ip" {
  description = "Your IP address for SSH access"
  type        = string
  default     = "0.0.0.0/0" # Замените на ваш IP
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "project"
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "your-key-pair" # Замените на ваш key pair
}