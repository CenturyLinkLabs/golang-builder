#!/bin/bash

source /build_environment.sh

# Compile statically linked version of package
echo "Building $pkgName"
`CGO_ENABLED=${CGO_ENABLED:-0} go build -a --installsuffix cgo --ldflags="${LDFLAGS:--s}" $pkgName`

if [ -e "/var/run/docker.sock" ] && [ -e "./Dockerfile" ];
then
  # Grab the last segment from the package name
  name=${pkgName##*/}

  # Default TAG_NAME to package name if not set explicitly
  tagName=${tagName:-"$name":latest}

  # Build the image from the Dockerfile in the package directory
  docker build -t $tagName .
fi
