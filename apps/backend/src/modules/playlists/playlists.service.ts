import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Playlist } from '../../common/entities/playlist.entity';
import { User } from '../../common/entities/user.entity';
import { Song } from '../../common/entities/song.entity';
import { PlaylistVisibility } from '../../common/enums/playlist.enum';

@Injectable()
export class PlaylistsService {
  constructor(
    @InjectRepository(Playlist)
    private readonly playlistRepository: Repository<Playlist>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Song)
    private readonly songRepository: Repository<Song>,
  ) {}

  async findAll(page: number = 1, limit: number = 10): Promise<{ playlists: Playlist[]; total: number }> {
    const [playlists, total] = await this.playlistRepository.findAndCount({
      where: { visibility: PlaylistVisibility.PUBLIC },
      relations: ['user'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { playlists, total };
  }

  async findOne(id: string): Promise<Playlist> {
    const playlist = await this.playlistRepository.findOne({
      where: { id },
      relations: ['user', 'playlistSongs', 'playlistSongs.song', 'playlistSongs.song.artist'],
    });

    if (!playlist) {
      throw new NotFoundException('Playlist no encontrada');
    }

    return playlist;
  }

  async findByUser(userId: string, page: number = 1, limit: number = 10): Promise<{ playlists: Playlist[]; total: number }> {
    const [playlists, total] = await this.playlistRepository.findAndCount({
      where: { userId },
      relations: ['user'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { playlists, total };
  }

  async getFeaturedPlaylists(limit: number = 10): Promise<Playlist[]> {
    return this.playlistRepository.find({
      where: { isFeatured: true, visibility: PlaylistVisibility.PUBLIC },
      relations: ['user'],
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  async createPlaylist(userId: string, playlistData: any): Promise<Playlist> {
    const playlist = this.playlistRepository.create({
      ...playlistData,
      userId,
    });

    return this.playlistRepository.save(playlist as any);
  }

  async updatePlaylist(id: string, userId: string, updateData: any): Promise<Playlist> {
    const playlist = await this.findOne(id);

    if (playlist.userId !== userId) {
      throw new ForbiddenException('No tienes permisos para editar esta playlist');
    }

    Object.assign(playlist, updateData);
    return this.playlistRepository.save(playlist);
  }

  async deletePlaylist(id: string, userId: string): Promise<void> {
    const playlist = await this.findOne(id);

    if (playlist.userId !== userId) {
      throw new ForbiddenException('No tienes permisos para eliminar esta playlist');
    }

    await this.playlistRepository.remove(playlist);
  }

  async addSongToPlaylist(playlistId: string, songId: string, userId: string): Promise<void> {
    const playlist = await this.findOne(playlistId);

    if (playlist.userId !== userId) {
      throw new ForbiddenException('No tienes permisos para editar esta playlist');
    }

    const song = await this.songRepository.findOne({ where: { id: songId } });
    if (!song) {
      throw new NotFoundException('Canción no encontrada');
    }

    // Implementar lógica para agregar canción a playlist
    // Esto requeriría la entidad PlaylistSong
  }

  async removeSongFromPlaylist(playlistId: string, songId: string, userId: string): Promise<void> {
    const playlist = await this.findOne(playlistId);

    if (playlist.userId !== userId) {
      throw new ForbiddenException('No tienes permisos para editar esta playlist');
    }

    // Implementar lógica para remover canción de playlist
  }
}
