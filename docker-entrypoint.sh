#!/bin/bash
set -e
function sigterm_handler(){
  echo "SIGTERM signal received, try to gracefully shutdown all services..."
  #program stop
}

trap "sigterm_handler; exit" TERM
echo "Thank you for using this Docker Images!"
echo "Current version: $RELEASE_VERSION"
echo ""
if [[ "$RELEASE_VERSION" == "" ]]; then
  echo "Unknow version"
fi
echo "Start syslogd..."
syslogd
status=$?
if [[ $status -ne 0 ]]; then
  echo "Failed to start syslogd"
  exit $status
fi
sleep 1s

echo "Start Services..."
sleep 3s
echo "Start keepalived..."
keepalived -f "/etc/keepalived/keepalived.conf"
status=$?
echo "keepalived complete! $status"
if [[ $status -ne 0 ]]; then 
  echo "Failed to start keepalived: $status"
  exit $status
fi
echo "Start haproxy..."
haproxy -D -f "/etc/haproxy/haproxy.cfg"
status=$?
echo "haproxy complete! $status"
if [[ $status -ne 0 ]]; then
  echo "Failed to start haproxy: $status"
  exit $status
fi
echo "Start nginx..."
nginx #-g "daemon off;"
status=$?
echo "nginx complete! $status"
if [[ $status -ne 0 ]]; then
  echo "Failed to start nginx: $status"
  exit $status
fi

echo "Validate services..."
sleep 3s
killall -0 keepalived
chk=$?
if [[ $chk -ne 0 ]]; then
  echo "keepalived unexpected closed!"
  exit $chk
fi

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
