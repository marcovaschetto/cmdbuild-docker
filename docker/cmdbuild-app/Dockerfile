# ---- Stage 1: download ----
FROM alpine:3.20 AS downloader

ARG WAR_URL=https://sourceforge.net/projects/cmdbuild/files/ready2use-2.4/ready2use-2.4-4.0.4.war/download

WORKDIR /war
RUN apk add --no-cache curl unzip && \
    curl -L -o cmdbuild.war "$WAR_URL" && \
    mkdir cmdbuild && unzip cmdbuild.war -d cmdbuild

# ---- Stage 2: production image ----
FROM tomcat:jdk21-openjdk-bookworm

LABEL maintainer="marcovaschetto"
LABEL org.opencontainers.image.source="https://github.com/marcovaschetto/cmdbuild-docker"
LABEL org.opencontainers.image.description="Production-ready CMDBuild Ready2Use image"

RUN . /etc/os-release && echo "deb http://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" \
      > /etc/apt/sources.list.d/pgdg.list && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor \
      -o /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg

RUN apt-get update && \
    apt-get install -y libpq-dev \
    postgresql-client-17 && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

# Copy WAR contents (already unzipped)
COPY --from=downloader /war/cmdbuild /usr/local/tomcat/webapps/cmdbuild

RUN groupadd -g 1001 cmdbuild && \
    useradd -m -u 1001 -g cmdbuild -s /bin/bash cmdbuild

RUN chown -R cmdbuild:cmdbuild /usr/local/tomcat/

# Entrypoint to inject configuration
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

USER cmdbuild

ENTRYPOINT ["/entrypoint.sh"]