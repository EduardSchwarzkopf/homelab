variable "proxy_hosts" {
  description = "List of proxy hosts to create"
  type = list(object({
    domain_names   = list(string)
    forward_scheme = string
    forward_host   = string
    forward_port   = number
    block_exploits = optional(bool, true)
  }))
}

variable "credential_id" {
  description = "Credential ID to use for all proxy hosts"
  type        = number
}
