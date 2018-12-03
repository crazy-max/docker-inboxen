#!/bin/sh

function fixperms() {
  for folder in $@; do
    if $(find ${folder} ! -user inboxen -o ! -group inboxen | egrep '.' -q); then
      echo "Fixing permissions in $folder..."
      chown -R inboxen. "${folder}"
    else
      echo "Permissions already fixed in ${folder}"
    fi
  done
}

function runas_inboxen() {
  su - inboxen -s /bin/sh -c "$1"
}

TZ=${TZ:-UTC}
export PUID=${PUID:-1000}
export PGID=${PGID:-1000}

DB_TIMEOUT=${DB_TIMEOUT:-30}

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# Change inboxen UID / GID
echo "Checking if inboxen UID / GID has changed..."
if [[ $(id -u inboxen) != ${PUID} ]]; then
  usermod -u ${PUID} inboxen
fi
if [[ $(id -g inboxen) != ${PGID} ]]; then
  groupmod -g ${PGID} inboxen
fi

# Init
echo "Initializing Inboxen files / folders..."
mkdir -p /data/cache /data/liberation /data/media

# Config
# SECRET_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1)
if [[ -z "$IB_SECRET_KEY" -o -z "$IB_DB_HOST" -o -z "$IB_DB_USER" -o -z "$IB_DB_PASSWORD" ]]; then
  >&2 echo "ERROR: IB_SECRET_KEY, IB_DB_HOST, IB_DB_USER and IB_DB_PASSWORD must be defined"
  exit 1
fi
export PGPASSWORD=${IB_DB_PASSWORD}
dbcmd="psql --host=${IB_DB_HOST} --port=${IB_DB_PORT:-5432} --username=${IB_DB_USER} -lqt"

# https://github.com/Inboxen/Inboxen/blob/master/docs/settings.rst
cat > /app/settings.ini <<EOL
[general]
admin_emails = ${IB_ADMIN_EMAILS}
admin_names = ${IB_ADMIN_NAMES}
allowed_hosts = ${IB_ALLOWED_HOSTS:-*}
debug = ${IB_DEBUG:-false}
enable_registration = ${IB_ENABLE_REGISTRATION:-false}
enable_user_editing = ${IB_ENABLE_USER_EDITING:-false}
language_code = ${IB_LANGUAGE_CODE:-en-gb}
login_attempt_cooloff = ${IB_LOGIN_ATTEMPT_COOLOFF:-10}
login_attempt_limit = ${IB_LOGIN_ATTEMPT_LIMIT:-5}
register_limit_window = ${IB_REGISTER_LIMIT_WINDOW:-1440}
register_limit_count = ${IB_REGISTER_LIMIT_COUNT:-100}
static_root = /app/static
media_root = /data/media
secret_key = ${IB_SECRET_KEY}
server_email = ${IB_SERVER_EMAIL:-docker-inboxen@localhost}
site_name = ${IB_SITE_NAME:-Docker Inboxen}
source_link = ${IB_SOURCE_LINK:-https://github.com/Inboxen/Inboxen}
time_zone = ${TZ}
per_user_email_quota = ${IB_PER_USER_EMAIL_QUOTA:-0}

[inbox]
inbox_length = ${IB_INBOX_LENGTH:-5}
inbox_limit_window = ${IB_INBOX_LIMIT_WINDOW:-1440}
inbox_limit_count = ${IB_INBOX_LIMIT_COUNT:-100}

[tasks]
broker_url = ${IB_TASKS_BROKER_URL:-amqp://guest:guest@localhost:5672//}
concurrency = ${IB_TASKS_CONCURRENCY:-3}

[[liberation]]
path = /data/liberation
sendfile_method = ${IB_LIBERATION_SENDFILE_METHOD:-simple}

[database]
name = ${IB_DB_NAME:-inboxen}
user = ${IB_DB_USER}
password = ${IB_DB_PASSWORD}
host = ${IB_DB_HOST}
port = ${IB_DB_PORT:-5432}

[cache]
backend = file
location = /data/cache
timeout = ${IB_CACHE_TIMEOUT:-300}
EOL
chown inboxen. /app/settings.ini

# Fix perms
echo "Fixing permissions..."
fixperms /app /data/cache /data/liberation /data/logs /data/media

echo "Waiting ${DB_TIMEOUT}s for database to be ready..."
counter=1
while ${dbcmd} | cut -d \| -f 1 | grep -qw ${IB_DB_NAME:-inboxen} > /dev/null 2>&1; [[ $? -ne 0 ]]; do
  sleep 1
  counter=$((counter + 1))
  if [[ ${counter} -gt ${DB_TIMEOUT} ]]; then
    >&2 echo "ERROR: Failed to connect to database on $IB_DB_HOST"
    exit 1
  fi;
done
echo "Database ready!"

unset IB_SECRET_KEY
unset IB_DB_USER
unset IB_DB_PASSWORD
unset IB_DB_HOST
unset PGPASSWORD

# Migrate DB
runas_inboxen ". env/bin/activate && ./manage.py migrate"

exec "$@"
