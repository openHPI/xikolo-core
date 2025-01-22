# vim: ft=hcl

variable TAG {
  default = "latest"
}

variable CI_COMMIT_SHA {
  default = "latest"
}

variable REGISTRY {
  default = ""
}

group default {
  targets = ["build"]
}

target build {
  matrix = {
    app = [
      "account",
      "collabspace",
      "course",
      "grouping",
      "news",
      "nginx",
      "notification",
      "peerassessment",
      "pinboard",
      "quiz",
      "timeeffort",
      "web",
    ]
  }

  name       = "${app}"
  context    = "../"
  dockerfile = "./docker/files/${app}.Dockerfile"

  tags = [
    "${REGISTRY}xikolo-${app}:${TAG}",
    "${REGISTRY}xikolo-${app}:${CI_COMMIT_SHA}",
    "${REGISTRY}xikolo-${app}:latest",
  ]

  annotations = [
    "org.opencontainers.image.ref.name=${TAG}",
    "org.opencontainers.image.revision=${CI_COMMIT_SHA}",
    "org.opencontainers.image.title=xikolo-${app}",
    "org.opencontainers.image.vendor=Hasso Plattner Institute for Digital Engineering gGmbH",
    "org.opencontainers.image.version=${TAG}",
  ]

  platforms = [
    "linux/amd64"
  ]
}
