#!/bin/bash
set -euo pipefail

export BUILD_TARGET="${1:-+plan}"

export CI="${CI:-false}"
export AWS_PROFILE="${AWS_PROFILE:-scalac-piotrres}"
export SSH_KEY_NAME="${SSH_KEY_NAME:-earthly}"

export EARTHLY_PARAMS="${EARTHLY_PARAMS:-}"

if [ "${CI}" == "true" ] ;
then
  export EARTHLY_PARAMS="$EARTHLY_PARAMS --ci"

  if [ "$GITHUB_REF_NAME" == "main" ] ;
  then
    export EARTHLY_PARAMS="$EARTHLY_PARAMS --push"
  fi
else
  export SSH_KEY_CONTENT="$(cat ~/.ssh/$SSH_KEY_NAME)"
  export AWS_CREDENTIALS="$(cat ~/.aws/credentials)"
fi

export EARTHLY_BUILD_ARGS="AWS_PROFILE=$AWS_PROFILE,SSH_KEY_NAME=$SSH_KEY_NAME"
export EARTHLY_SECRETS="SSH_KEY_CONTENT=$SSH_KEY_CONTENT,AWS_CREDENTIALS=$AWS_CREDENTIALS"

earthly $EARTHLY_PARAMS ${BUILD_TARGET}
