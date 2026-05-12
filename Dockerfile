# Etapa de construcción
FROM node:22-bookworm AS builder

WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar TODAS las dependencias (incluyendo devDependencies para compilar)
RUN npm ci

# Copiar el código fuente
COPY . .

# Compilar la aplicación NestJS
RUN npm run build

# Etapa de producción
FROM node:22-bookworm-slim

WORKDIR /app

# Establecer entorno a producción
ENV NODE_ENV=production
ENV PORT=3000

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar SOLO las dependencias de producción
RUN npm ci --omit=dev

# Configurar Playwright para que descargue los navegadores en una carpeta accesible
ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright

# Instalar dependencias del sistema requeridas por Playwright y luego descargar Chromium
RUN apt-get update && \
    npx playwright install --with-deps chromium && \
    rm -rf /var/lib/apt/lists/*

# Copiar el código compilado desde la etapa builder
COPY --from=builder /app/dist ./dist

# Copiar la carpeta pública de archivos estáticos
COPY --from=builder /app/public ./public

# Crear directorio data para el caché JSON y dar permisos a todas las carpetas necesarias
RUN mkdir -p data && \
    mkdir -p /home/node/.cache && \
    chown -R node:node /app && \
    chown -R node:node /home/node

# Cambiar a un usuario sin privilegios por seguridad
USER node

# Exponer el puerto de la aplicación
EXPOSE 3000

# Comando para iniciar la aplicación
CMD ["npm", "run", "start:prod"]
