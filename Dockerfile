FROM alpine:3.4
MAINTAINER technik@myfoodmap.de

RUN apk add --update \
    py-pip \
    gpgme \
    xz \
    && rm -rf /var/cache/apk/*

RUN pip install awscli

ADD backup.sh /backup.sh
ADD restore.sh /restore.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh

CMD ["/run.sh"]
