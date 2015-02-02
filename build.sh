#!/bin/bash

tagName=$1

if ( find /src -maxdepth 0 -empty | read v );
then
  echo "Error: Must mount Go source code into /src directory"
  exit 990
fi

if ! [ -e "/var/run/docker.sock" ];
then
  echo "Error: Docker socket must be mounted at /var/run/docker.sock"
  exit 991
fi

# Grab Go package name
pkgName="$(go list -e -f '{{.ImportComment}}' 2>/dev/null || true)"

if [ -z "$pkgName" ];
then
  echo "Error: Must add canonical import path to root package"
  exit 992
fi

# Grab just first path listed in GOPATH
goPath="${GOPATH%%:*}"

# Construct Go package path
pkgPath="$goPath/src/$pkgName"

# Set-up src directory tree in GOPATH
mkdir -p "$(dirname "$pkgPath")"

# Link source dir into GOPATH
ln -sf /src "$pkgPath"

if [ -e "$pkgPath/Godeps/_workspace" ];
then
  # Add local godeps dir to GOPATH
  GOPATH=$pkgPath/Godeps/_workspace:$GOPATH
else
  # Get all package dependencies
  go get -d -v ./...
fi

# Compile statically linked version of package
CGO_ENABLED=0 go build -a -installsuffix cgo -ldflags '-s' $pkgName

# Grab the last segment from the package name
name=${pkgName##*/}

# Default TAG_NAME to package name if not set explicitly
tagName=${tagName:-"$name":latest}

# Build the image from the Dockerfile in the package directory
docker build -t $tagName .
