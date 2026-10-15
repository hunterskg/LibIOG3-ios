import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DB_HOST', 'localhost'),
        port: Number(config.get('DB_PORT', 5432)),
        username: config.get<string>('DB_USERNAME', 'postgres'),
        password: config.get<string>('DB_PASSWORD', 'postgres'),
        database: config.get<string>('DB_DATABASE', 'prm_project'),
        autoLoadEntities: true,
        synchronize:
          config.get<string>('DB_SYNCHRONIZE') !== undefined
            ? config.get<string>('DB_SYNCHRONIZE') === 'true'
            : config.get<string>('NODE_ENV') !== 'production',
        logging: config.get<string>('DB_LOGGING') === 'true',
        ssl:
          config.get<string>('DB_SSL') === 'true'
            ? { rejectUnauthorized: false }
            : false,
        extra: {
          max: 20,
          connectionTimeoutMillis: 10000,
          idleTimeoutMillis: 30000,
          keepAlive: true,
          keepAliveInitialDelayMillis: 10000,
        },
      }),
    }),
  ],
})
export class DatabaseModule {}
