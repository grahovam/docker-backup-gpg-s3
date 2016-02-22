FROM ubuntu:14.04.3
MAINTAINER technik@myfoodmap.de

RUN apt-get update && apt-get install -y \
  python-pip \
  xz-utils

RUN pip install awscli

ADD backup.sh /backup.sh
ADD restore.sh /restore.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh

CMD ["/run.sh"]
