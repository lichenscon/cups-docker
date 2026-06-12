FROM debian:stable-slim

# ENV variables
ENV DEBIAN_FRONTEND noninteractive
ENV TZ "America/New_York"
ENV CUPSADMIN admin
ENV CUPSPASSWORD password


LABEL org.opencontainers.image.source="https://github.com/anujdatar/cups-docker"
LABEL org.opencontainers.image.description="CUPS Printer Server"
LABEL org.opencontainers.image.author="Anuj Datar <anuj.datar@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/anujdatar/cups-docker/blob/main/README.md"
LABEL org.opencontainers.image.licenses=MIT


# Install dependencies
RUN apt-get update -qq  && apt-get upgrade -qqy \
    && apt-get install -qqy \
    apt-utils \
    usbutils \
    cups \
    cups-filters \
    avahi-daemon \
    wget \
    binutils-common \
    && wget https://gdlp01.c-wss.com/gds/2/0100007602/49/linux-UFRII-drv-v630-m17n-07.tar.gz \
    && mkdir /tmp/canon /tmp/canon-extract && tar -xzvf linux-UFRII-drv-v630-m17n-07.tar.gz -C /tmp/canon \
    && apt-get install -y cups cups-bsd libcups2t64 libcupsimage2t64 ghostscript libjpeg62-turbo libgcrypt20 libgtk-3-0t64 libjbig0 zlib1g lsb-release \
    && dpkg -i -G --force-overwrite /tmp/canon/linux-UFRII-drv-v630-m17n/x64/Debian/cnrdrvcups-ufr2-uk_6.30-1.07_amd64.deb \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && wget https://download.brother.com/welcome/dlfp002171/ql550cupswrapper-1.0.1-0.i386.deb -O /tmp/ql550cupswrapper-1.0.1-0.i386.deb \
    && wget https://download.brother.com/welcome/dlfp002168/ql550lpr-1.0.1-0.i386.deb -O /tmp/ql550lpr-1.0.1-0.i386.deb \
    && mkdir -p /var/spool/lpd/ \
    && dpkg -i --force-all /tmp/ql550lpr-1.0.1-0.i386.deb \
    && dpkg -i --force-all /tmp/ql550cupswrapper-1.0.1-0.i386.deb \
    && rm -rf /tmp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm /linux-UFRII-drv-v630-m17n-07.tar.gz 

EXPOSE 631
EXPOSE 5353/udp

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf

# back up cups configs in case used does not add their own
RUN cp -rp /etc/cups /etc/cups-bak
VOLUME [ "/etc/cups" ]

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
