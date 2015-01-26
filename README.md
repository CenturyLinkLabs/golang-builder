## golang-builder
Containerized build environment for compiling an executable Golang package and packaging 
it in a light-weight Docker container.

### Usage

There are a few things that the `golang-builder` needs in order to compile your
application code and wrap it in a Docker image:

* Access to your source code. Inject your source code into the container by mounting it at the `/src` mount point with the `-v` flag.
* Access to the Docker API socket. Since the `golang-builder` code needs to interact with the Docker API in order to build the final image, you need to mount `/var/run/docker.sock` into the container with the `-v` flag when you run it.
* The name of the Go package to be compiled. This is passed as the first argument (immediately after the `centurylink/golang-builder` image name) when running the container.

Assuming that the source code for your Go executable package is located at 
`/home/go/src/github.com/jdoe/helloworld` on your local system you'd run the 
`golang-builder` container as follows:

    docker run --rm \
      -v /home/go/src/github.com/jdoe/helloworld:/src \
      -v /var/run/docker.sock:/var/run/docker.sock \
      centurylink/golang-builder \
      github.com/jdoe/helloworld

This would result in the creation of a new Docker image named `helloworld:latest`.

Note that the image tag is generated dynamically from the name of the Go package. If you'd
like to specify an image tag name you can provide it as an argument after the package
name.

    docker run --rm \
      -v /home/go/src/github.com/jdoe/helloworld:/src \
      -v /var/run/docker.sock:/var/run/docker.sock \
      centurylink/golang-builder \
      github.com/jdoe/helloworld \
      centurylink/helloworld:latest
