FROM alpine:latest

LABEL maintainer="SpaceIndustries"

RUN apk update && apk add --no-cache bash postgresql-client gzip coreutils openssl tzdata \
    && apk add --no-cache cronie \
    && mkdir -p /backup /scripts /cron

COPY backup.sh /backup/backup.sh
COPY restore.sh /backup/restore.sh
COPY crontab.template /cron/crontab.template
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /backup/*.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
