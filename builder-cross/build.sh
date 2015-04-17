#!/bin/bash

source /build_environment.sh

# Grab the last segment from the package name
name=${pkgName##*/}

for GOOS in darwin linux; do
        for GOARCH in 386 amd64; do
                echo "Building $name for $GOOS-$GOARCH"
                # Why am I redefining the same variables that already existed?
                # Somehow they're not available just from the loop, unless I
                # either export them or do this. My theory is that it's somehow
                # building in another process that doesn't have access to the
                # loop variables. That caused everything to be built for linux.
                `GOOS=$GOOS GOARCH=$GOARCH go build \
                        -v \
                        -o $name-$GOOS-$GOARCH \
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
