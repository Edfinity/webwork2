# NOTE --> build this with docker-build.sh and see instructions therein for
# checking out pg and MathJax dependencies ^_^

FROM ubuntu:22.04

ENV WEBWORK_URL=/webwork2 \
    WEBWORK_ROOT_URL=http://localhost \
    WEBWORK_SMTP_SERVER=localhost \
    WEBWORK_SMTP_SENDER=webwork@example.com \
    WEBWORK_TIMEZONE=America/New_York \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    # temporary state file location. This might be changed to /run in Wheezy+1 \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    # Only /var/log/apache2 is handled by /etc/logrotate.d/apache2.
    APACHE_LOG_DIR=/var/log/apache2 \
    APP_ROOT=/opt/webwork \
    DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    DEV=0

WORKDIR $APP_ROOT

ENV WEBWORK_ROOT=$APP_ROOT/webwork2 \
    PG_ROOT=$APP_ROOT/pg \
    PATH=$PATH:$APP_ROOT/webwork2/bin

# ==================================================================
# Strip docs/man/info pages from this image. Honored by dpkg for any package
# installed AFTER this file is written, so it must precede the apt-get
# install below. Keep copyright files for license-compliance.
RUN printf 'path-exclude /usr/share/doc/*\npath-include /usr/share/doc/*/copyright\npath-exclude /usr/share/man/*\npath-exclude /usr/share/info/*\n' \
      > /etc/dpkg/dpkg.cfg.d/01_nodoc \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
	apache2 \
	curl \
	dvipng \
	gcc \
	libapache2-request-perl \
	libcrypt-ssleay-perl \
	libdatetime-perl \
	libdancer-perl \
	libdancer-plugin-database-perl \
	libdbd-mysql-perl \
	libemail-address-xs-perl \
	libexception-class-perl \
	libextutils-xsbuilder-perl \
	libfile-find-rule-perl-perl \
	libgd-perl \
	libhtml-scrubber-perl \
	libjson-perl \
	liblocale-maketext-lexicon-perl \
	libmail-sender-perl \
	libmime-tools-perl \
	libnet-ip-perl \
	libnet-ldap-perl \
	libnet-oauth-perl \
	libossp-uuid-perl \
	libpadwalker-perl \
	libpath-class-perl \
	libphp-serialization-perl \
	libxml-simple-perl \
	libsoap-lite-perl \
	libsql-abstract-perl \
	libstring-shellquote-perl \
	libtemplate-perl \
	libtext-csv-perl \
	libtimedate-perl \
	libuuid-tiny-perl \
	libxml-parser-perl \
	libxml-writer-perl \
	libxmlrpc-lite-perl \
	libapache2-reload-perl \
	cpanminus \
	libxml-parser-easytree-perl \
	libiterator-perl \
	libiterator-util-perl \
	libpod-wsdl-perl \
	libtest-xml-perl \
	libmodule-build-perl \
	libxml-semanticdiff-perl \
	libxml-xpath-perl \
	libpath-tiny-perl \
	libarray-utils-perl \
	libhtml-template-perl \
	libtest-pod-perl \
	libemail-sender-perl \
	libmail-sender-perl \
	libmodule-pluggable-perl \
	libemail-date-format-perl \
	libcapture-tiny-perl \
	libthrowable-perl \
	libdata-dump-perl \
	libfile-sharedir-install-perl \
	libclass-tiny-perl \
	libtest-requires-perl \
	libtest-mockobject-perl \
	libtest-warn-perl \
  libstatistics-r-io-perl \
	libsub-uplevel-perl \
	libtest-exception-perl \
	libuniversal-can-perl \
	libuniversal-isa-perl \
	libtest-fatal-perl \
	libjson-xs-perl \
	libmoox-options-perl \
	make \
	netpbm \
	preview-latex-style \
	texlive \
	texlive-latex-extra \
	texlive-plain-generic \
	texlive-xetex \
	texlive-latex-recommended \
	texlive-lang-other \
	texlive-lang-arabic \
	libc6-dev \
	git \
	mysql-client \
	tzdata \
	apt-utils \
	locales \
	debconf-utils \
	ssl-cert \
	ca-certificates \
	culmus \
	fonts-linuxlibertine \
	lmodern \
	zip \
	jq \
  python3 \
  python-is-python3 \
  python3-pip \
  openssl \
  libmath-cephes-perl \
  texlive-fonts-recommended \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* /tmp/*

RUN cpanm install Statistics::R::IO \
  && rm -fr ./cpanm /root/.cpanm

# ==================================================================
RUN mkdir -p $APP_ROOT/courses $APP_ROOT/libraries $APP_ROOT/libraries/webwork-open-problem-library /www/www/html

# see docker-build.sh for running, this should be run from a parent directory with pg and MathJax checked out
COPY . ./
# ==================================================================

RUN echo "PATH=$PATH:$APP_ROOT/webwork2/bin" >> /root/.bashrc \
    && cd $APP_ROOT/pg/lib/chromatic && gcc color.c -o color  \
    && cd $APP_ROOT/webwork2/ \
      && chown www-data DATA ../courses  htdocs/applets logs tmp $APP_ROOT/pg/lib/chromatic \
      && chmod -R u+w DATA ../courses  htdocs/applets logs tmp $APP_ROOT/pg/lib/chromatic   \
    && echo "en_US ISO-8859-1\nen_US.UTF-8 UTF-8" > /etc/locale.gen \
      && /usr/sbin/locale-gen \
      && find /usr/share/locale -mindepth 1 -maxdepth 1 -type d \
           ! -name 'en' ! -name 'en_US' -exec rm -rf {} + \
      && echo "locales locales/default_environment_locale select en_US.UTF-8\ndebconf debconf/frontend select Noninteractive" > /tmp/preseed.txt \
      && debconf-set-selections /tmp/preseed.txt \
    && rm /etc/localtime /etc/timezone && echo "Etc/UTC" > /etc/timezone \
      &&   dpkg-reconfigure -f noninteractive tzdata

ENV SSL=0 \
    PAPERSIZE=letter \
    SYSTEM_TIMEZONE=UTC \
    ADD_LOCALES=0 \
    ADD_APT_PACKAGES=0

COPY ./webwork2/docker-config/ssl/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf

RUN cd $APP_ROOT/webwork2/conf \
    && cp webwork.apache2.4-config.dist webwork.apache2.4-config \
    && cp $APP_ROOT/webwork2/conf/webwork.apache2.4-config /etc/apache2/conf-enabled/webwork.conf \
    && a2dismod mpm_event \
    && a2enmod mpm_prefork \
    && sed -i -e 's/Timeout 300/Timeout 8/' /etc/apache2/apache2.conf \
    && sed -i -e 's/TIMEOUT = 10;/TIMEOUT = $ENV{"WEBWORK_TIMEOUT"} \/\/ 7;/' /opt/webwork/webwork2/lib/WeBWorK/Constants.pm \
    && sed -i -e 's/MaxRequestWorkers     150/MaxRequestWorkers     20/' \
	  -e 's/MaxConnectionsPerChild   0/MaxConnectionsPerChild   100/' \
	  /etc/apache2/mods-available/mpm_prefork.conf \
    && cp $APP_ROOT/webwork2/htdocs/favicon.ico /var/www/html \
    && mkdir -p $APACHE_RUN_DIR $APACHE_LOCK_DIR $APACHE_LOG_DIR \
    && mkdir /etc/ssl/local  \
    && a2enmod rewrite \
    && sed -i -e 's/^<Perl>$/\
	PerlPassEnv WEBWORK_URL\n\
	PerlPassEnv WEBWORK_ROOT_URL\n\
	PerlPassEnv WEBWORK_DB_DSN\n\
	PerlPassEnv WEBWORK_DB_USER\n\
	PerlPassEnv WEBWORK_DB_PASSWORD\n\
	PerlPassEnv WEBWORK_SMTP_SERVER\n\
	PerlPassEnv WEBWORK_SMTP_SENDER\n\
	PerlPassEnv WEBWORK_TIMEZONE\n\
	\n<Perl>/' /etc/apache2/conf-enabled/webwork.conf

ENTRYPOINT ["docker-entrypoint.sh"]

# ================================================
EXPOSE 80
CMD ["apache2", "-DFOREGROUND"]

