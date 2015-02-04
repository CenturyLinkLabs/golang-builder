# golang-builder
Containerized build environment for compiling an executable Golang package and packaging 
it in a light-weight Docker container.

## Overview
One of the (many) benefits of developing with Go is that you have the option of compiling
your application into a self-contained, statically-linked binary. A statically-linked binary
can be run in a container with NO other dependencies which means you can create incredibly 
small images.

With a statically-linked binary, you could have a Dockerfile that looks something like this:

    FROM scratch
    COPY hello /
    ENTRYPOINT ["/hello"]

Note that the base image here is the 0 byte *scratch* image which serves as the root layer for
all Docker images. The only thing in the resulting image will be the copied binary so the total
image size will be roughly the same as the binary itself.

Contrast that with using the official [golang](https://registry.hub.docker.com/u/library/golang/)
image which weighs-in at 500MB before you even copy your application into it.

The *golang-builder* will accept your source code, compile it into a statically-linked binary
and generate a minimal Docker image containing that binary.

The implementation of the *golang-builder* was heavily inspired by the [Create the Smallest Possible Docker Container](http://blog.xebia.com/2014/07/04/create-the-smallest-possible-docker-container/) post on the [Xebia blog](http://blog.xebia.com).

## Requirements
In order for the golang-builder to work properly with your project, you need to follow a few simple conventions:

### Project Structure
The *golang-builder* assumes that your "main" package (the package containing your executable command) is at the root of your project directory structure.

    .
    |-- Dockerfile
    |-- api
    |   |-- api.go
    |   `-- api_test.go
    |-- greeting
    |   |-- greeting.go
    |   `-- greeting_test.go
    |-- hello.go
    `-- hello_test.go
   
In the example above, the `hello.go` source file defines the "main" package for this project and lives at the root of the project directory structure. This project defines other packages ("api" and "greeting") but those are subdirectories off the root.

This convention is in place so that the *golang-builder* knows where to find the "main" package in the project structure. In a future release, we may make this a configurable option in order to support projects with different directory structures.****

### Canonical Import Path
In addition to knowing where to find the "main" package, the *golang-builder* also needs to know the fully-qualified package name for your application. For the "hello" application shown above, the fully-qualified package name for the executable is "github.com/CenturyLink/hello" but there is no way to determine that just by looking at the project directory structure (during the development, the project directory would likely be mounted at `$GOPATH/src/github.com/CenturyLink/hello` so that the Go tools can determine the package name).

In version 1.4 of Go an annotation was introduced which allows you to identify the [canonical import path](https://golang.org/doc/go1.4#canonicalimports) as part of the `package` clause in your source code. The annotation is a specially formatted comment that appears immediately after the `package` clause:

    package main // import "github.com/CenturyLink/hello"

The *golang-builder* will read this annotation from your source code and use it to mount the source code into the proper place in the GOPATH for compilation.

### Dockerfile
The final requirement is that your Dockerfile be placed at the root of your project directory structure. After compiling your Go application, *golang-builder* will execute a `docker build` with your Dockerfile.

The compiled binary will be placed in the root of your project directory so your Dockerfile can be written with the assumption that the application binary is in the same directory as the Dockerfile itself:

    FROM scratch
	EXPOSE 3000
    COPY hello /
    ENTRYPOINT ["/hello"]

In this case, the *hello* binary will be copied right to the root of the image and used as the entrypoint. Since we're using the empty *scratch* image as our base, there is no need to set-up any sort of directory structure inside the image.

## Usage

There are a few things that the *golang-builder* needs in order to compile your
application code and wrap it in a Docker image:

* Access to your source code. Inject your source code into the container by mounting it at the `/src` mount point with the `-v` flag.
* Access to the Docker API socket. Since the *golang-builder* code needs to interact with the Docker API in order to build the final image, you need to mount `/var/run/docker.sock` into the container with the `-v` flag when you run it.

Assuming that the source code for your Go executable package is located at 
`/home/go/src/github.com/CenturyLink/hello` on your local system and you're currently in the `hello` directory, you'd run the `golang-builder` container as follows:

    docker run --rm \
      -v $(pwd):/src \
      -v /var/run/docker.sock:/var/run/docker.sock \
      centurylink/golang-builder

This would result in the creation of a new Docker image named `hello:latest`.

Note that the image tag is generated dynamically from the name of the Go package. If you'd
like to specify an image tag name you can provide it as an argument after the image
name.

    docker run --rm \
      -v $(pwd):/src \
      -v /var/run/docker.sock:/var/run/docker.sock \
      centurylink/golang-builder \
      centurylink/hello:1.0
