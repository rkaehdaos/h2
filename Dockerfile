FROM openjdk:jre-alpine

# Set Default version
ARG H2_VERSION="2.4.240"
ARG H2_DOWNLOAD_URL="https://github.com/h2database/h2database/releases/download/version-2.4.240/h2-2025-09-22.zip"


LABEL name ="GeunChang Ahn"
LABEL email = "rkaehdaos@gmail.com"
LABEL version = "version-${H2_VERSION}"
LABEL description = "${H2_VERSION} upgrade"

ENV DOWNLOAD ${H2_DOWNLOAD_URL}

ENV DATA_DIR /opt/h2-data

RUN apk add --no-cache wget

RUN mkdir -p ${DATA_DIR} \
    && wget -O h2.zip ${DOWNLOAD} \
    && unzip h2.zip -d /opt/ \
    && rm h2.zip

COPY h2.server.properties /root/.h2.server.properties

EXPOSE 81 1521

WORKDIR /opt/h2-data

CMD java -cp /opt/h2/bin/h2*.jar org.h2.tools.Server \
    -web -webAllowOthers -webPort 81 \
    -tcp -tcpAllowOthers -tcpPort 1521 \
    -baseDir ${DATA_DIR} ${H2_OPTIONS}