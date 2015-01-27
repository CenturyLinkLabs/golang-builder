FROM golang:1.4

# Install Docker binary
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y wget
RUN wget -nv https://get.docker.com/builds/Linux/x86_64/docker-1.3.3 -O /usr/bin/docker && \
  chmod +x /usr/bin/docker

VOLUME /src
WORKDIR /src

COPY build.sh /

ENTRYPOINT ["/build.sh"]
