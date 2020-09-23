#!/bin/bash

set -o pipefail

set +e
#script trace mode
if [ "${DEBUG}" == "true" ]; then
  sex -o xtrace
fi

: "${WORK_HOME:="/root/"}"

#if `docker run` first argument start with `--` then user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  echo "start services..."
fi

# As argument is not main programs, assume user want to run his own process, for example a `bash` shell to explore this image
exec "$@"
