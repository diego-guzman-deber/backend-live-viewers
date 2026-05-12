# ─────────────────────────────────────────────
# Etapa 1: Build
# ─────────────────────────────────────────────
FROM node:22-bookworm AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

# Copiar fuentes (sin dist gracias al .dockerignore)
COPY . .

# Compilar – genera /app/dist/
RUN npm run build && ls -la dist/

# ─────────────────────────────────────────────
# Etapa 2: Producción
# ─────────────────────────────────────────────
FROM node:22-bookworm-slim

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# Dependencias de producción
COPY package*.json ./
RUN npm ci --omit=dev

# Instalar Chromium con sus dependencias (como root)
RUN npx playwright install --with-deps chromium && \
    chmod -R 755 /ms-playwright

# Copiar dist compilado desde el builder
COPY --from=builder /app/dist /app/dist

# Copiar archivos estáticos
COPY --from=builder /app/public /app/public

# Verificar que main.js existe antes de continuar
RUN test -f /app/dist/main.js && echo "✅ dist/main.js encontrado" || (echo "❌ dist/main.js NO encontrado. Contenido de dist/:" && ls -la /app/dist/ && exit 1)

# Directorio de datos con permisos correctos
RUN mkdir -p /app/data && chown -R node:node /app

USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000', r => process.exit(r.statusCode < 500 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "/app/dist/main.js"]
