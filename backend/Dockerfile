FROM node:20-alpine AS base

# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat

# Setup Infisical [https://infisical.com/docs/integrations/platforms/docker] for env management
RUN apk add --no-cache bash curl && curl -1sLf \
'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.alpine.sh' | bash \
&& apk add infisical

# ==============================================================
# 1. Install dependencies only when needed
# ==============================================================
FROM base AS deps

WORKDIR /app

# Install dependencies based on the preferred package manager
# ENV NODE_ENV=production
COPY package.json ./
RUN npm install


# ==============================================================
# 2. Rebuild the source code only when needed
# ==============================================================
FROM base AS builder

WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ARG infisical_env
ARG infisical_project_id

RUN --mount=type=secret,id=infisical_token,required=true \
  INFISICAL_TOKEN=$(cat /run/secrets/infisical_token) \
  infisical export --projectId=$infisical_project_id --env=$infisical_env --path=/backend > .env

RUN npm run tsc

RUN rm .env


# ==============================================================
# 3. Production image, copy all the files and run next
# ==============================================================
FROM base AS runner

WORKDIR /app

COPY --from=builder /app .

EXPOSE 8000

ENV PORT 8000
ENV HOSTNAME 0.0.0.0

# CMD ["infisical", "run", "--env=staging", "--path=/backend", "--", "node", "server/index.js"]