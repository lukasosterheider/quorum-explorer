FROM node:lts-alpine as dependencies
WORKDIR /app

RUN apk add --update git

RUN git clone --single-branch --depth 1 https://github.com/ConsenSys/quorum-explorer.git .

RUN apk add --no-cache --virtual .gyp \
  python3 \
  make \
  g++ \
  && npm i \
  && npm ci \
  && apk del .gyp

FROM node:lts-alpine as builder
WORKDIR /app

RUN apk add --update git
RUN git clone --single-branch --depth 1 https://github.com/ConsenSys/quorum-explorer.git .

COPY --from=dependencies /app/node_modules ./node_modules
RUN npm run build

FROM node:lts-alpine as runner
ENV NODE_ENV=production
WORKDIR /app
# If you are using a custom next.config.js file, uncomment this line.
COPY --from=builder /app/.env.production ./
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

EXPOSE 25000
CMD ["npm", "run", "start"]
