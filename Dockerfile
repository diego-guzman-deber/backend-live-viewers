# ─────────────────────────────────────────────
# Etapa 1: Build
# ─────────────────────────────────────────────
FROM node:22-bookworm AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ─────────────────────────────────────────────
# Etapa 2: Producción
# ─────────────────────────────────────────────
FROM node:22-bookworm-slim

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
# Playwright instalará los browsers en esta ruta (como root durante el build)
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# 1. Instalar dependencias de producción
COPY package*.json ./
RUN npm ci --omit=dev

# 2. Instalar Chromium con sus dependencias del sistema (como root)
#    La carpeta /ms-playwright será accesible por cualquier usuario
RUN npx playwright install --with-deps chromium && \
    chmod -R 755 /ms-playwright

# 3. Copiar artefactos del builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public

# 4. Preparar directorio de datos y asignar propietario
RUN mkdir -p data && chown -R node:node /app

# 5. Ejecutar como usuario sin privilegios
USER node

EXPOSE 3000

# Verifica que el servidor responde (Docker/Dokploy usa esto para detectar crashes)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "dist/main"]
