# # # #
# #
# #  BASE CONTAINER
# #
# # # #

FROM ruby:2.6.5-alpine AS base-container

LABEL maintainer  = "Dustin Ward <dustin.n.ward@gmail.com>"
LABEL version     = "1.0"

## ENVIRONMENT VARIABLES
ENV TERM=xterm-256color
ENV LANG=C.UTF-8
ENV GEM_HOME=/bundle
ENV BUNDLE_JOBS=4
ENV BUNDLE_RETRY=3
ENV BUNDLE_PATH=$GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH
ENV BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH=$APP_PATH/bin:$BUNDLE_BIN:$PATH
ENV TZ=America/Chicago

## ARGUMENT VARIABLES
ARG APP_PATH=/usr/src/app
ARG BASE_PACKAGES="zsh curl wget git zsh-vcs openssl-dev yarn ca-certificates"
ARG BUILD_PACKAGES="build-base"
ARG DEV_PACKAGES="curl-dev ruby-dev zlib-dev libxml2-dev libxslt-dev yaml-dev tzdata"
ARG DB_PACKAGES="postgresql-dev postgresql-client mysql-dev mysql-client sqlite sqlite-dev sqlite-libs"
ARG RUBY_PACKAGES="ruby-json yaml nodejs"

## INSTALL PACKAGES
RUN apk update && \
    apk upgrade && \
    apk add --update\
    $BASE_PACKAGES \
    $BUILD_PACKAGES \
    $DEV_PACKAGES \
    $DB_PACKAGES \
    $RUBY_PACKAGES && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    rm -rf /var/cache/apk/* && \
    mkdir -p $APP_PATH

## SETUP DEFAULT APP USER, ZSH & POWERLEVEL THEME
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git /usr/share/oh-my-zsh && \
    git clone https://github.com/bhilburn/powerlevel9k.git /usr/share/oh-my-zsh/custom/themes/powerlevel9k && \
    mkdir -p /etc/skel/.oh-my-zsh/cache

COPY ./.docker/services/base/etc/skel/.zshrc /etc/skel/.zshrc
COPY ./.docker/services/base/etc/motd /etc/motd
COPY ./.docker/services/base/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN addgroup -S default && adduser -S default -G default -k /etc/skel
RUN sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd

RUN chown default:default /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

## TRUST SSL CERTIFICATE
COPY ./.docker/certificates/ejbca-dev_management-ca.pem /usr/local/share/ca-certificates/ejbca-dev_management-ca.crt
RUN update-ca-certificates


## GRANT PERMISSIONS TO APP DIRECTPRY TO DEFAULT APP USER
RUN mkdir -p /bundle

## RUN ZSH SHELL BY DEFAULT
WORKDIR $APP_PATH

RUN gem install foreman

RUN chown -R default:default /bundle
RUN chown -R default:default $APP_PATH

USER default

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["zsh"]

# # # #
# #
# #  APPLICATION CONTAINER
# #
# # # #

FROM base-container AS application
USER root
COPY ./.docker/services/application/etc/motd /etc/motd
COPY ./.docker/services/application/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chown default:default /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 3000

USER default
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["foreman", "start"]

# # # #
# #
# #  POSTGRES CONTAINER
# #
# # # #


# # # #
# #
# #  MYSQL CONTAINER
# #
# # # #

FROM base-container AS mysql
USER root
COPY ./.docker/services/mysql/etc/motd /etc/motd
COPY ./.docker/services/mysql/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chown default:default /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

RUN apk add --update mysql mysql-client && \
    rm -rf /var/cache/apk/*

RUN addgroup mysql mysql

COPY ./.docker/services/mysql/etc/mysql/my.cnf /etc/my.cnf

VOLUME ["/var/lib/mysql"]

EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/mysqld_safe"]

# # # #
# #
# #  REDIS CONTAINER
# #
# # # #

FROM base-container AS redis
USER root
COPY ./.docker/services/redis/etc/motd /etc/motd
COPY ./.docker/services/redis/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chown default:default /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

RUN apk add --update redis && \
    rm -rf /var/cache/apk/* && \
    mkdir /data && \
    chown -R default:default /data

RUN sed -i 's#logfile /var/log/redis/redis.log#logfile ""#i' /etc/redis.conf && \
    sed -i 's#daemonize yes#daemonize no#i' /etc/redis.conf && \
    sed -i 's#dir /var/lib/redis/#dir /data#i' /etc/redis.conf

VOLUME ["/data"]
EXPOSE 6379

USER default
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["redis-server"]

# # # #
# #
# #  MAILCATCHER CONTAINER
# #
# # # #

FROM base-container AS mailcatcher
USER root
COPY ./.docker/services/mailcatcher/etc/motd /etc/motd
COPY ./.docker/services/mailcatcher/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chown default:default /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh
RUN gem install mailcatcher
EXPOSE 1025 1080

USER default
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["mailcatcher", "--foreground", "--ip=0.0.0.0", "--smtp-port=1025", "--http-port=1080"]
