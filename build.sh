#!/usr/bin/env bash
set -e

PROJECT=inboxen
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_TAG=docker_build
VCS_REF=${TRAVIS_COMMIT::8}
RUNNING_TIMEOUT=50
RUNNING_LOG_CHECK="uwsgi entered RUNNING state"

DOCKER_USERNAME=${DOCKER_USERNAME:="crazymax"}
DOCKER_REPONAME=${DOCKER_REPONAME:="inboxen"}
QUAY_USERNAME=${QUAY_USERNAME:="crazymax"}
QUAY_REPONAME=${QUAY_REPONAME:="inboxen"}

# Check local or travis
BRANCH=${TRAVIS_BRANCH:-"local"}
if [[ ${TRAVIS_PULL_REQUEST} == "true" ]]; then
  BRANCH=${TRAVIS_PULL_REQUEST_BRANCH}
fi
DOCKER_TAG=${BRANCH:-"local"}
if [[ "$BRANCH" == "master" ]]; then
  DOCKER_TAG=latest
elif [[ "$BRANCH" == "local" ]]; then
  BUILD_DATE=
  VERSION=local
fi

echo "PROJECT=${PROJECT}"
echo "BUILD_DATE=${BUILD_DATE}"
echo "BUILD_TAG=${BUILD_TAG}"
echo "VCS_REF=${VCS_REF}"
echo "DOCKER_USERNAME=${DOCKER_USERNAME}"
echo "DOCKER_REPONAME=${DOCKER_REPONAME}"
echo "QUAY_USERNAME=${QUAY_USERNAME}"
echo "QUAY_REPONAME=${QUAY_REPONAME}"
echo "TRAVIS_BRANCH=${TRAVIS_BRANCH}"
echo "TRAVIS_PULL_REQUEST=${TRAVIS_PULL_REQUEST}"
echo "BRANCH=${BRANCH}"
echo "DOCKER_TAG=${DOCKER_TAG}"
echo

# Build
echo "### Build"
docker build \
  --build-arg BUILD_DATE=${BUILD_DATE} \
  --build-arg VCS_REF=${VCS_REF} \
  --build-arg VERSION=${VERSION} \
  -t ${BUILD_TAG} .
echo

echo "### Test"
docker rm -f ${PROJECT} ${PROJECT}-rabbitmq ${PROJECT}-db || true
docker network rm ${PROJECT} || true
docker network create -d bridge ${PROJECT}
docker run -d --network=${PROJECT} --name ${PROJECT}-rabbitmq --hostname ${PROJECT}-rabbitmq rabbitmq:3.7
docker run -d --network=${PROJECT} --name ${PROJECT}-db --hostname ${PROJECT}-db \
  -e "POSTGRES_DB=inboxen" \
  -e "POSTGRES_USER=inboxen" \
  -e "POSTGRES_PASSWORD=inboxen" \
  postgres:9.6
docker run -d --network=${PROJECT} --link ${PROJECT}-db --link ${PROJECT}-rabbitmq -p 8000:8080 \
  -e "IB_SECRET_KEY=${PROJECT}" \
  -e "IB_DB_HOST=${PROJECT}-db" \
  -e "IB_DB_NAME=inboxen" \
  -e "IB_DB_USER=inboxen" \
  -e "IB_DB_PASSWORD=inboxen" \
  -e "IB_TASKS_BROKER_URL=amqp://guest:guest@${PROJECT}-rabbitmq:5672//" \
  --name ${PROJECT} ${BUILD_TAG}
echo

echo "### Waiting for ${PROJECT} to be up..."
TIMEOUT=$((SECONDS + RUNNING_TIMEOUT))
while read LOGLINE; do
  echo ${LOGLINE}
  if [[ "${LOGLINE#*$RUNNING_LOG_CHECK}" != "$LOGLINE" ]]; then
    echo "Container up!"
    break
  fi
  if [[ $SECONDS -gt ${TIMEOUT} ]]; then
    >&2 echo "ERROR: Failed to run ${PROJECT} container"
    exit 1
  fi
done < <(docker logs -f ${PROJECT})
echo

if [ "${VERSION}" == "local" -o "${TRAVIS_PULL_REQUEST}" == "true" ]; then
  echo "INFO: This is a PR or a local build, skipping push..."
  exit 0
fi
if [[ ! -z ${DOCKER_PASSWORD} ]]; then
  echo "### Push to Docker Hub..."
  echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
  docker tag ${BUILD_TAG} ${DOCKER_USERNAME}/${DOCKER_REPONAME}:${DOCKER_TAG}
  docker tag ${BUILD_TAG} ${DOCKER_USERNAME}/${DOCKER_REPONAME}:${VERSION}
  docker push ${DOCKER_USERNAME}/${DOCKER_REPONAME}
  if [[ ! -z ${DOCKER_PASSWORD} ]]; then
    echo "Call MicroBadger hook"
    curl -X POST ${MICROBADGER_HOOK}
  fi
  echo
fi
if [[ ! -z ${QUAY_PASSWORD} ]]; then
  echo "### Push to Quay..."
  echo "$QUAY_PASSWORD" | docker login quay.io --username "$QUAY_USERNAME" --password-stdin
  docker tag ${BUILD_TAG} quay.io/${QUAY_USERNAME}/${QUAY_REPONAME}:${DOCKER_TAG}
  docker tag ${BUILD_TAG} quay.io/${QUAY_USERNAME}/${QUAY_REPONAME}:${VERSION}
  docker push quay.io/${QUAY_USERNAME}/${QUAY_REPONAME}
fi