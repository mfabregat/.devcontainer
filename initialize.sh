#!/usr/bin/env bash

# Fallback for Xauthority if the env variable isn't explicitly set on host
XAUTH=${XAUTHORITY:-$HOME/.Xauthority}

cat << EOF > .devcontainer/.env
USER_UID=$(id -u)
USER_GID=$(id -g)
WORKSPACE_PATH=$(pwd)
WORKSPACE_NAME=$(basename $(pwd))
XAUTHORITY=${XAUTH}
EOF