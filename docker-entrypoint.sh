#!/bin/bash

set -o pipefail
set +e
: "${WORK_HOME:="/root/"}"

# As argument is not main programs, assume user want to run his own process, for example a `bash` shell to explore this image
exec "$@"
