#!/bin/bash -e

source /build_environment.sh

# Compile statically linked version of package
echo "Building $pkgName"
if [[ $BUILD_RACE_DETECTION == "true" ]];
then
  `CGO_ENABLED=${CGO_ENABLED:-0} go build -a -race --installsuffix cgo --ldflags="${LDFLAGS:--s}" $pkgName` 
else
  `CGO_ENABLED=${CGO_ENABLED:-0} go build -a --installsuffix cgo --ldflags="${LDFLAGS:--s}" $pkgName`
fi

# Grab the last segment from the package name
name=${pkgName##*/}

if [[ $COMPRESS_BINARY == "true" ]];
then
  goupx $name
fi

if [ -e "/var/run/docker.sock" ] && [ -e "./Dockerfile" ];
then
  # Default TAG_NAME to package name if not set explicitly
  tagName=${tagName:-"$name":latest}

  # Build the image from the Dockerfile in the package directory
  docker build -t $tagName .
fi
