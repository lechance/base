#!/bin/bash

set -o pipefail

set +e
#script trace mode
if [ "${DEBUG}" == "true" ]; then
  sex -o xtrace
fi

: "${WORK_HOME:="/root/"}"


# As argument is not main programs, assume user want to run his own process, for example a `bash` shell to explore this image
exec "$@"
