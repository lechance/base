FROM alpine 

LABEL org.label-schema.name="alpine:me" \
      org.label-schema.vendor="lechance" \
      org.label-schema.description="Docker image customized by lechance" \
      org.label-schema.version="latest" \
      org.label-schema.license="MIT"

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

RUN apk --update -t add openrc python3 py3-pip openssh keepalived sudo bash grep iproute2 tcpdump && \
    rm -f /var/cache/apk/* /tmp/* && \
    rm -f /sbin/halt /sbin/poweroff /sbin/reboot


RUN mkdir -p /run/openrc && \
    touch /run/openrc/softlevel 

RUN rc-update add keepalived default
RUN rc-update add sshd default


RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64
RUN chmod +x /usr/local/bin/dumb-init


ENV myName="lechance"

VOLUME ["/sys/fs/cgroup"]

RUN set -x \
    # Disable getty's
    && sed -i 's/^\(tty\d\:\:\)/#\1/g' /etc/inittab \
    && sed -i \
        # Change subsystem type to "docker"
        -e 's/#rc_sys=".*"/rc_sys="docker"/g' \
        # Allow all variables through
        -e 's/#rc_env_allow=".*"/rc_env_allow="\*"/g' \
        # Start crashed services
        -e 's/#rc_crashed_stop=.*/rc_crashed_stop=NO/g' \
        -e 's/#rc_crashed_start=.*/rc_crashed_start=YES/g' \
        # Define extra dependencies for services
        -e 's/#rc_provide=".*"/rc_provide="loopback net"/g' \
        /etc/rc.conf \
    # Remove unnecessary services
    && rm -f /etc/init.d/hwdrivers \
            /etc/init.d/hwclock \
            /etc/init.d/hwdrivers \
            /etc/init.d/modules \
            /etc/init.d/modules-load \
            /etc/init.d/modloop \
    # Can't do cgroups
    && sed -i 's/cgroup_add_service /# cgroup_add_service /g' /lib/rc/sh/openrc-run.sh \
    && sed -i 's/VSERVER/DOCKER/Ig' /lib/rc/sh/init.sh


WORKDIR /tmp/
EXPOSE 22
ENTRYPOINT ["/usr/local/bin/dumb-init","--"]
CMD ["/bin/sh"]
