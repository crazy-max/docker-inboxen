FROM alpine:3.9

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL maintainer="CrazyMax" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="inboxen" \
  org.label-schema.description="Inboxen" \
  org.label-schema.version=$VERSION \
  org.label-schema.url="https://github.com/crazy-max/docker-inboxen" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/crazy-max/docker-inboxen" \
  org.label-schema.vendor="CrazyMax" \
  org.label-schema.schema-version="1.0"

ENV INBOXEN_VERSION="deploy-20190110" \
  SHA1_COMMIT="2998ce0987a352d62cc1e2fd4e34215e9c3e85ff" \
  DJANGO_SETTINGS_MODULE="inboxen.settings" \
  SALMON_SETTINGS_MODULE="inboxen.router.config.settings"

RUN apk --update --no-cache add \
    gettext \
    libressl \
    libjpeg-turbo-dev \
    libstdc++ \
    libxml2-dev \
    libxslt-dev \
    linux-headers \
    musl-dev \
    nginx \
    postgresql-client \
    postgresql-dev \
    python3 \
    python3-dev \
    py3-virtualenv \
    shadow \
    supervisor \
    tzdata \
    zlib-dev \
  && apk --update --no-cache add -t build-dependencies \
    build-base \
    git \
    nodejs \
    npm \
    ruby \
    ruby-dev \
  && mkdir -p /data/logs /var/log/supervisord \
  && addgroup -g 1000 inboxen \
  && adduser -u 1000 -G inboxen -h /app -s /bin/sh -D inboxen \
  && passwd -l inboxen \
  && usermod -a -G inboxen nginx \
  && pip3 install --upgrade pip \
  && gem install sass -v '< 3.5.0' --no-ri --no-rdoc \
  && git clone https://github.com/Inboxen/Inboxen.git app \
  && cd app \
  && git reset --hard $SHA1_COMMIT \
  && ln -sf /data/logs /app/logs \
  && mkdir run \
  && virtualenv env \
  && . env/bin/activate \
  && pip3 install --no-cache-dir -r requirements.txt \
  && pip3 install --no-cache-dir -r requirements-dev.txt \
  && pip3 install --no-cache-dir uwsgi \
  && npm install \
  && printf "[general]\nsecret_key=temp\nstatic_root=/app/static" > settings.ini \
  && sed -i -e "s/SALMON_SERVER.*/SALMON_SERVER = {\"host\": \"0.0.0.0\", \"port\": 8823, \"type\": \"smtp\"}/" inboxen/settings.py \
  && python3 ./manage.py compilemessages \
  && python3 ./manage.py collectstatic \
  && chown -R inboxen. /app /data \
  && apk del build-dependencies \
  && rm -rf /app/.git /tmp/* /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
COPY assets /

RUN chmod a+x /entrypoint.sh

EXPOSE 8080 8823
WORKDIR /app
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]
