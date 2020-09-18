#!/bin/sh
set -x

service nginx stop
service nginx start
service sshd stop
service sshd start
