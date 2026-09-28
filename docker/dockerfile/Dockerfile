FROM python:3.7-buster
SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Retrieve the target architecture to install the correct wkhtmltopdf package
ARG TARGETARCH

RUN export CRYPTOGRAPHY_DONT_BUILD_RUST=1

#INSTALL PACKAGES
RUN mkdir -p /usr/share/man/man1

# Fix Debian Buster EOL - use archive repositories
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        bzr \
        curl \
        default-jre \
        default-libmysqlclient-dev \
        font-manager \
        gfortran \
        git \
        libatlas-base-dev \
        libblas-dev \
        libcups2-dev \
        libevent-dev \
        libfreetype6-dev \
        liblapack-dev \
        libldap2-dev \
        libpq-dev \
        libsasl2-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        libxslt-dev \
        mercurial \
        subversion \
        unixodbc-dev \
        unzip \
        wget \
        zlib1g-dev \
        zip \
        && rm -rf /var/lib/apt/lists/*

#NODE JS
# Install Node.js and npm (using official binaries for Debian Buster)
RUN curl -fsSL https://nodejs.org/dist/v14.21.3/node-v14.21.3-linux-x64.tar.xz -o /tmp/node.tar.xz && \
    tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 && \
    rm /tmp/node.tar.xz && \
    ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Install npm packages globally
RUN npm install -g less less-plugin-clean-css

#WKHTML2PDF DEBIAN 10
# Install xfonts dependencies first
RUN apt-get update && \
    apt-get install -y --no-install-recommends xfonts-75dpi xfonts-base xfonts-encodings xfonts-utils && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends ./wkhtmltox_0.12.5-1.buster_amd64.deb && \
    rm -f wkhtmltox_0.12.5-1.buster_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

# install latest postgresql-client
RUN echo 'deb http://apt-archive.postgresql.org/pub/repos/apt/ buster-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
        && GNUPGHOME="$(mktemp -d)" \
        && export GNUPGHOME \
        && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
        && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
        && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
        && gpgconf --kill all \
        && rm -rf "$GNUPGHOME" \
        && apt-get update \
        && apt-get install --no-install-recommends -y postgresql-client \
        && rm -f /etc/apt/sources.list.d/pgdg.list \
        && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

RUN useradd odoo

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /opt/odoo \
    && chown odoo /opt/odoo \
    && chmod -R 777 /opt/odoo
VOLUME ["/opt/odoo"]

RUN pip install --upgrade pip
RUN pip3 install --upgrade wheel==0.40.0 setuptools==67.7.2
RUN pip3 install psycopg2-binary
COPY ./requirements.txt /opt/requirements/requirements.txt
RUN pip3 install -r /opt/requirements/requirements.txt

RUN mkdir -p /var/lib/odoo \
    && chown odoo /var/lib/odoo \
    && chmod -R 777 /var/lib/odoo

# Expose Odoo services
EXPOSE 8069 8071 8072

COPY ./docker/dockerfile/wait-for-psql.py /usr/local/bin/wait-for-psql.py

RUN ["chmod", "+x", "/usr/local/bin/wait-for-psql.py"]

RUN mkdir -p /home/odoo \
    && chown odoo:users /home/odoo \
    && chmod -R 777 /home/odoo

RUN mkdir -p /opt/temp \
    && chown odoo:users /opt/temp \
    && chmod -R 777 /opt/temp

# Set the default config file
ENV ODOO_RC /opt/odoo/server.conf

# Copy entrypoint script and Odoo configuration file
COPY ./docker/dockerfile/entrypoint.sh /

RUN ["chmod", "+x", "/entrypoint.sh"]

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]

CMD ["odoo"]