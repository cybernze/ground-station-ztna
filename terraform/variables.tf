variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-south-2"
}

variable "my_ip" {
  description = "Your public IP in CIDR format (e.g. 1.2.3.4/32)"
  type        = string
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "ground-station"
}

variable "ec2_instance_type" {
  description = "EC2 instance type (Free Tier: t3.micro in eu-south-2)"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Amazon Linux 2023 AMI ID for eu-south-2"
  type        = string
  # Amazon Linux 2023 en eu-south-2 (verificar en console si cambia)
  default = "ami-0c97e386812b2fea0"
}

variable "operator_public_key" {
  description = "SSH public key content for EC2 operator access. Set via TF_VAR_operator_public_key or terraform.tfvars."
  type        = string
  default     = ""
}
