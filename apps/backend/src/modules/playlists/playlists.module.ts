import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { PlaylistsController } from './playlists.controller';
import { PlaylistsService } from './playlists.service';
import { Playlist } from '../../common/entities/playlist.entity';
import { User } from '../../common/entities/user.entity';
import { Song } from '../../common/entities/song.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Playlist, User, Song])],
  controllers: [PlaylistsController],
  providers: [PlaylistsService],
  exports: [PlaylistsService],
})
export class PlaylistsModule {}









