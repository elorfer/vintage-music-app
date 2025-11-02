import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
// import * as compression from 'compression';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);

  // Configuración de seguridad
  app.use(helmet());
  // app.use(compression.default());

  // CORS
  app.enableCors({
    origin: [
      'http://localhost:3001', // Admin panel (alternativo)
      'http://localhost:3002', // Admin panel (puerto principal)
      'http://localhost:3000', // Backend
      'http://localhost:8080', // Flutter web
      'http://localhost:8081', // Flutter web alternativo
      'http://localhost:8082', // Flutter web alternativo
      'http://127.0.0.1:8080', // Flutter web localhost alternativo
      'http://127.0.0.1:8081', // Flutter web localhost alternativo
      'http://127.0.0.1:3002', // Admin panel localhost
      'http://10.0.2.2:3000', // Android emulator
      'http://10.0.2.2:8080', // Android emulator Flutter
    ],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  });

  // Validación global
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Prefijo global para la API
  app.setGlobalPrefix('api/v1');

  // Configuración de Swagger
  const config = new DocumentBuilder()
    .setTitle('Vintage Music Streaming API')
    .setDescription('API para aplicación de streaming musical vintage')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('auth', 'Autenticación y autorización')
    .addTag('users', 'Gestión de usuarios')
    .addTag('artists', 'Gestión de artistas')
    .addTag('songs', 'Gestión de canciones')
    .addTag('playlists', 'Gestión de playlists')
    .addTag('streaming', 'Streaming de música')
    .addTag('analytics', 'Estadísticas y analytics')
    .addTag('payments', 'Procesamiento de pagos')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = configService.get('PORT', 3000);
  await app.listen(port);
  
  console.log(`🎵 Vintage Music Backend ejecutándose en puerto ${port}`);
  console.log(`📚 Documentación API disponible en http://localhost:${port}/api/docs`);
}

bootstrap();
