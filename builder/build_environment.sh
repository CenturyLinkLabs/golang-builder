#!/bin/bash

tagName=$1

if ( find /src -maxdepth 0 -empty | read v );
then
  echo "Error: Must mount Go source code into /src directory"
  exit 990
fi

# Construct Go package path
if [ ! -z "${MAIN_PATH}" ]; 
then
  pkgName="$(go list -e -f '{{.ImportComment}}' ./... 2>/dev/null | grep ${MAIN_PATH} || true)"
  path=$(cd /src && ls -d -1 ${MAIN_PATH})
  pkgBase=${pkgName%/$path}
else
  pkgName="$(go list -e -f '{{.ImportComment}}' 2>/dev/null || true)"
  pkgBase="$pkgName"
fi

echo "using pkgName: $pkgName, pkgBase: $pkgBase"

if [ -z "$pkgName" ];
then
  echo "Error: Must add canonical import path to root package, or specify the MAIN_PATH env var"
  exit 992
fi

# Grab just first path listed in GOPATH
goPath="${GOPATH%%:*}"

pkgPath="$goPath/src/$pkgBase"

# Set-up src directory tree in GOPATH
mkdir -p "$(dirname "$pkgPath")"

# Link source dir into GOPATH
ln -sf /src "$pkgPath"

if [ -e "$pkgPath/vendor" ];
then
  # Enable vendor experiment
  export GO15VENDOREXPERIMENT=1
elif [ -e "$pkgPath/Godeps/_workspace" ];
then
  # Add local godeps dir to GOPATH
  GOPATH=$pkgPath/Godeps/_workspace:$GOPATH
else
  # Get all package dependencies
  go get -t -d -v ./...
fi