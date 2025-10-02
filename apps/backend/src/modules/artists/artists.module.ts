import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { ArtistsController } from './artists.controller';
import { ArtistsService } from './artists.service';
import { Artist } from '../../common/entities/artist.entity';
import { User } from '../../common/entities/user.entity';
import { Song } from '../../common/entities/song.entity';
import { Album } from '../../common/entities/album.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Artist, User, Song, Album])],
  controllers: [ArtistsController],
  providers: [ArtistsService],
  exports: [ArtistsService],
})
export class ArtistsModule {}









