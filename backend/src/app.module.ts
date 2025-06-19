import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UsuarioModule } from './modules/usuario/usuario.module';
import { ClienteModule } from './modules/cliente/cliente.module';
import { EmpleadoModule } from './modules/empleado/empleado.module';
import { EntidadOperadoraModule } from './modules/entidad-operadora/entidad-operadora.module';
import { MicroModule } from './modules/micro/micro.module';
import { RutaModule } from './modules/ruta/ruta.module';
import { ParadaModule } from './modules/parada/parada.module';
import { TrackingModule } from './modules/tracking/tracking.module';
import { SocketModule } from './modules/socket/socket.module';
import { AuthModule } from './modules/auth/auth.module';
import { SeedersModule } from './modules/seeders/seeders.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get('DB_HOST', 'localhost'),
        port: configService.get('DB_PORT', 5432),
        username: configService.get('DB_USERNAME', 'postgres'),
        password: configService.get('DB_PASSWORD', 'password'),
        database: configService.get('DB_NAME', 'crucero_tracking'),
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        synchronize: configService.get('NODE_ENV') !== 'production',
        logging: configService.get('NODE_ENV') === 'development',
      }),
      inject: [ConfigService],
    }),
    // Módulos de entidades base
    UsuarioModule,
    ClienteModule,
    EmpleadoModule,
    
    // Módulos de negocio
    EntidadOperadoraModule,
    MicroModule,
    RutaModule,
    ParadaModule,
    
    // Módulos de funcionalidad
    TrackingModule,
    SocketModule,
    AuthModule,
    SeedersModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
