# vim: ft=hcl

variable TAG {
  default = "latest"
}

variable CI_REGISTRY_IMAGE {
  default = "registry.gitlab.hpi.de/openpi/xikolo/web"
}

group default {
  targets = ["ruby-base", "ruby-base-chrome"]
}

target ruby-base {
  dockerfile = "docker/files/base.Dockerfile"
  target     = "ruby-base"

  tags = [
    "${CI_REGISTRY_IMAGE}/ruby-base:${TAG}",
    "${CI_REGISTRY_IMAGE}/ruby-base:latest",
  ]

  platforms = [
    "linux/amd64"
  ]
}

target ruby-base-node {
  inherits = ["ruby-base"]
  target   = "ruby-base-node"

  tags = [
    "${CI_REGISTRY_IMAGE}/ruby-base-node:${TAG}",
    "${CI_REGISTRY_IMAGE}/ruby-base-node:latest",
  ]

  platforms = [
    "linux/amd64"
  ]
}

target ruby-base-chrome {
  inherits = ["ruby-base"]
  target   = "ruby-base-chrome"

  tags = [
    "${CI_REGISTRY_IMAGE}/ruby-base-chrome:${TAG}",
    "${CI_REGISTRY_IMAGE}/ruby-base-chrome:latest",
  ]

  platforms = [
    "linux/amd64"
  ]
}
