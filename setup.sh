#!/bin/sh
set -xeu

service nginx stop
service nginx start
service sshd stop
service sshd start
service keepalived stop
service keepalived start

