#!/bin/sh
set -x
rc-status

service sshd stop
service sshd start
