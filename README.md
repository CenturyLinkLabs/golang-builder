# golang-builder
[![](https://badge.imagelayers.io/centurylink/golang-builder.svg)](https://imagelayers.io/?images=centurylink/golang-builder:latest 'Get your own badge on imagelayers.io')

Containerized build environment for compiling an executable Golang package and packaging 
it in a light-weight Docker container.

## Overview
One of the (many) benefits of developing with Go is that you have the option of compiling your application into a self-contained, statically-linked binary. A statically-linked binary can be run in a container with NO other dependencies which means you can create incredibly small images.

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
    ├─Dockerfile
    ├─api
    | ├─api.go
    | └─api_test.go
    ├─greeting
    | ├─greeting.go
    | └─greeting_test.go
    ├─hello.go
    └─hello_test.go
   
In the example above, the `hello.go` source file defines the "main" package for this project and lives at the root of the project directory structure. This project defines other packages ("api" and "greeting") but those are subdirectories off the root.

This convention is in place so that the *golang-builder* knows where to find the "main" package in the project structure. In a future release, we may make this a configurable option in order to support projects with different directory structures.

### Canonical Import Path
In addition to knowing where to find the "main" package, the *golang-builder* also needs to know the fully-qualified package name for your application. For the "hello" application shown above, the fully-qualified package name for the executable is "github.com/CenturyLink/hello" but there is no way to determine that just by looking at the project directory structure (during the development, the project directory would likely be mounted at `$GOPATH/src/github.com/CenturyLink/hello` so that the Go tools can determine the package name).

In version 1.4 of Go an annotation was introduced which allows you to identify the [canonical import path](https://golang.org/doc/go1.4#canonicalimports) as part of your source code. The annotation is a specially formatted comment that appears immediately after the `package` clause:

    package main // import "github.com/CenturyLink/hello"

The *golang-builder* will read this annotation from your source code and use it to mount the source code into the proper place in the GOPATH for compilation.

### Dependencies
There's a good chance that your project imports at least one third-party Go package. The *golang-builder* obviously needs access to any packages that you've imported in order to compile your code. By default, *golang-builder* will `go get` any packages you've imported which aren't part of your project already.

The problem with doing a `go get` with each build is that *golang-builder* may end up with versions of packages which are different than those you developed against. Depending on the stability of the packages that you are importing this may not be an issue. However, if you want to maintain strict control over your dependency versions you may want to look at the [Godep](https://github.com/tools/godep#readme) tool.

If you are using Godep to manage your dependencies *golang-builder* will reference the packages in your `Godeps/_workspace` directory instead of downloading them via `go get`.

### Dockerfile
If you would like to have *golang-builder* package your compiled Go application into a Docker image automatically then the final requirement is that your Dockerfile be placed at the root of your project directory structure. After compiling your Go application, *golang-builder* will execute a `docker build` with your Dockerfile.

The compiled binary will be placed in the root of your project directory so your Dockerfile can be written with the assumption that the application binary is in the same directory as the Dockerfile itself:

    FROM scratch
    EXPOSE 3000
    COPY hello /
    ENTRYPOINT ["/hello"]

In this case, the *hello* binary will be copied right to the root of the image and used as the entrypoint. Since we're using the empty *scratch* image as our base, there is no need to set-up any sort of directory structure inside the image.

If *golang-builder* does **NOT** see a Dockerfile in your project directory it will simply stop after compiling your application.

## Usage

There are a few things that the *golang-builder* needs in order to compile your
application code and wrap it in a Docker image:

* Access to your source code. Inject your source code into the container by mounting it at the `/src` mount point with the `-v` flag.
* Access to the Docker API socket. Since the *golang-builder* code needs to interact with the Docker API in order to build the final image, you need to mount `/var/run/docker.sock` into the container with the `-v` flag when you run it. If you omit the volume mount for the Docker socket, the application will be compiled but not packaged into a Docker image.

Assuming that the source code for your Go executable package is located at 
`/home/go/src/github.com/CenturyLink/hello` on your local system and you're currently in the `hello` directory, you'd run the `golang-builder` container as follows:

    docker run --rm \
      -v "$(pwd):/src" \
      -v /var/run/docker.sock:/var/run/docker.sock \
      centurylink/golang-builder

This would result in the creation of a new Docker image named `hello:latest`.

Note that the image tag is generated dynamically from the name of the Go package. If you'd like to specify an image tag name you can provide it as an argument after the image name.

    docker run --rm \
      -v "$(pwd):/src" \
      -v /var/run/docker.sock:/var/run/docker.sock \
      centurylink/golang-builder \
      centurylink/hello:1.0

If you just want to compile your application without packaging it in a Docker image you can simply run *golang-builder* without mounting the Docker socket.

    docker run --rm -v $(pwd):/src centurylink/golang-builder

### Additional Options

* CGO_ENABLED - whether or not to compile the binary with CGO (defaults to false)
* LDFLAGS - flags to pass to the linker (defaults to '-s')
* COMPRESS_BINARY - if set to true, will use UPX to compress the final binary (defaults to false)

The above are environment variables to be passed to the docker run command:

    docker run --rm \
      -e CGO_ENABLED=true \
      -e LDFLAGS='-extldflags "-static"' \
      -e COMPRESS_BINARY=true \
      -v $(pwd):/src \
      centurylink/golang-builder

### Cross-compilation

An additional image, `centurylink/golang-builder-cross`, exists that works identically to `golang-builder` save for the presence of the additional options presented above. This uses a larger base image that will build linux and OSX binaries for 32- and 64-bit, named like `mypackage-darwin-amd64`. This will use CGO, and you may find that some code – for example things from the `os` package – do not behave the same under cross-compilation in a container as they do natively compiled in OSX.

More information can be found in [the Docker Hub page](https://registry.hub.docker.com/_/golang/) for the official Go images.

## SSL Verification

If your Go application needs to make calls to SSL endpoints you may find your application failing with a message like:

    x509: failed to load system roots and no roots provided
    
One of the down-sides to using the *scratch* image is that you no longer have access to the root CA certificates which come pre-installed in most base images. There are a few different options for dealing with this:

* Disable SSL verification. This is **not** recommended for obvious reasons.
* Bundle the necessary root CA certificates as part of your application.
* Use a different base image which already contains the root CA certificates.

We've created a minimal base image for applications that require SSL verification. The [centurylink/ca-certs](https://registry.hub.docker.com/u/centurylink/ca-certs/) image is simply the *scratch* image with the most common root CA certificates pre-installed. The resulting image is only 258 kB which is still a good starting point for creating your own minimal images.
