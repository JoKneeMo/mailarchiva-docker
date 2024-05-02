FROM tomcat:10-jre21 as builder

LABEL maintainer="JoKneeMo <https://github.com/JoKneeMo>"
LABEL version="9.0.21"

ARG MAILARCHIVA_VERSION=9.0.21
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /build

RUN apt update && apt install -y \
    fontconfig-config \
    unzip

RUN curl -so mailarchiva.war https://stimulussoft.b-cdn.net/mailarchiva-${MAILARCHIVA_VERSION}.war

RUN unzip mailarchiva.war -d /usr/local/tomcat/webapps/ROOT

RUN sed -i 's|Connector port=\"8080\" protocol=\"HTTP\/1.1\"|Connector port=\"8080\" protocol=\"org.apache.coyote.http11.Http11NioProtocol\" URIEncoding=\"UTF-8\" compression=\"on\" noCompressionUserAgents=\"gozilla, traviata\" compressableMimeType=\"text/html,text/xml,text/css,text/plain,application/javascript,application/json\" enableLookups=\"false\"  disableUploadTimeout=\"true\" address=\"0.0.0.0\"|g' $CATALINA_HOME/conf/server.xml


FROM tomcat:10-jre21 as runtime

RUN apt update && apt install -y fontconfig-config \
    && apt autoremove --purge -y && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /usr/local/tomcat/webapps/ROOT/ /usr/local/tomcat/webapps/ROOT/
COPY --from=builder /usr/local/tomcat/conf/server.xml /usr/local/tomcat/conf/server.xml

# Webserver
EXPOSE 8080
# SMTP
EXPOSE 8091
# Milter
EXPOSE 8092
# Tomcat AJP
EXPOSE 8009
# Tomcat Shutdown
EXPOSE 8010

CMD ["catalina.sh", "run"]
