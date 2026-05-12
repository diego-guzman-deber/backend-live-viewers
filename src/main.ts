import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Habilitar CORS
  app.enableCors({
    origin: [
      'http://localhost:3000',
      'http://localhost:3001',
      'http://localhost:5173',
      'http://localhost:5174',
      'http://127.0.0.1:3001',
      'http://127.0.0.1:5173',

      // acceso desde red interna
      'http://172.20.16.38:5173',
    ],
    credentials: true,
  });

  // Servir archivos estáticos
  app.useStaticAssets(join(__dirname, '..', 'public'));

  const port = process.env.PORT ?? 3000;

  // Escuchar en todas las interfaces (clave para servidor)
  await app.listen(port, '0.0.0.0');

  console.log(`🚀 Servidor corriendo en puerto ${port}`);
  console.log(`🌐 API: http://172.20.16.38:${port}`);
  console.log(`📊 Viewer: http://172.20.16.38:${port}/realtime-viewer.html`);
}

bootstrap();