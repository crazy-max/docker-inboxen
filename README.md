<p align="center"><a href="https://github.com/crazy-max/docker-inboxen" target="_blank"><img height="128"src="https://raw.githubusercontent.com/crazy-max/docker-inboxen/master/.res/docker-inboxen.jpg"></a></p>

<p align="center">
  <a href="https://microbadger.com/images/crazymax/inboxen"><img src="https://images.microbadger.com/badges/version/crazymax/inboxen.svg?style=flat-square" alt="Version"></a>
  <a href="https://travis-ci.com/crazy-max/docker-inboxen"><img src="https://img.shields.io/travis/com/crazy-max/docker-inboxen/master.svg?style=flat-square" alt="Build Status"></a>
  <a href="https://hub.docker.com/r/crazymax/inboxen/"><img src="https://img.shields.io/docker/stars/crazymax/inboxen.svg?style=flat-square" alt="Docker Stars"></a>
  <a href="https://hub.docker.com/r/crazymax/inboxen/"><img src="https://img.shields.io/docker/pulls/crazymax/inboxen.svg?style=flat-square" alt="Docker Pulls"></a>
  <a href="https://quay.io/repository/crazymax/inboxen"><img src="https://quay.io/repository/crazymax/inboxen/status?style=flat-square" alt="Docker Repository on Quay"></a>
  <a href="https://www.codacy.com/app/crazy-max/docker-inboxen"><img src="https://img.shields.io/codacy/grade/6e477437dfdf48f3a7133d7637d92175.svg?style=flat-square" alt="Code Quality"></a>
  <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=CF9YNTZWJCW3L"><img src="https://img.shields.io/badge/donate-paypal-7057ff.svg?style=flat-square" alt="Donate Paypal"></a>
</p>

## About

