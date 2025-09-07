FROM iwhicr.azurecr.io/webmethods-edge-runtime:11.2.0 AS builder
#FROM ghcr.io/staillanibm/webmethods-edge-runtime:11.0.7 AS builder

ARG WPM_TOKEN
ARG GIT_TOKEN

RUN /opt/softwareag/wpm/bin/wpm.sh install -ws https://packages.webmethods.io -wr supported -j $WPM_TOKEN -d /opt/softwareag/IntegrationServer WmStreaming:latest
RUN mkdir -p /opt/softwareag/IntegrationServer/packages/WmStreaming/code/jars/static
RUN curl -o /opt/softwareag/IntegrationServer/packages/WmStreaming/code/jars/static/kafka-clients-3.9.0.jar "https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.9.0/kafka-clients-3.9.0.jar"
RUN curl -o /opt/softwareag/IntegrationServer/packages/WmStreaming/code/jars/static/lz4-java-1.8.0.jar "https://repo1.maven.org/maven2/org/lz4/lz4-java/1.8.0/lz4-java-1.8.0.jar"
RUN curl -o /opt/softwareag/IntegrationServer/packages/WmStreaming/code/jars/static/snappy-java-1.1.10.7.jar "https://repo1.maven.org/maven2/org/xerial/snappy/snappy-java/1.1.10.7/snappy-java-1.1.10.7.jar"


RUN /opt/softwareag/wpm/bin/wpm.sh install -ws https://packages.webmethods.io -wr licensed -j $WPM_TOKEN -d /opt/softwareag/IntegrationServer WmJDBCAdapter:latest
RUN curl -o /opt/softwareag/IntegrationServer/packages/WmJDBCAdapter/code/jars/postgresql-42.7.4.jar "https://jdbc.postgresql.org/download/postgresql-42.7.4.jar"
RUN /opt/softwareag/wpm/bin/wpm.sh install -u staillanibm -p $GIT_TOKEN -r https://github.com/staillanibm -d /opt/softwareag/IntegrationServer sttFramework
RUN /opt/softwareag/IntegrationServer/bin/jcode.sh makeall sttFramework

ADD --chown=1724:0 . /opt/softwareag/IntegrationServer/packages/sttContactManagement

USER 0
RUN chgrp -R 0 /opt/softwareag && chmod -R g=u /opt/softwareag


FROM iwhicr.azurecr.io/webmethods-edge-runtime:11.2.0
#FROM ghcr.io/staillanibm/webmethods-edge-runtime:11.0.7

USER 1724

COPY --from=builder /opt/softwareag/IntegrationServer /opt/softwareag/IntegrationServer
