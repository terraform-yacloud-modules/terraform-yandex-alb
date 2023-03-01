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
  default     = {}
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
  default     = {}
}
