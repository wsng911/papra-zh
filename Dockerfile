FROM node:24-slim AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN corepack enable && corepack prepare pnpm@10.33.0 --activate

FROM base AS build

WORKDIR /app

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/* && \
    git config --global user.email "dev@example.com" && \
    git config --global user.name "dev"

COPY pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/papra-client/package.json apps/papra-client/
COPY apps/papra-server/package.json apps/papra-server/
COPY packages/webhooks/package.json packages/webhooks/
COPY packages/lecture/package.json packages/lecture/
COPY packages/search-parser/package.json packages/search-parser/

RUN pnpm install --frozen-lockfile --ignore-scripts

COPY . .

RUN git init && git add -A && git commit -m "init" || true

RUN pnpm --filter "@papra/app-client..." run build && \
    pnpm --filter "@papra/app-server..." run build

RUN pnpm deploy --filter=@papra/app-server --legacy --prod /prod/papra-server

FROM base

WORKDIR /app

COPY --from=build /prod/papra-server ./
COPY --from=build /app/apps/papra-client/dist ./public

RUN mkdir -p ./app-data/db ./app-data/documents ./ingestion

ENV NODE_ENV=production
ENV SERVER_SERVE_PUBLIC_DIR=true
ENV DATABASE_URL=file:./app-data/db/db.sqlite
ENV DOCUMENT_STORAGE_FILESYSTEM_ROOT=./app-data/documents
ENV PAPRA_CONFIG_DIR=./app-data
ENV EMAILS_DRY_RUN=true
ENV CLIENT_BASE_URL=http://localhost:1221
ENV BETTER_AUTH_TELEMETRY=0

EXPOSE 1221

CMD ["pnpm", "start:with-migrations"]
