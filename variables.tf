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
  type = list(object({
    zone_id         = string
    id              = string
    disable_traffic = bool
  }))
  default = []
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
  type = map(object({
    address = string
    zone_id = string
    ports   = list(number)
    type    = string
    tls     = bool
    cert = optional(object({
      type   = optional(string)
      ids    = optional(list(string))
      domain = optional(string)
    }))
    authority = string
    backend = object({
      name             = string
      port             = number
      weight           = number
      http2            = bool
      target_group_ids = list(string)
      health_check = object({
        timeout                 = string
        interval                = string
        interval_jitter_percent = optional(number)
        healthy_threshold       = number
        unhealthy_threshold     = number
        healthcheck_port        = optional(number)
        http = object({
          path = string
        })
      })
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners : contains(["ipv4prv", "ipv4pub", "ipv6"], listener.address)
    ])
    error_message = "Address must be one of: ipv4prv, ipv4pub, ipv6"
  }

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners : contains(["ru-central1-a", "ru-central1-b", "ru-central1-c", "ru-central1-d"], listener.zone_id)
    ])
    error_message = "Zone ID must be one of: ru-central1-a, ru-central1-b, ru-central1-c, ru-central1-d"
  }

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners : alltrue([
        for port in listener.ports : port > 0 && port <= 65535
      ])
    ])
    error_message = "Ports must be between 1 and 65535"
  }

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners : contains(["http", "http2", "stream"], listener.type)
    ])
    error_message = "Type must be one of: http, http2, stream"
  }

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners : listener.backend.weight >= 0 && listener.backend.weight <= 100
    ])
    error_message = "Backend weight must be between 0 and 100"
  }

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners : listener.backend.port > 0 && listener.backend.port <= 65535
    ])
    error_message = "Backend port must be between 1 and 65535"
  }

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners : listener.backend.health_check.healthy_threshold > 0
    ])
    error_message = "Healthy threshold must be greater than 0"
  }

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners : listener.backend.health_check.unhealthy_threshold > 0
    ])
    error_message = "Unhealthy threshold must be greater than 0"
  }

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners :
      listener.backend.health_check.interval_jitter_percent == null ||
      (listener.backend.health_check.interval_jitter_percent >= 0 && listener.backend.health_check.interval_jitter_percent <= 100)
    ])
    error_message = "Interval jitter percent must be between 0 and 100 if specified"
  }

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners :
      listener.backend.health_check.healthcheck_port == null ||
      (listener.backend.health_check.healthcheck_port > 0 && listener.backend.health_check.healthcheck_port <= 65535)
    ])
    error_message = "Healthcheck port must be between 1 and 65535 if specified"
  }

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners : listener.authority != ""
    ])
    error_message = "Authority cannot be empty"
  }

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners : listener.backend.name != ""
    ])
    error_message = "Backend name cannot be empty"
  }

  validation {
    condition = alltrue([
      for listener_key, listener in var.listeners : listener.backend.health_check.http.path != ""
    ])
    error_message = "Health check path cannot be empty"
  }
}

variable "external_ipv4_address" {
  description = "External IPv4 address for the load balancer"
  type        = string
  default     = null
}

variable "timeouts" {
  description = "Timeout settings for cluster operations"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
