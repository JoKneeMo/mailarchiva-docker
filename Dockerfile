FROM tomcat:jre8 as builder

LABEL maintainer="JoKneeMo <https://github.com/JoKneeMo>"
LABEL version="8.11.18"

ARG MAILARCHIVA_VERSION=8.11.18
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /build

RUN apt update && apt install -y \
    fontconfig-config \
    unzip

RUN curl -so javax2jakarta https://dlcdn.apache.org/tomcat/jakartaee-migration/v1.0.6/binaries/jakartaee-migration-1.0.6-shaded.jar

RUN curl -so mailarchiva.war https://stimulussoft.b-cdn.net/mailarchiva_v${MAILARCHIVA_VERSION}.war

RUN java -jar javax2jakarta mailarchiva.war mailarchiva-jakarta.war


FROM tomcat:jre8 as runtime

COPY --from=builder /build/mailarchiva-jakarta.war .

RUN apt update && apt install -y \
    fontconfig-config \
    unzip \
    && apt autoremove --purge -y \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && unzip mailarchiva-jakarta.war -d $CATALINA_HOME/webapps/ROOT \
    && sed -i 's|Connector port=\"8080\" protocol=\"HTTP\/1.1\"|Connector port=\"8080\" protocol=\"org.apache.coyote.http11.Http11NioProtocol\" URIEncoding=\"UTF-8\" compression=\"on\" noCompressionUserAgents=\"gozilla, traviata\" compressableMimeType=\"text/html,text/xml,text/css,text/plain,application/javascript,application/json\" enableLookups=\"false\"  disableUploadTimeout=\"true\" address=\"0.0.0.0\"|g' $CATALINA_HOME/conf/server.xml \
    && rm -f mailarchiva-jakarta.war

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
