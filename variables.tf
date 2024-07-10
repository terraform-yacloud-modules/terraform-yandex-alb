#
# Координаты облака Yandex
#
variable "folder_id" {
description = "Идентификатор папки"
type        = string
default     = null
}

variable "region_id" {
description = "Идентификатор зоны доступности, где находится ALB"
type        = string
default     = null
}

#
# Именование
#
variable "name" {
description = "Имя ALB"
type        = string
}

variable "description" {
description = "Описание ALB"
type        = string
default     = ""
}

variable "labels" {
description = "Набор меток"
type        = map(string)
default     = {}
}

#
# Сеть
#
variable "network_id" {
description = "Идентификатор сети, в которой находится ALB"
type        = string
}

variable "security_group_ids" {
description = "Список идентификаторов групп безопасности, присоединенных к ALB"
type        = list(string)
default     = []
}

variable "subnets" {
description = "Список подсетей"
default     = {}
}

variable "create_pip" {
description = "Если true, будет создан публичный IP"
type        = bool
default     = true
}

variable "pip_zone_id" {
description = "Зона для публичного IP"
type        = string
default     = "ru-central1-a"
}

#
# Логирование
#
variable "enable_logs" {
description = "Установите true, чтобы отключить Cloud Logging для балансировщика"
type        = bool
default     = true
}

variable "log_group_id" {
description = "Идентификатор группы Cloud Logging для отправки логов. Оставьте пустым, чтобы использовать группу логов по умолчанию для папки балансировщика"
type        = string
default     = ""
}

variable "discard_rules" {
description = "Список правил игнорирования логов"
type = object({
http_codes          = optional(list(string), [])
http_code_intervals = optional(number)
grpc_codes          = optional(list(string), [])
})
default = null
}

#
# Конфигурация балансировщика нагрузки
#
variable "listeners" {
description = "Слушатели балансировщика нагрузки приложений"
default     = {}
}
