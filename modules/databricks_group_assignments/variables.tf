variable "group_id" {
  type = string
}

variable "group_type" {
  type = string
  description = "Group type"
  default = "USER"
  validation {
    condition = contains(["ADMIN", "USER"], var.group_type)
    error_message = "Valid value is one of the following: ADMIN, USER."
  }
}

variable "workspace_id" {
  type = string
}