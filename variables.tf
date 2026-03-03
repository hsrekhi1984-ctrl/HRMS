variable "project_name" {
  description = "Short project name used as a prefix for resource names."
  type        = string
  default     = "hrms"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,20}$", var.project_name))
    error_message = "project_name must be 2-20 characters and use only lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Environment label for naming and tagging."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, stage, prod."
  }
}

variable "location" {
  description = "Azure region where resources will be created."
  type        = string
  default     = "East US"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Set null to let Azure choose a default."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Initial number of nodes for the AKS system node pool."
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "node_count must be between 1 and 10 for this learning setup."
  }
}

variable "node_vm_size" {
  description = "VM size for AKS nodes."
  type        = string
  default     = "Standard_DS2_v2"
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
