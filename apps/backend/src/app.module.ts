import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule, TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ThrottlerModule } from '@nestjs/throttler';
import { ScheduleModule } from '@nestjs/schedule';
// import { RedisModule } from '@nestjs/redis';

// Módulos de la aplicación
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ArtistsModule } from './modules/artists/artists.module';
import { SongsModule } from './modules/songs/songs.module';
import { PlaylistsModule } from './modules/playlists/playlists.module';
import { StreamingModule } from './modules/streaming/streaming.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { UploadModule } from './modules/upload/upload.module';
import { HealthModule } from './modules/health/health.module';
import { PublicModule } from './modules/public/public.module';
import { entities } from './database/entities';

// Configuración de la base de datos
import { dataSourceOptions } from './database/data-source';

@Module({
  imports: [
    // Configuración global
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),

    // Base de datos PostgreSQL
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService): TypeOrmModuleOptions => {
        const isProduction = configService.get<string>('NODE_ENV') === 'production';
        const databaseUrl = configService.get<string>('DATABASE_URL');

        const baseOptions: TypeOrmModuleOptions = {
          type: 'postgres',
          entities,
          autoLoadEntities: true,
          synchronize: !isProduction,
          logging: !isProduction,
        };

        if (databaseUrl) {
          return {
            ...baseOptions,
            url: databaseUrl,
            ssl: isProduction ? { rejectUnauthorized: false } : false,
          };
        }

        return {
          ...baseOptions,
          host: configService.get<string>('DB_HOST') ?? 'localhost',
          port: Number(configService.get<string>('DB_PORT') ?? '5432'),
          username: configService.get<string>('DB_USERNAME') ?? 'vintage_user',
          password: configService.get<string>('DB_PASSWORD') ?? 'vintage_password_2024',
          database: configService.get<string>('DB_DATABASE') ?? 'vintage_music',
          ssl: isProduction ? { rejectUnauthorized: false } : false,
        };
      },
      inject: [ConfigService],
    }),

    // Redis para estadísticas en tiempo real
    // RedisModule.forRootAsync({
    //   imports: [ConfigModule],
    //   useFactory: (configService: ConfigService) => ({
    //     url: configService.get('REDIS_URL'),
    //   }),
    //   inject: [ConfigService],
    // }),

    // Rate limiting
    ThrottlerModule.forRoot([
      {
        ttl: 60000, // 1 minuto
        limit: 100, // 100 requests por minuto
      },
    ]),

    // Tareas programadas
    ScheduleModule.forRoot(),

    // Módulos de la aplicación
    HealthModule,
    AuthModule,
    UsersModule,
    ArtistsModule,
    SongsModule,
    PlaylistsModule,
    StreamingModule,
    AnalyticsModule,
    PaymentsModule,
    UploadModule,
    PublicModule,
  ],
})
export class AppModule {}
