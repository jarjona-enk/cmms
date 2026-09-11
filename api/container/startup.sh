#!/bin/sh
#
# Container entrypoint, modelled on ../budget/container/startup.sh.
#
# Two things happen here that a plain `java -jar` CMD cannot do:
#
#  1. sshd is started in the background on 2222, which is what the Azure
#     portal's SSH console and `az webapp ssh` attach to. Without a listener
#     on that exact port the blade just times out.
#
#  2. The app runs in the foreground with its console output teed to
#     LOG_FILE. stdout is preserved, so `az webapp log tail` and Log Analytics
#     keep working exactly as before; the file is what you read once you are
#     inside the container over SSH, where there is no docker log to look at.
#
# Unlike budget there is no nginx: one fat jar serves the REST API and the SPA
# on 8080, which is the site container's target port.

LOG_FILE="${LOG_FILE:-/home/cmms/atlas.log}"
mkdir -p "$(dirname "${LOG_FILE}")"

echo "Starting SSHD..."
/usr/sbin/sshd -D &

echo "Starting Atlas CMMS..."
java --add-opens=java.base/java.lang=ALL-UNNAMED -jar /app/my-spring-boot-app.jar 2>&1 | tee -a "${LOG_FILE}"
