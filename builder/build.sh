#!/bin/bash -e

source /build_environment.sh

# Compile statically linked version of package
echo "Building $pkgName"
`CGO_ENABLED=${CGO_ENABLED:-0} go build -a --installsuffix cgo --ldflags="${LDFLAGS:--s}" $pkgName`

# Grab the last segment from the package name
name=${pkgName##*/}

if [[ $COMPRESS_BINARY == "true" ]];
then
  goupx $name
fi

dockerArgs=""

if [[ $NO_CACHE == "true" ]];
then
  dockerArgs="$dockerArgs --no-cache"
fi

dockerFile="Dockerfile"

if [[ $DOCKERFILE != "" ]];
then
  dockerFile=$DOCKERFILE
  dockerArgs="$dockerArgs -f $DOCKERFILE"
fi

if [ -e "/var/run/docker.sock" ] && [ -e "./$dockerFile" ];
then
  # Default TAG_NAME to package name if not set explicitly
  tagName=${tagName:-"$name":latest}

  # Build the image from the Dockerfile in the package directory
  docker build $dockerArgs -t $tagName .
fi
