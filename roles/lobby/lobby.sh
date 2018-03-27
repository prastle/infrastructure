#!/bin/bash

. /root/infrastructure/common.sh

CURL="curl -L"
RUN_LOBBY="/root/infrastructure/roles/lobby/files/run_lobby.sh"
REMOVE_LOBBY="/root/infrastructure/roles/lobby/files/remove_lobby.sh"
LOBBY_SERVICE_FILE="/root/infrastructure/roles/lobby/files/triplea-lobby.service"
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case ${key} in
    --lobby-port)
    PORT="$2"
    shift # past argument
    shift # past value
    ;;
    --database-port)
    DATABASE_PORT="$2"
    shift # past argument
    shift # past value
    ;;
   --tag-name)
    TAG_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


function checkArg() {
  local label=$1
  local arg=$2
  if [ -z "$arg" ]; then
    echo "${label} was not set"
    exit 1
  fi
}

checkArg DATABASE_PORT $DATABASE_PORT
checkArg PORT $PORT
checkArg TAG_NAME $TAG_NAME


## TODO: arg check, if any are missing then report an error

echo "Lobby port: ${PORT}"
echo "Lobby database port: ${DATABASE_PORT}"
echo "Lobby version tag: ${TAG_NAME}"

set -ex

# Retrieve latest triplea version
if [[ "${TAG_NAME}" == "latest" ]]; then
  TAG_NAME=$($CURL -s 'https://api.github.com/repos/triplea-game/triplea/releases/latest' \
        | python3 -c "import sys, json; print(json.load(sys.stdin)['tag_name'])")
fi


function installLobbyMain() {
  local destFolder=/home/triplea/lobby/${TAG_NAME}
  if [ ! -d "${destFolder}" ]; then
   report "Lobby update to: ${TAG_NAME} started"
   installLobby ${destFolder} ${TAG_NAME}
   report "Lobby update to: ${TAG_NAME} complete"
  fi
  updateConfig
  chown -R triplea:triplea /home/triplea
}


function installLobby() {
  local destFolder=$1
  local tagName=$2

  mkdir -p ${destFolder}
  echo "$tagName" > ${destFolder}/version

  local installerFile="triplea-${tagName}-server.zip"
  wget "https://github.com/triplea-game/triplea/releases/download/${tagName}/${installerFile}"
  unzip -o -d ${destFolder} ${installerFile}
  rm ${installerFile}

  chmod go-rw ${destFolder}/config/lobby/lobby.properties

  cp ${RUN_LOBBY} ${destFolder}/
  cp ${REMOVE_LOBBY} ${destFolder}/
  chmod +x ${destFolder}/*.sh
}

## TODO: update database port + password
 ## todo: add lobby database port to props (do it outside of this method in case we are changing port)
function updateConfig() {
  local destFolder=$1

  local serviceFileDeployedPath="/lib/systemd/system/triplea-lobby.service"
  cp -v ${LOBBY_SERVICE_FILE} ${serviceFileDeployedPath}
  sed -i "s|LOBBY_DIR|${destFolder}|" ${serviceFileDeployedPath}
  systemctl enable triplea-lobby
  systemctl daemon-reload
}

installLobbyMain
