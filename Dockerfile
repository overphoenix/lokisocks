FROM debian:bullseye

RUN apt-get update 

# Lokinet
RUN apt install --no-install-recommends --no-install-suggests -y ca-certificates curl
RUN curl -so /etc/apt/trusted.gpg.d/oxen.gpg https://deb.oxen.io/pub.gpg
RUN echo "deb https://deb.oxen.io bullseye main" |  tee /etc/apt/sources.list.d/oxen.list
RUN apt update
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections
RUN apt install lokinet -y

RUN apt install sudo --no-install-recommends libcap2-bin -y
RUN mkdir /var/lib/lokinet/conf.d
COPY ./data/lokinet.ini /var/lib/lokinet/conf.d/lokinet.ini

# Dante
ENV DANTE_VER=1.4.3
ENV DANTE_URL=https://www.inet.no/dante/files/dante-$DANTE_VER.tar.gz
ENV DANTE_SHA=418a065fe1a4b8ace8fbf77c2da269a98f376e7115902e76cda7e741e4846a5d
ENV DANTE_FILE=dante.tar.gz
ENV DANTE_TEMP=dante
ENV DANTE_DEPS="build-essential"

RUN set -xe \
    && apt-get install -y $DANTE_DEPS \
    && mkdir $DANTE_TEMP \
    && cd $DANTE_TEMP \
    && curl -sSL $DANTE_URL -o $DANTE_FILE \
    && echo "$DANTE_SHA *$DANTE_FILE" | shasum -c \
    && tar xzf $DANTE_FILE --strip 1 \
    && ./configure \
    && make install \
    && cd .. \
    && rm -rf $DANTE_TEMP \
    && apt-get purge -y --auto-remove $DANTE_DEPS \
    && rm -rf /var/lib/apt/lists/*

COPY ./data/sockd.conf /etc/dante/sockd.conf

ENV CFGFILE=/etc/dante/sockd.conf
ENV PIDFILE=/run/sockd.pid
ENV WORKERS=12

EXPOSE 1080

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh
ENTRYPOINT ["/sbin/entrypoint.sh"]
