DRIVER_NAME := ray-gpu
MODULE := github.com/NVIDIA/$(DRIVER_NAME)

REGISTRY ?= nvcr.io/nvidia

VERSION ?= v0.17.1

# vVERSION represents the version with a guaranteed v-prefix
vVERSION := v$(VERSION:v%=%)

GOLANG_VERSION=$(grep -E "^FROM golang:.*$" ${DOCKERFILE_ROOT}/Dockerfile | grep -oE "[0-9\.]+")

BUILDIMAGE_TAG ?= devel-go$(GOLANG_VERSION)
BUILDIMAGE ?=  $(DRIVER_NAME):$(BUILDIMAGE_TAG)

GIT_COMMIT ?= $(shell git describe --match="" --dirty --long --always --abbrev=40 2> /dev/null || echo "")

# @TODO: add ray version namespace etc