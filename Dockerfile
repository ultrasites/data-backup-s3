# mysql backup image
FROM alpine:3.9
LABEL maintainer="info@ultra-sites.de"

RUN apk add --update bash python3 shadow openssl coreutils && \
    rm -rf /var/cache/apk/*  && \
    pip3 install awscli

RUN groupadd -g 1005 backupuser && \
    useradd -r -m -u 1005 -g backupuser backupuser
USER backupuser

RUN mkdir /home/backupuser/data
VOLUME ["/home/backupuser/data"]

COPY functions.sh /
COPY entrypoint /entrypoint

ENTRYPOINT ["/entrypoint"]
