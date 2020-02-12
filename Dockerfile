FROM alpine:3.8

LABEL Mark Moloney <m4rkmo@gmail.com>

ENV APP_DIR=/srv/app
ENV GIT_BRANCH 0.0.14a
ENV GIT_URL https://github.com/markmo/datapusher.git
ENV JOB_CONFIG ${APP_DIR}/datapusher_settings.py

WORKDIR ${APP_DIR}

RUN apk add --no-cache python \
    py-pip \
    py-gunicorn \
    libmagic \
    libxslt

# Temporary packages to build CKAN requirements
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    git \
    musl-dev \
    python-dev \
    libffi-dev \
    openssl-dev \
    libxml2-dev \
    libxslt-dev && \
    # Fetch datapusher and install
    mkdir ${APP_DIR}/src && cd ${APP_DIR}/src && \
    git clone -b ${GIT_BRANCH} --depth=1 --single-branch ${GIT_URL} && \
    cd datapusher && \
    python setup.py install && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    # Remove temporary packages and files
    apk del .build-deps && \
    rm -rf ${APP_DIR}/src

COPY deployment/datapusher_settings.py ${APP_DIR}/datapusher_settings.py
COPY wsgi.py ${APP_DIR}/wsgi.py

EXPOSE 8800

CMD ["gunicorn", "-b=0.0.0.0", "--log-file=-", "--log-level=debug", "--timeout=60", "wsgi:app"]
