#!/bin/sh
CHROME_DRIVER_VERSION=2.29
CHROME_VERSION="google-chrome-stable"

ruby_versions="2.1 2.2 2.3 2.4 2 latest"
additional_os="alpine"

main() {
    [ -d Dockerfiles ] || mkdir Dockerfiles

    for os in "" $additional_os
    do
        for ruby_ver in $ruby_versions
        do
            if [ "$os" = "" ] ; then
                tag=$ruby_ver
            elif [ "$ruby_ver" = "latest" ] ; then
                tag=$os
            else
                tag=$ruby_ver-$os
            fi
            dump_dockerfile > Dockerfiles/Dockerfile.$tag
        done
    done
}

dump_dockerfile () {
    echo FROM ruby:$tag
    dump_package
    dump_nokogiri
    dump_phantomjs
}

dump_nokogiri () {
    echo RUN gem install nokogiri
    echo "RUN gem install nokogiri -v '~> 1.7.0'"
    echo "RUN gem install nokogiri -v '~> 1.6.0'"
}

dump_package () {
    if [ "$os" = "alpine" ] ; then
        # phantomjs: openssl curl
        echo RUN apk add --no-cache build-base libxml2-dev libxslt-dev unzip openssl curl
    else
        # phantomjs: libssl-dev libfontconfig1
        cat <<'END'
RUN apt-get update \
    && apt-get install -y ruby-dev zlib1g-dev liblzma-dev build-essential git unzip libfontconfig1 libssl-dev \
        libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 libxi6 \
        libxtst6 libcups2 libxss1 libxrandr2 libasound2 libatk1.0-0 libgtk-3-0 \
    && rm -rf /var/lib/apt/lists/*
END
    fi
}

dump_phantomjs() {
#============================================
# Google Chrome
#============================================
# can specify versions by CHROME_VERSION;
#  e.g. google-chrome-stable=53.0.2785.101-1
#       google-chrome-beta=53.0.2785.92-1
#       google-chrome-unstable=54.0.2840.14-1
#       latest (equivalent to google-chrome-stable)
#       google-chrome-beta  (pull latest beta)
#============================================
    cat <<END
#============================================
# Google Chrome
#============================================
ARG CHROME_VERSION="google-chrome-beta"
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \\
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \\
  && apt-get update -qqy \\
  && apt-get -qqy install \\
    \${CHROME_VERSION:-google-chrome-stable} \\
  && rm /etc/apt/sources.list.d/google-chrome.list \\
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#==================
# Chrome webdriver
#==================
ARG CHROME_DRIVER_VERSION=${CHROME_DRIVER_VERSION}
RUN wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/\$CHROME_DRIVER_VERSION/chromedriver_linux64.zip \\
  && rm -rf /opt/selenium/chromedriver \\
  && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \\
  && rm /tmp/chromedriver_linux64.zip \\
  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-\$CHROME_DRIVER_VERSION \\
  && chmod 755 /opt/selenium/chromedriver-\$CHROME_DRIVER_VERSION \\
  && ln -fs /opt/selenium/chromedriver-\$CHROME_DRIVER_VERSION /usr/bin/chromedriver
END
}

main "$@"

# vim: set et ts=4 sw=4 sts=4:
