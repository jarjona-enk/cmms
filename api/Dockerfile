# ── Source bundle stage ───────────────────────────────────────────────
# AGPLv3 §13: capture the complete corresponding source of the running
# version (whole repository, minus VCS metadata and build artifacts/deps).
# Requires the build context to be the REPOSITORY ROOT, e.g.:
#   docker build -f api/Dockerfile -t intelloop/atlas-cmms-backend .
# (docker-compose is configured to do this automatically.)
FROM alpine:3.20 AS source
WORKDIR /repo
COPY . .
RUN apk add --no-cache zip \
 && zip -r -q /atlas-cmms-source.zip . \
      -x '.git/*' \
      -x '*/node_modules/*' \
      -x 'api/target/*' \
      -x '*/build/*' \
      -x '*/dist/*' \
      -x '*/.gradle/*' \
      -x '*/.idea/*' \
      -x '*/.terraform/*' \
      -x '*.tfstate*' \
      -x '*.env' \
      -x '.env' \
 && mkdir -p /out \
 && mv /atlas-cmms-source.zip /out/atlas-cmms-source.zip

# ── Build Stage ───────────────────────────────────────────────────────
# Builds the whole reactor from the repo root: the frontend (frontend-maven-plugin
# downloads a local Node), deploys the SPA into the api module's static resources,
# then builds the fat jar. Build context must be the repository root.
FROM maven:3.9.3-eclipse-temurin-17 AS build
WORKDIR /app
COPY . .
# Embed the source bundle so the running app can serve it for download
# (see SourceCodeController -> GET /source-code/download).
COPY --from=source /out/atlas-cmms-source.zip api/src/main/resources/static/source/atlas-cmms-source.zip

# These three are compiled INTO the SPA bundle by Create React App, so they
# cannot be changed at container runtime - the resulting image is specific to
# the environment named by FRONTEND_API_URL. Defaults match api/pom.xml and
# suit a local build; CI overrides them per environment (see REQUIREMENTS.md).
ARG FRONTEND_API_URL=http://localhost:8080
ARG FRONTEND_ENABLE_SSO=true
ARG FRONTEND_OAUTH2_PROVIDER=microsoft

RUN mvn -f pom.xml -DskipTests \
      -Dfrontend.api.url="${FRONTEND_API_URL}" \
      -Dfrontend.enable.sso="${FRONTEND_ENABLE_SSO}" \
      -Dfrontend.oauth2.provider="${FRONTEND_OAUTH2_PROVIDER}" \
      clean package

# ── Runtime Stage ─────────────────────────────────────────────────────
# Ubuntu-based (noble) rather than the upstream amazoncorretto:17-alpine, so
# the SSH setup below is the same apt/openssh-server setup the budget app uses
# (../budget/Dockerfile). Alpine's musl build of openssh does not behave the
# same way with App Service's SSH console. Java 17 regardless: newer JDKs break
# Lombok in this codebase.
FROM eclipse-temurin:17-jre-noble

USER root

# Set the working directory in the container
WORKDIR /app

# ── SSH server, matching ../budget/Dockerfile ─────────────────────────
# This is what lets the Azure portal's "SSH" blade (and `az webapp ssh`) open a
# shell inside the running container to read the log file. App Service connects
# to port 2222 as root with the password Docker! - both are fixed by the
# platform, not choices, and neither is reachable from the internet: the only
# route in is the authenticated SCM tunnel.
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get install -y --no-install-recommends \
      openssh-server sudo vim less passwd tcpdump net-tools telnet wget curl && \
    rm -rf /var/lib/apt/lists/*

# Directory for the SSH daemon, then the host keys.
RUN mkdir /var/run/sshd && chmod 0755 /var/run/sshd
RUN ssh-keygen -A

# Non-root user for day-to-day poking around, as on budget.
RUN useradd -ms /bin/bash cmms && \
    echo "cmms:cmm5" | chpasswd && \
    echo "cmms ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Required by App Service's SSH console.
RUN echo "root:Docker!" | chpasswd

COPY api/container/sshd_config /etc/ssh/

# ── Application ───────────────────────────────────────────────────────
# LOG_FILE is where startup.sh tees the console output. /home is not persisted
# unless WEBSITES_ENABLE_APP_SERVICE_STORAGE is true, so by default this file
# starts empty on every restart - which is usually what you want when reading
# it over SSH.
ENV LOG_FILE=/home/cmms/atlas.log
RUN mkdir -p /home/cmms && chown cmms:cmms /home/cmms

# Copy the compiled Spring Boot application JAR file into the container at /app
COPY --from=build /app/api/target/*.jar my-spring-boot-app.jar
COPY api/container/startup.sh startup.sh
RUN chmod +x startup.sh

# 8080 is the app and the site container's target port; 2222 is sshd.
EXPOSE 8080 2222

# Specify the command to run on container startup
ENTRYPOINT ["sh", "/app/startup.sh"]
