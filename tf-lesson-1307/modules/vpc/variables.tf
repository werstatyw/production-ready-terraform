variable "env" {
  description = "Env name"
  default = "dev"
  type = string
}

variable "vpc_cidr" {
  description = "Range of ip address available in the VPC"
  type = string
}
variable "public_subnet_cidr" {
  description = "public subnet CIDR block"
  type = string 
}

variable "private_subnet_cidr" {
  description = "private subnet CIDR block"
  type = string
}