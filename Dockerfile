FROM alpine 
USER root
LABEL org.label-schema.name="alpine:me" \
      org.label-schema.vendor="lechance" \
      org.label-schema.description="Docker image customized by lechance" \
      org.label-schema.version="latest" \
      org.label-schema.license="MIT"

ENV TINI_VERSION v0.19.0

#ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini  /tini
#RUN chmod +x /tini

ENV TIME_ZONE Asia/Shanghai

RUN echo "http://mirrors.aliyun.com/alpine/latest-stable/main/" > /etc/apk/repositories
RUN echo "http://mirrors.aliyun.com/alpine/latest-stable/community/" >> /etc/apk/repositories

RUN set -eux && \
    addgroup -S -g 1995 zhang && \
    adduser -S -D -G zhang -G root -u 1997 -h /var/lib/zhang/ zhang

#RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

RUN apk --update -t add openrc tzdata haproxy ipvsadm curl nginx python3 py3-pip openssh keepalived sudo bash grep iproute2 tcpdump tini && \
    rm -f /var/cache/apk/* /tmp/* && \
    rm -f /sbin/halt /sbin/poweroff /sbin/reboot

RUN echo "${TIME_ZONE}" > /etc/timezone && \
    ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime && \
    sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    ssh-keygen -t dsa -P "" -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -t rsa -P "" -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -t ecdsa -P "" -f /etc/ssh/ssh_host_ecsdsa_key && \
    ssh-keygen -t ed25519 -P "" -f /etc/ssh/ssh_host_ed25519_key && \
    echo "root:admin" | chpasswd

RUN mkdir -p /run/openrc && \
    touch /run/openrc/softlevel 
RUN mkdir -p /root/www

RUN rc-update add keepalived default
RUN rc-update add sshd default
RUN rc-update add nginx default

RUN mkdir -p /run/nginx

#RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64
#RUN chmod +x /usr/local/bin/dumb-init


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
RUN echo "welcome nginx" > /root/www/index.htm

RUN sed -i '/return 404;/d' /etc/nginx/conf.d/default.conf \
    && sed -i '9a root \/root\/www;' /etc/nginx/conf.d/default.conf \
    && sed -i '10a index index.html index.htm;' /etc/nginx/conf.d/default.conf \
    && sed -i 's/user nginx/user root/' /etc/nginx/nginx.conf

WORKDIR /root/

COPY setup.sh .
COPY ["docker-entrypoint.sh","/usr/local/bin/"]

#RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 22
EXPOSE 80

STOPSIGNAL SIGTERM


ENTRYPOINT ["/sbin/tini", "--", "/bin/sh", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/sh"]
#CMD ["nginx","-g","daemon off;"]
