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
RUN mvn -f pom.xml -DskipTests clean package

# ── Runtime Stage ─────────────────────────────────────────────────────
FROM amazoncorretto:17-alpine

# Set the working directory in the container
WORKDIR /app

# Copy the compiled Spring Boot application JAR file into the container at /app
COPY --from=build /app/api/target/*.jar my-spring-boot-app.jar

# Expose the port that the Spring Boot application will run on
EXPOSE 8080

# Specify the command to run on container startup
CMD ["java", "--add-opens=java.base/java.lang=ALL-UNNAMED", "-jar", "/app/my-spring-boot-app.jar"]