🐳 [Inboxen](https://inboxen.org/) image based on Alpine Linux.<br />
If you are interested, [check out](https://hub.docker.com/r/crazymax/) my other 🐳 Docker images!

## Features

### Included

* Alpine Linux 3.8
* Inboxen [WSGI daemon](https://github.com/Inboxen/Inboxen/blob/master/inboxen/wsgi.py) served through [uWSGI](https://uwsgi-docs.readthedocs.io) and Nginx
* Nginx serves /static/ from `app/static` content through [Django collectstatic](https://docs.djangoproject.com/en/1.11/ref/contrib/staticfiles/#collectstatic)
* [Salmon](https://salmon-mail.readthedocs.io) mail server available through port `8823`
* [Celery](http://docs.celeryproject.org/en/latest/index.html) served as a distributed task queue for RabbitMQ
* Automatic DB migration

### From docker-compose

* [Traefik](https://github.com/containous/traefik-library-image) as reverse proxy and creation/renewal of Let's Encrypt certificates
* [PostgreSQL](https://github.com/docker-library/postgres) image as database instance
* [RabbitMQ](https://github.com/docker-library/rabbitmq) image for message queue

## Docker

### Environment variables

#### General

* `TZ` : The timezone assigned to the container and Inboxen (default `UTC`)
* `PUID` : Inboxen user id (default `1000`)
* `PGID`: Inboxen group id (default `1000`)
* `DB_TIMEOUT` : Time in seconds after which we stop trying to reach the PostgreSQL server (default `30`)

#### Inboxen

The following environment variables allow to populate the [settings.ini](https://inboxen.readthedocs.io/en/latest/settings.html) for Inboxen.

**General**

* `IB_ADMIN_EMAILS` : See [general / admin_emails](https://inboxen.readthedocs.io/en/latest/settings.html) setting
* `IB_ADMIN_NAMES` : See [general / admin_names](https://inboxen.readthedocs.io/en/latest/settings.html) setting
* `IB_ALLOWED_HOSTS` : See [general / allowed_hosts](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `*`)
* `IB_DEBUG` : See [general / debug](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `false`)
* `IB_ENABLE_REGISTRATION` :  See [general / enable_registration](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `false`)
* `IB_ENABLE_USER_EDITING` : See [general / enable_user_editing](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `false`)
* `IB_LANGUAGE_CODE` : See [general / language_code](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `en-gb`)
* `IB_LOGIN_ATTEMPT_COOLOFF` : See [general / login_attempt_cooloff](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `10`)
* `IB_LOGIN_ATTEMPT_LIMIT` :  See [general / login_attempt_limit](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `5`)
* `IB_REGISTER_LIMIT_WINDOW` : See [general / register_limit_window](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `1440`)
* `IB_REGISTER_LIMIT_COUNT` : See [general / register_limit_count](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `100`)
* `IB_SECRET_KEY` : See [general / secret_key](https://inboxen.readthedocs.io/en/latest/settings.html) setting
* `IB_SERVER_EMAIL` : See [general / server_email](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `docker-inboxen@localhost`)
* `IB_SITE_NAME` : See [general / site_name](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `Docker Inboxen`)
* `IB_SOURCE_LINK` : See [general / source_link](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `https://github.com/Inboxen/Inboxen`)
* `IB_PER_USER_EMAIL_QUOTA` : See [general / per_user_email_quota](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `0`)

**Inbox**

* `IB_INBOX_LENGTH` : See [inbox / inbox_length](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `5`)
* `IB_INBOX_LIMIT_WINDOW` : See [inbox / inbox_limit_window](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `1440`)
* `IB_INBOX_LIMIT_COUNT` : See [inbox / inbox_limit_count](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `100`)

**Tasks**

* `IB_TASKS_BROKER_URL` : See [tasks / broker_url](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `amqp://guest:guest@localhost:5672//`)
* `IB_TASKS_CONCURRENCY` : See [tasks / concurrency](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `3`)
* `IB_LIBERATION_SENDFILE_METHOD` : See [tasks / liberation / sendfile_method](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `simple`)

**Database**

* `IB_DB_NAME` : See [database / name](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `inboxen`)
* `IB_DB_USER` : See [database / user](https://inboxen.readthedocs.io/en/latest/settings.html) setting
* `IB_DB_PASSWORD` : See [database / password](https://inboxen.readthedocs.io/en/latest/settings.html) setting
* `IB_DB_HOST` : See [database / host](https://inboxen.readthedocs.io/en/latest/settings.html) setting
* `IB_DB_PORT` : See [database / port](https://inboxen.readthedocs.io/en/latest/settings.html) setting

**Cache**

* `IB_CACHE_TIMEOUT` : See [cache / timeout](https://inboxen.readthedocs.io/en/latest/settings.html) setting (default `300`)

### Volumes

* `/data` : Contains cache, media, logs and liberation data

### Ports

* `8080` : HTTP port of Nginx
* `8823` : SMTP port for Salmon mail server

## Use this image

### Docker Compose

Docker compose is the recommended way to run this image. You can use the following [docker compose template](examples/compose/docker-compose.yml), then run the container :

```bash
touch acme.json
chmod 600 acme.json
docker-compose up -d
docker-compose logs -f
```

## Notes

### Add super user

On first launch, you will have to create a super user to handle administration through `/admin` :

```
$ docker-compose exec --user inboxen inboxen sh -c ". env/bin/activate && ./manage.py createsuperuser --username <username> --email <email>"
Password:
Password (again):
Superuser created successfully.
```

> :warning: Substitute your desired username `<username>` and email address `<email>`

## Upgrade

To upgrade to the latest version, pull the newer image and launch the container. Inboxen will upgrade automatically :

```bash
docker-compose pull
docker-compose up -d
```

## How can I help ?

All kinds of contributions are welcome :raised_hands:!<br />
The most basic way to show your support is to star :star2: the project, or to raise issues :speech_balloon:<br />
But we're not gonna lie to each other, I'd rather you buy me a beer or two :beers:!

[![Paypal](.res/paypal.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=CF9YNTZWJCW3L)

## License

MIT. See `LICENSE` for more details.
