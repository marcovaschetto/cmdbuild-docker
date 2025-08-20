# ---- Stage 1: download ----
FROM alpine:3.20 AS downloader

ARG WAR_URL=https://sourceforge.net/projects/openmaint/files/2.4/openmaint-2.4-4.0.4.war/download

WORKDIR /war
RUN apk add --no-cache curl unzip && \
    curl -L -o openmaint.war "$WAR_URL" && \
    mkdir openmaint && unzip openmaint.war -d openmaint

# ---- Stage 2: production image ----
#FROM tomcat:10-jdk17
FROM tomcat:jdk21-openjdk-bookworm

LABEL maintainer="marcovaschetto"
LABEL org.opencontainers.image.source="https://github.com/marcovaschetto/cmdbuild-docker"
LABEL org.opencontainers.image.description="Production-ready openMAINT image"

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

# Deploy application
COPY --from=downloader /war/openmaint /usr/local/tomcat/webapps/openmaint

RUN groupadd -g 1001 openmaint && \
    useradd -m -u 1001 -g openmaint -s /bin/bash openmaint

RUN chown -R openmaint:openmaint /usr/local/tomcat/

# Runtime setup
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

USER openmaint

ENTRYPOINT ["/entrypoint.sh"]
