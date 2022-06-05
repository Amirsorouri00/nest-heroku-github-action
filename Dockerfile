FROM docker.incitedev.org/pub/node:16.13.1 AS builder

USER root

WORKDIR /app

RUN chown node:node .

USER node

COPY --chown=node:node ["package.json", "package-lock.json", "./"]

RUN npm config set registry http://registry.npmjs.org/

RUN NODE_ENV=production npm ci && mv node_modules /tmp && npm ci && rm -rf /home/node/.cache

COPY --chown=node:node . .

RUN make build

FROM gcr.io/distroless/nodejs:16 AS runner

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/package-lock.json ./package-lock.json
COPY --from=builder /tmp/node_modules ./node_modules
COPY --from=builder /lib/x86_64-linux-gnu/libuuid.so.1.3.0 /lib/x86_64-linux-gnu/libuuid.so.1

ENV NODE_ENV=production

CMD ["dist/main"]