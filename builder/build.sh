#!/bin/bash -e

source /build_environment.sh

# Grab the last segment from the package name
name=${pkgName##*/}

#
# Optional OUTPUT env var to use the "-o" go build switch
# forces build to write the resulting executable or object
# to the named output file
#
output=""
outputFile=""
if [[ ! -z "${OUTPUT}" ]];
then
  outputFile="${OUTPUT}"
  #
  # If OUTPUT env var ends with "/", assume an output directory
  # was specified, and we should append the executable name.
  #
  if [[ "$outputFile" == *"/" ]];
  then
    outputFile="${outputFile}${name}"
  fi
  output="-o ${outputFile}"
fi

# Compile statically linked version of package
echo "Building $pkgName => ${outputFile}"
(
  CGO_ENABLED=${CGO_ENABLED:-0} \
  go build \
  -a \
  ${output} \
  --installsuffix cgo \
  --ldflags="${LDFLAGS:--s}" \
  $pkgName
)

if [[ "$COMPRESS_BINARY" == "true" ]];
then
  if [[ ! -z "${outputFile}" ]];
  then
    goupx "${outputFile}"
  else
    goupx $name
  fi
fi

dockerContextPath="."
if [ ! -z "${DOCKER_BUILD_CONTEXT}" ];
then
  dockerContextPath="${DOCKER_BUILD_CONTEXT}"
fi

if [[ -e "/var/run/docker.sock"  &&  -e "${dockerContextPath}/Dockerfile" ]];
then
  # Default TAG_NAME to package name if not set explicitly
  tagName=${tagName:-"$name":latest}

  # Build the image from the Dockerfile in the package directory
  docker build -t $tagName "$dockerContextPath"
fi