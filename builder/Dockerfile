FROM alpine:latest
MAINTAINER CenturyLink Labs <clt-labs-futuretech@centurylink.com>

RUN apk update && \
  apk add curl git go build-base bash && \
  rm -rf /var/cache/apk/*

RUN mkdir -p /go/src /go/bin && chmod -R 777 /go
ENV GOPATH=/go
ENV PATH=/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN curl https://get.docker.com/builds/Linux/x86_64/docker-1.3.3 > /usr/bin/docker && chmod +x /usr/bin/docker

VOLUME [/src]
WORKDIR /src

COPY build.sh /

ENTRYPOINT ["/build.sh"]
