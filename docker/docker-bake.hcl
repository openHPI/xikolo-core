# vim: ft=hcl

variable TAG {
  default = "latest"
}

variable CI_COMMIT_REF_NAME {
  default = ""
}

variable CI_COMMIT_SHA {
  default = "latest"
}

variable CI_COMMIT_SHORT_SHA {
  default = ""
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
      "course",
      "grouping",
      "news",
      "nginx",
      "notification",
      "pinboard",
      "quiz",
      "timeeffort",
      "web",
    ]
  }

  name       = "${app}"
  context    = "../"
  dockerfile = "./docker/files/${app}.Dockerfile"

  args = {
    BUILD_REF_NAME         = "${CI_COMMIT_REF_NAME}"
    BUILD_COMMIT_SHA       = "${CI_COMMIT_SHA}"
    BUILD_COMMIT_SHORT_SHA = "${CI_COMMIT_SHORT_SHA}"
  }

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
