FROM adoptopenjdk/openjdk11:debian
ARG RUNDECK_VERSION=
ARG RUNDECK_CLI_VERSION=1.3.4

ENV SERVER_URL=https://localhost:4443 \
    RUNDECK_STORAGE_PROVIDER=file \
    RUNDECK_PROJECT_STORAGE_TYPE=file \
    LOGIN_MODULE=RDpropertyfilelogin \
    JAAS_CONF_FILE=jaas-loginmodule.conf \
    KEYSTORE_PASS=adminadmin \
    TRUSTSTORE_PASS=adminadmin \
    SERVER_DOWNLOAD_URL="http://dl.bintray.com/rundeck/rundeck-deb/rundeck_${RUNDECK_VERSION}_all.deb" \
    CLI_DOWNLOAD_URL="http://dl.bintray.com/rundeck/rundeck-deb/rundeck-cli_${RUNDECK_CLI_VERSION}-1_all.deb"    

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get -y install --no-install-recommends bash ca-certificates-java supervisor procps sudo ca-certificates  \
     openssh-client software-properties-common curl uuid-runtime debconf-utils \
    && echo "downloading rundeck server from: ${SERVER_DOWNLOAD_URL}" \
    && curl -fLo /tmp/rundeck-server.deb ${SERVER_DOWNLOAD_URL} \
    && echo "downloading rundeck cli from: ${CLI_DOWNLOAD_URL}"  \
    && curl -fLo /tmp/rundeck-cli.deb ${CLI_DOWNLOAD_URL} \
    && dpkg -i /tmp/rundeck-server.deb \
    && rm /tmp/rundeck-server.deb \
    && dpkg -i /tmp/rundeck-cli.deb \
    && rm /tmp/rundeck-cli.deb \
    && mkdir -p /var/lib/rundeck/.ssh \
    && chown rundeck:rundeck /var/lib/rundeck/.ssh \
    && sed -i "s/export RDECK_JVM=\"/export RDECK_JVM=\"\${RDECK_JVM} /" /etc/rundeck/profile \

    && rm -rf /tmp/* /var/tmp/* \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -fr /tmp/*.deb \
    && rm -rf /usr/share/man/?? \
    && rm -rf /usr/share/man/??_*


COPY rundeck-defaults /opt/rundeck-defaults
COPY supervisor /etc/supervisor
COPY bin/docker-entrypoint.sh /
COPY bin/custom-scripts.sh /
COPY bin/rundeck-wrapper.sh /usr/local/bin/rundeck-wrapper
COPY bin/wait-for-it.sh /usr/local/bin/wait-for-it

RUN mkdir -p /var/log/supervisor /opt/supervisor /docker-entrypoint.d/ && \
    chmod u+x /usr/local/bin/rundeck-wrapper /docker-entrypoint.sh /custom-scripts.sh

EXPOSE 4440 4443

## TODOL should we remove /var/lib/rundeck ?
VOLUME  ["/etc/rundeck", "/var/rundeck", "/var/lib/rundeck", "/var/log/rundeck", "/opt/rundeck-plugins", "/var/lib/rundeck/logs", "/var/lib/rundeck/var/storage"]

ENTRYPOINT ["/docker-entrypoint.sh"]
