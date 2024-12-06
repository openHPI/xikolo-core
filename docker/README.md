# Docker configuration

## Build containers

```console
$ cd docker/
$ docker buildx bake --load
[..]
```

### Build and push to specific registry

```console
$ cd docker/
$ REGISTRY=registry.example.org/container docker buildx bake [--push|--load]
[..]
```

## Configuration

### Environment variables

See `.env`.

### Configuration files

TODO

## Setup

TODO
