FROM armdocker.rnd.ericsson.se/proj-orchestration-so/eric-oss-pf-base-image:2.21.0
ARG BUILD_VERSION_DROOLS=${BUILD_VERSION_DROOLS}
ARG POLICY_LOGS=/var/log/onap/policy/pdpd
ARG POLICY_INSTALL=/tmp/policy-install

ENV JAVA_HOME /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0
ENV BUILD_VERSION_DROOLS $BUILD_VERSION_DROOLS
ENV POLICY_HOME /opt/app/policy
ENV POLICY_INSTALL $POLICY_INSTALL
ENV POLICY_INSTALL_INIT $POLICY_INSTALL/config
ENV POLICY_LOGS $POLICY_LOGS
ENV POLICY_CONFIG $POLICY_HOME/config
ENV POLICY_LOGBACK $POLICY_CONFIG/logback.xml
ENV POLICY_DOCKER true
	
RUN zypper in -l -y java-1_8_0-openjdk-devel util-linux cron shadow mariadb-client unzip wget zip

# Create policy user and group
RUN groupadd policy && useradd -m policy -g policy

RUN mkdir -p $POLICY_CONFIG $POLICY_LOGS $POLICY_INSTALL_INIT && \
    chown -R policy:policy $POLICY_HOME $POLICY_LOGS $POLICY_INSTALL

WORKDIR $POLICY_INSTALL
COPY base.conf $POLICY_INSTALL_INIT
COPY docker-install.sh do-start.sh wait-for-port.sh ./

VOLUME [ "$POLICY_INSTALL_INIT" ]

RUN wget --no-check-certificate https://arm.seli.gic.ericsson.se/artifactory/docker-default/proj-sdd/test-drools-pdp/install-drools-1.5.3-SNAPSHOT-b.zip && \
    unzip -o install-drools-1.5.3-SNAPSHOT-b.zip && \
    rm install-drools-1.5.3-SNAPSHOT-b.zip && \
    chown -R policy:policy * && \
    chmod +x *.sh

# Added to fix SM-111272
RUN unzip -o policy-management-1.5.3-20191016.114714-3.zip -d temp && \
    rm policy-management-1.5.3-20191016.114714-3.zip && \
    zip -d temp/lib/log4j-1.2.17.jar org/apache/log4j/net/JMSAppender.class && \
    zip -d temp/lib/log4j-1.2.17.jar org/apache/log4j/net/SocketServer.class && \
    cd temp && \
    zip -r ../policy-management-1.5.3-20191016.114714-3.zip * && \
    rm -rf ../temp

RUN unzip -o feature-state-management-1.5.3-20191016.114846-3.zip -d temp && \
    rm feature-state-management-1.5.3-20191016.114846-3.zip && \
    zip -d temp/lib/dependencies/log4j-1.2.17.jar org/apache/log4j/net/JMSAppender.class && \
    zip -d temp/lib/dependencies/log4j-1.2.17.jar org/apache/log4j/net/SocketServer.class && \
    cd temp && \
    zip -r ../feature-state-management-1.5.3-20191016.114846-3.zip * && \
    rm -rf ../temp

EXPOSE 9696 6969

USER policy

CMD ["./do-start.sh"]
