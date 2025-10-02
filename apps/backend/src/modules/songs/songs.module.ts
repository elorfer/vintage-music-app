import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { SongsController } from './songs.controller';
import { SongsService } from './songs.service';
import { Song } from '../../common/entities/song.entity';
import { Artist } from '../../common/entities/artist.entity';
import { Album } from '../../common/entities/album.entity';
import { Genre } from '../../common/entities/genre.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Song, Artist, Album, Genre])],
  controllers: [SongsController],
  providers: [SongsService],
  exports: [SongsService],
})
export class SongsModule {}









