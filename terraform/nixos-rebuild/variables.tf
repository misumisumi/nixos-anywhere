variable "nixos_system" {
  type        = string
  description = "The nixos system to deploy"
}

variable "target_host" {
  type        = string
  description = "DNS host to deploy to"
}

variable "target_user" {
  type        = string
  default     = "root"
  description = "User to deploy as"
}

variable "target_port" {
  type        = number
  description = "SSH port used to connect to the target_host"
  default     = 22
}

variable "ssh_private_key" {
  type        = string
  description = "Content of private key used to connect to the target_host. If set to - no key is passed to openssh and ssh will back to its own configuration"
  default     = "-"
}

variable "ignore_systemd_errors" {
  type = bool
  description = "Ignore systemd errors happening during deploy"
  default = false
}

variable "switch_arg" {
  type = string
  description = "One required argument, which specifies the desired operation."
  default = "switch"
  validation {
    condition     = contains(["switch", "boot", "test"], var.switch_arg)
    error_message = "The argument must be one of 'switch', 'boot', or 'test'."
  }
}
