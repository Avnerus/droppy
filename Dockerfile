FROM resin/odroid-ux3-alpine-node:4-slim
MAINTAINER avnerus

# Install and build modules
RUN apk add --update-cache --no-cache --virtual deps curl make gcc g++ python git && \
  # add yarn
  mkdir -p /opt && \
  curl -sL https://yarnpkg.com/latest.tar.gz | tar xz -C /opt && \
  mv /opt/dist /opt/yarn && \
  ln -s /opt/yarn/bin/yarn /usr/local/bin && \
  # install global modules
  yarn global add droppy@latest dmn@latest --production && \
  # add droppy symlink
  ln -s /usr/local/share/.config/yarn/global/node_modules/.bin/droppy /usr/bin/droppy && \
  # cleanup node modules
  cd /usr/local/share/.config/yarn/global && \
  dmn clean -f && \
  yarn global remove dmn && \
  # remove yarn
  rm -rf /usr/local/share/.cache/yarn && \
  rm -rf /opt && \
  # remove unnecessary module files
  rm -rf /usr/local/share/.config/yarn/global/node_modules/uws/*darwin*.node && \
  rm -rf /usr/local/share/.config/yarn/global/node_modules/uws/*win32*.node && \
  rm -rf /usr/local/share/.config/yarn/global/node_modules/uws/*linux_4*.node && \
  rm -rf /usr/local/share/.config/yarn/global/node_modules/uws/build && \
  rm -rf /usr/local/share/.config/yarn/global/node_modules/lodash/fp && \
  rm -rf /usr/local/share/.config/yarn/global/node_modules/lodash/_* && \
  rm -rf /usr/local/share/.config/yarn/global/node_modules/lodash/*.min.js && \
  rm -rf /usr/local/share/.config/yarn/global/node_modules/lodash/core.js && \
  # remove npm
  npm uninstall -g npm && \
  rm -rf /root/.npm && \
  rm -rf /tmp/npm* && \
  rm -rf /root/.node-gyp && \
  # cleanup apk
  apk del --purge deps && \
  rm -rf /var/cache/apk/*

EXPOSE 8989
VOLUME ["/config", "/files"]
CMD ["/usr/local/share/.config/yarn/global/node_modules/droppy/docker-start.sh"]
