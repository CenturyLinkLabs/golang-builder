#!/bin/bash

source /build_environment.sh

# Grab the last segment from the package name
name=${pkgName##*/}

for GOOS in darwin linux; do
        for GOARCH in 386 amd64; do
                echo "Building $name for $GOOS-$GOARCH"
                # Compile statically linked version of package
                `CGO_ENABLED=${CGO_ENABLED:-0} go build \
                        -v \
                        -o $name-$GOOS-$GOARCH \
                        -a \
                        --installsuffix cgo \
                        --ldflags="${LDFLAGS:--s}" \
                        $pkgName`
                rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
        done
done

if [ -e "/var/run/docker.sock" ] && [ -e "./Dockerfile" ];
then
  # Default TAG_NAME to package name if not set explicitly
  tagName=${tagName:-"$name":latest}

  # Build the image from the Dockerfile in the package directory
  docker build -t $tagName .
fi
