FROM alpine
MAINTAINER Falcon Chen <me@cellmean.com>

USER root
ENV VERSION_BEANSTALKD="1.10"

RUN addgroup -S beanstalkd && adduser -S -G beanstalkd beanstalkd
RUN apk add --no-cache 'su-exec>=0.2'

RUN apk --update add --virtual build-dependencies \
  make \
  musl-dev \
  curl \
  && curl -sL https://github.com/kr/beanstalkd/archive/v$VERSION_BEANSTALKD.tar.gz | tar xvz -C /tmp \
  && cd /tmp/beanstalkd-$VERSION_BEANSTALKD \
  && sed -i "s|#include <sys/fcntl.h>|#include <fcntl.h>|g" sd-daemon.c \
  && make \
  && cp beanstalkd /usr/bin \
  && apk del build-dependencies \
  && rm -rf /tmp/* \
  && rm -rf /var/cache/apk/*

RUN GOSU_SHA=5ec5d23079e94aea5f7ed92ee8a1a34bbf64c2d4053dadf383992908a2f9dc8a \
  && curl -sSL -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.9/gosu-$(dpkg --print-architecture)" \
  && chmod +x /usr/local/bin/gosu \
  && echo "$GOSU_SHA  /usr/local/bin/gosu" | sha256sum -c -   

RUN mkdir /data && chown beanstalkd:beanstalkd /data
VOLUME ["/data"]
EXPOSE 11300

ENTRYPOINT ["gosu","beanstalkd", "-p", "11300", "-u", "beanstalkd"]
CMD ["-b", "/data"]
