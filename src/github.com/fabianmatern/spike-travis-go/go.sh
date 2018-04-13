#!/usr/bin/env bash

set -e

SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_NAME="${SOURCE_DIR##*/}"
TOOLS_DIR="$SOURCE_DIR/.tools"
DESIRED_DOCKER_COMPOSE_VERSION=1.13.0
DOCKER_COMPOSE="$TOOLS_DIR/docker-compose-$DESIRED_DOCKER_COMPOSE_VERSION-$(uname -s)-$(uname -m)"
ENVIRONMENTS_ALREADY_BUILT=()
RUNNING_ON_CI=$([ "$USER" = "jenkins" ] && echo -n "yes" || echo -n "no")
SUDO_ON_CI=$([ "$RUNNING_ON_CI" = "yes" ] && echo -n "sudo" || echo -n "")

function main {
  case "$1" in

  depinstall) depinstall;;
  setup) setup;;
  build) build;;
  run) run;;
  unitTest) unitTest "${@:2}";;
  lint) lint;;
  *)
    help
    exit 1
    ;;

  esac
}

function help {
  echo "Usage:"
  echo " unitTest               runs the unit test suite once"
  echo " - EVERYTHING ELSE -----------------------------------------------------"
  echo " lint                   runs go vet on the source code"
  echo " build                  builds the application"
  echo " run                    runs the application"
  echo " depinstall             installs the dependencies"
  echo " setup                  manually download dependencies, should run when new dependencies are added"
  echo
}

function depinstall {
  echoGreenText 'Installing dependencies...'
  runCommandInBuildContainer dep ensure
}

function setup {
  echoGreenText 'Downloading dependencies...'
  runCommandInBuildContainer dep ensure -vendor-only
}

function assureSetup {
  [ -d $SOURCE_DIR/vendor ] || setup
}

function build {
  echoGreenText 'Building application...'
  assureSetup
  runCommandInBuildContainer sh -c "go build -o infrastructure/dev/app/app main/main.go"

  echoGreenText 'Building application image...'
  GIT_HASH=$(git rev-parse --short=8 HEAD)
  $SUDO_ON_CI docker build -t "errorbudget/spiketravisgo:$GIT_HASH" "$SOURCE_DIR/infrastructure/dev/app"
}

function run {
  build

  echoGreenText 'Running application...'
  assureSetup
  runCommandInContainer "$SOURCE_DIR/infrastructure/dev/run.yml" app
}

function unitTest {
  echoGreenText 'Running unit tests...'
  assureSetup
  runCommandInBuildContainer sh -c "ginkgo $@ -cover -tags unitTests ./..."
}

function lint {
  echoGreenText 'Running linter...'
  assureSetup
  runCommandInBuildContainer sh -c "go list ./... | grep -v vendor | xargs go vet -v"
}

function checkForDockerCompose {
  hash docker 2>/dev/null || { echo >&2 "This script requires Docker, but it's not installed or not on your PATH."; exit 1; }

  if [ -f "$DOCKER_COMPOSE" ]; then
    return 0
  fi

  echoWhiteText "Downloading docker-compose..."
  mkdir -p "$(dirname $DOCKER_COMPOSE)"
  curl -# -L https://github.com/docker/compose/releases/download/$DESIRED_DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` > "$DOCKER_COMPOSE"
  chmod +x $DOCKER_COMPOSE
}

function runCommandInBuildContainer {
  runCommandInContainer "$SOURCE_DIR/infrastructure/dev/build-env.yml" build-env "$@"
}

function runCommandInContainer {
  checkForDockerCompose

  env=$1
  container=$2
  command=( "${@:3}" )

  if ! haveAlreadyBuiltEnvironment "$env"; then
    echoWhiteText 'Building environment (this may take a while the first time)...'
    output=$($SUDO_ON_CI "$DOCKER_COMPOSE" --project-name "$PROJECT_NAME" -f "$env" build 2>&1) || (echoRedText "Build failed. Output from docker-compose was:" && echo "$output" && exit 1)
    ENVIRONMENTS_ALREADY_BUILT+=("$env")
  fi

  echoWhiteText 'Cleaning up from previous runs...'
  $SUDO_ON_CI "$DOCKER_COMPOSE" --project-name "$PROJECT_NAME" -f "$env" down --volumes --remove-orphans 2>/dev/null

  if [[ "$command" == "" ]]; then
    echoWhiteText "Running container '$container'..."
  else
    echoWhiteText "Running '${command[@]}'..."
  fi

  # Normally, specifying ':cached' as the volume mount mode is fine. On OS X, we get the caching behaviour we want,
  # and on Linux, it's ignored (which is fine, because caching is unnecessary).
  # However, the version of Docker on our Jenkins instances is so old that it doesn't recognise the cached mode
  # and so complains. So we have to not use it when running on Jenkins.
  # Of course, we could upgrade the version of Docker on Jenkins, but that would require a lot of work, sadly.
  if [ "$RUNNING_ON_CI" == "yes" ]; then
    DOCKER_VOLUME_MOUNT_MODE=""
  else
    DOCKER_VOLUME_MOUNT_MODE=":cached"
  fi

  echo $DOCKER_VOLUME_MOUNT_MODE
  echo $DOCKER_COMPOSE
  echo $PROJECT_NAME
  echo $env
  echo $container

  DOCKER_VOLUME_MOUNT_MODE="$DOCKER_VOLUME_MOUNT_MODE" \
    $SUDO_ON_CI "$DOCKER_COMPOSE" --project-name "$PROJECT_NAME" -f "$env" run --service-ports --rm "$container" "${command[@]}" || cleanUpAfterFailure "$env"

  cleanUp "$env"
}

function cleanUpAfterFailure {
  env=${1:?}

  if [ "$RUNNING_ON_CI" = "yes" ]; then
    cleanUp "$env"
  else
    echoRedText 'Command failed. Containers will not be cleaned up to make debugging this issue easier.'
  fi

  exit 1
}

function cleanUp {
  env=$1

  echoWhiteText 'Completed, cleaning up...'
  $SUDO_ON_CI "$DOCKER_COMPOSE" --project-name "$PROJECT_NAME" -f "$env" down --volumes --remove-orphans 2>/dev/null
}

function haveAlreadyBuiltEnvironment {
  envToCheck=$1

  for e in "${ENVIRONMENTS_ALREADY_BUILT}"; do [[ "$e" == "$envToCheck" ]] && return 0; done
  return 1
}

function echoGreenText {
  if [[ "${TERM:-dumb}" == "dumb" ]]; then
    echo "${@}"
  else
    RESET=$(tput sgr0)
    GREEN=$(tput setaf 2)

    echo "${GREEN}${@}${RESET}"
  fi
}

function echoRedText {
  if [[ "${TERM:-dumb}" == "dumb" ]]; then
    echo "${@}"
  else
    RESET=$(tput sgr0)
    RED=$(tput setaf 1)

    echo "${RED}${@}${RESET}"
  fi
}

function echoWhiteText {
  if [[ "${TERM:-dumb}" == "dumb" ]]; then
     echo "${@}"
  else
    RESET=$(tput sgr0)
    WHITE=$(tput setaf 7)

    echo "${WHITE}${@}${RESET}"
  fi
}

main "$@"
