variable "aws_region" {
  description = "AWS region in which to deploy the laboratory"
  type        = string
  default     = "eu-west-3"
}

variable "instance_type" {
  description = "EC2 type for one Ubuntu virtual network lab"
  type        = string
  default     = "t3.small"
}
