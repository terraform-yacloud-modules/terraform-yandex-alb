#
# yandex cloud coordinates
#
variable "folder_id" {
  description = "Folder ID"
  type        = string
  default     = null
}

variable "region_id" {
  description = "ID of the availability zone where the ALB resides"
  type        = string
  default     = null
}

#
# naming
#
variable "name" {
  description = "ALB name"
  type        = string
}

variable "description" {
  description = "ALB description"
  type        = string
  default     = ""
}

variable "labels" {
  description = "A set of labels"
  type        = map(string)
  default     = {}
}

#
# network
#
variable "network_id" {
  description = "ID of the network that the ALB is located at"
  type        = string
}

variable "security_group_ids" {
  description = "A list of ID's of security groups attached to the ALB"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "List of subnets"
  type = map(object({
    zone_id         = optional(string, "ru-central1-a")
    id              = optional(string, null)
    disable_traffic = optional(bool, false)
  }))
  default = {}
}

variable "create_pip" {
  description = "If true, public IP will be created"
  type        = bool
  default     = true
}

variable "pip_zone_id" {
  description = "Public IP zone"
  type        = string
  default     = "ru-central1-a"
}

#
# logging
#
variable "enable_logs" {
  description = "Set to true to disable Cloud Logging for the balancer"
  type        = bool
  default     = true
}

variable "log_group_id" {
  description = "Cloud Logging group ID to send logs to. Leave empty to use the balancer folder default log group"
  type        = string
  default     = ""
}

variable "discard_rules" {
  description = "List of logs discard rules"
  type = object({
    http_codes          = optional(list(string), [])
    http_code_intervals = optional(number)
    grpc_codes          = optional(list(string), [])
  })
  default = null
}

#
# load balancer configuration
#
variable "listeners" {
  description = "Application load balancer listeners"
  type        = any
  default     = {}
}

variable "external_ipv4_address" {
  description = "External IPv4 address for the load balancer"
  type        = string
  default     = null
}
