##
# OS
##
FROM node:alpine as os

RUN mkdir -p /app

RUN  apk add --update --no-cache curl git && cd /tmp && \
    curl -#L https://github.com/tj/node-prune/releases/download/v1.0.1/node-prune_1.0.1_linux_amd64.tar.gz | tar -xvzf- && \
    mv -v node-prune /usr/local/bin && rm -rvf * && \
    echo "yarn cache clean && node-prune" > /usr/local/bin/node-clean && chmod +x /usr/local/bin/node-clean

##
# Base
##
FROM os as base

WORKDIR /app

ENV NODE_ENV=development

COPY package.json ./

RUN yarn

##
# Test
##
FROM os as test

WORKDIR /app

COPY . .
COPY --from=base ./app/yarn.lock ./yarn.lock
COPY --from=base ./app/node_modules ./node_modules/

RUN yarn

CMD [ "yarn", "test" ]


##
# Development
##
FROM os as development

WORKDIR /app
ENV NODE_ENV=development
ENV HOST 0.0.0.0

COPY . .
COPY --from=base ./app/node_modules ./node_modules/

CMD [ "yarn", "dev" ]

##
# Build
##
FROM os as build

WORKDIR /app

COPY . .
COPY --from=base ./app/yarn.lock ./yarn.lock
COPY --from=base ./app/node_modules ./node_modules/

RUN yarn
RUN yarn build
RUN yarn cache clean && node-clean

##
# Production
##
FROM os as production

WORKDIR /app
ENV NODE_ENV=production
ENV HOST=0.0.0.0

COPY package.json ./
COPY nuxt.config.js ./

COPY --from=build ./app/ ./

EXPOSE 3000
CMD ["yarn", "start"]
