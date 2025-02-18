variable "region" {
  type    = string
  default = "West Europe"
}
variable "cidr" {
  type        = string
  default     = "10.179.0.0/20"
  description = "Network range for created virtual network."
}

variable "no_public_ip" {
  type        = bool
  default     = true
  description = "Defines whether Secure Cluster Connectivity (No Public IP) should be enabled."
}

variable "prefix" {
  type        = string
  description = "Prefix to use"
  default     = "tf-modular-deploy"
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Optional tags to add to created resources"
}
