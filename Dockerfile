FROM maven:3.8.5-openjdk-17-slim as builder
COPY . .
RUN ...
# Once you have compiled your app and get the jar file you need to send it to scratch stage.

FROM pedroarrieta/alpine-openjdk-17:latest as customjre
RUN apk upgrade --available
RUN apk add --no-cache ca-certificates java-cacerts openssl binutils
RUN jlink \
     --module-path /opt/java/jmods \
     --compress=2 \
     --add-modules jdk.management.agent,java.base,java.logging,java.xml,jdk.unsupported,java.sql,java.naming,java.desktop,java.management,java.security.jgss,java.instrument,java.scripting,jdk.crypto.ec,java.rmi,jdk.httpserver,jdk.security.auth \
     --strip-debug \
     --no-header-files \
     --no-man-pages \
     --ignore-signing-information \
     --output /lib/runtime \
     && rm -rf /lib/apk \
     && rm -rf /lib/runtime/legal \
     && rm -rf /lib/runtime/security \
     && strip --strip-unneeded /lib/runtime/lib/server/libjvm.so \
     && cd /lib/runtime/lib; for i in $(ls /lib/runtime/lib/*.so); do strip --strip-unneeded $i; done \
     && rm -rf /tmp/*

FROM scratch
COPY --from=customjre /lib /lib
COPY --from=customjre /tmp /tmp
COPY --from=builder app.jar app.jar
CMD ["/lib/runtime/bin/java", "-jar","/app.jar"]