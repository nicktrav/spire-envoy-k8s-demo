variable network {
  type = string
}

variable subnet {
  type = string
}

variable region {
  type = string
}

variable zones {
  type = list(string)
}

variable machine-type {
  type    = string
  default = "n1-standard-4"
}

variable preemptible {
  type    = bool
  default = true
}

variable nodes {
  type    = number
  default = 3
}
