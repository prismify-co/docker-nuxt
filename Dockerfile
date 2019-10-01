# OS
FROM node:alpine as os
RUN mkdir -p /app
EXPOSE 3000
RUN apk add --update yarn

# Base
FROM os as base

ENV NODE_ENV=production
WORKDIR /app

COPY package*.json *lock ./

RUN yarn install --production && yarn cache clean

# Development
FROM base as development

WORKDIR /app
COPY . .

ENV PATH=/app/node_modules/.bin:$PATH
ENV NODE_ENV=development
ENV HOST 0.0.0.0

RUN yarn install --development
CMD [ "yarn", "dev" ]

# Source (copy in source)
FROM base as source

WORKDIR /app

COPY . .

# Test
FROM os as test

WORKDIR /app
COPY . .
RUN yarn install

ENV HOST 0.0.0.0
CMD [ "yarn", "test" ]

# Build
FROM source as build
ENV NODE_ENV=development
COPY --from=development /app/node_modules /app/node_modules
RUN yarn build

# Production (default)
FROM build as production
ENV NODE_ENV=production
ENV HOST 0.0.0.0

COPY --from=base /app/node_modules ./node_modules/
COPY --from=build /app/.nuxt .nuxt

CMD [ "node", "server/index.js" ]
