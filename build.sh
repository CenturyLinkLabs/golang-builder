#!/bin/bash

PKG_NAME=$1
TAG_NAME=$2

if ( find /src -maxdepth 0 -empty | read v );
then
  echo "Error: Must mount Go source code into /src directory"
  exit 990
fi

if [ -z "$PKG_NAME" ];
then
  echo "Error: Must specify Go package to be compiled"
  exit 991
fi

if ! [ -e "/var/run/docker.sock" ];
then
  echo "Error: Docker socket must be mounted at /var/run/docker.sock"
  exit 992
fi

# Set-up src directory tree in GOPATH
mkdir -p /gopath/src/$PKG_NAME

# Copy mounted source code into GOPATH
cp -r /src/* /gopath/src/$PKG_NAME

# Change to package directory
cd /gopath/src/$PKG_NAME

# Get all package dependencies
go get -d -v ./... 

# Compile statically linked version of package
CGO_ENABLED=0 go build -a -ldflags '-s' $PKG_NAME

# Grab the last segment from the package name
NAME=${PKG_NAME##*/}

# Default TAG_NAME to package name if not set explicitly
TAG_NAME=${TAG_NAME:-"$NAME":latest}

# Build the image from the Dockerfile in the package directory
docker build -t $TAG_NAME .
