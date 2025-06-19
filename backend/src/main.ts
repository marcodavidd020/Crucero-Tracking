import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

//seeders
// import { SeedersService } from './modules/seeders/seeders.service';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  // const seedersService = app.get(SeedersService);
  // await seedersService.seedAll();
  const configService = app.get(ConfigService);
  
  // Global validation pipe
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));
  
  // CORS configuration
  app.enableCors({
    origin: true,
    credentials: true,
  });
  
  // Global prefix for API routes
  app.setGlobalPrefix('api');
  
  // Swagger configuration
  const config = new DocumentBuilder()
    .setTitle('Crucero Tracking API')
    .setDescription('API para el sistema de tracking de transporte público')
    .setVersion('1.0')
    .addTag('auth', 'Autenticación y autorización')
    .addTag('entidad', 'Gestión de entidades operadoras')
    .addTag('ruta', 'Gestión de rutas')
    .addTag('tracking', 'Sistema de tracking GPS')
    .addTag('socket', 'Comunicación en tiempo real')
    .build();
  
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);
  
  const port = process.env.PORT || 3001;
  await app.listen(port);
  
  console.log(`🚀 Aplicación ejecutándose en: http://localhost:${port}/api`);
  console.log(`📚 Documentación Swagger en: http://localhost:${port}/api/docs`);
}

bootstrap();
