#!/bin/bash

source /build_environment.sh

if [ "$GO15VENDOREXPERIMENT"=="1" ]; 
then
    go test -v $(go list ./... | grep -v /vendor/ | sed s,_/src,$pkgName,g)
else
    go test -v  ./...
fi
