FROM mirror.gcr.io/library/node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# Correctly inject output: 'standalone' into next.config.js
# We use a more robust sed that works whether the object is empty or has properties
RUN sed -i "s/const nextConfig = {/const nextConfig = {\n    output: 'standalone',/g" next.config.js
ENV NODE_OPTIONS="--max-old-space-size=8192"
RUN npm run build

FROM mirror.gcr.io/library/node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000
# Copy standalone build output
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
EXPOSE 3000
CMD ["node", "server.js"]