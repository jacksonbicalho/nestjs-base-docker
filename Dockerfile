ARG WORK_DIR_DEFAULT=/usr/src/app

#############################
# base: build for Base
#############################
FROM node:19-alpine As base

ONBUILD ENV YARN_VERSION 1.22.19

ONBUILD ARG NODE_ENV
ONBUILD ENV NODE_ENV ${NODE_ENV:-builder}

ONBUILD ARG USER_UID
ONBUILD ENV USER_UID ${USER_UID:-36891}

ONBUILD ARG USER_NAME=${NODE_ENV}
ONBUILD ENV USER_NAME ${USER_NAME:-criador}

ONBUILD ARG WORK_DIR
ONBUILD ENV WORK_DIR ${WORK_DIR:-$WORK_DIR_DEFAULT}

ONBUILD COPY \
  package.json* \
  yarn.lock* \
  .yarnrc* \
  .npmrc* \
  npm-shrinkwrap.json* \
  package-lock.json* \
  pnpm-lock.yaml* ./

ONBUILD RUN rm -rf /usr/local/bin/yarn \
  && rm -rf /usr/local/bin/yarnpkg \
  && npm uninstall --loglevel warn --global pnpm \
  && npm uninstall --loglevel warn --global npm \
  && deluser --remove-home node \
  && addgroup -S ${USER_NAME} -g ${USER_UID} \
  && adduser -S -G ${USER_NAME} -u ${USER_UID} ${USER_NAME} \
  && apk --no-cache update \
  && apk add --no-cache --virtual \
  builds-deps \
  make \
  python3 \
  bash \
  curl \
  git \
  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -snf /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -snf /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz \
  && yarn --version \
  && curl -sfL RUN curl -sf https://gobinaries.com/tj/node-prune | bash -s -- -b /usr/local/bin/ \
  && rm -rf /var/cache/apk/* \
  && yarn global add @nestjs/cli

ONBUILD WORKDIR ${WORK_DIR}

ONBUILD COPY . ./

ONBUILD RUN ls -l \
  && yarn \
  && ls /usr/local/bin/ \
  && /usr/local/bin/node-prune \
  && chown -R ${USER_NAME}:${USER_NAME} ./

ONBUILD USER ${USER_NAME}


#####################################
# development: build for development
#####################################
FROM base as development
LABEL developer=jacksonbicalho

ENV NODE_ENV=development

EXPOSE 3000

CMD ["yarn", "start:dev"]


##########################################
# builder-prod: pre bulder for production
##########################################
FROM node:19-alpine as builder-prod
LABEL developer=jacksonbicalho

ARG WORK_DIR
ENV WORK_DIR ${WORK_DIR:-$WORK_DIR_DEFAULT}

WORKDIR ${WORK_DIR}

COPY ./package.json ./yarn.lock ./tsconfig.json ./

RUN yarn install --production --frozen-lockfile

COPY . .

RUN yarn build


######################################
# production: builder form production
######################################
FROM node:19-alpine as production
LABEL developer=jacksonbicalho

ARG NODE_ENV=production
ENV NODE_ENV ${NODE_ENV}

ENV USER_NAME ${NODE_ENV}

RUN deluser --remove-home node \
  # Get a random UID/GID from 10,000 to 65,532
  && while [ "${ID:-0}" -lt "10000" ] || [ "${ID:-99999}" -ge "65533" ]; do \
  ID=$(od -An -tu -N2 /dev/urandom | tr -d " "); \
  done \
  && addgroup -S ${USER_NAME} -g ${ID} \
  && adduser -S -G ${USER_NAME} -u ${ID} ${USER_NAME} >/dev/null

ARG WORK_DIR
ENV WORK_DIR ${WORK_DIR:-$WORK_DIR_DEFAULT}

WORKDIR ${WORK_DIR}

COPY --chown=${USER_NAME}:${USER_NAME} --from=builder-prod ${WORK_DIR}/package.json ./package.json
COPY --chown=${USER_NAME}:${USER_NAME} --from=builder-prod ${WORK_DIR}/dist ./dist
COPY --chown=${USER_NAME}:${USER_NAME} --from=builder-prod ${WORK_DIR}/node_modules ./node_modules

USER ${USER_NAME}

EXPOSE 3000

CMD [ "yarn", "start:prod" ]


######################################
# testing: builder form tests
######################################
FROM development as testing
LABEL developer=jacksonbicalho

ENV CI=true
CMD ["yarn","test"]
