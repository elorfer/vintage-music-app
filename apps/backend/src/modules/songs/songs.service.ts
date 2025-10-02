import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Song, SongStatus } from '../../common/entities/song.entity';
import { Artist } from '../../common/entities/artist.entity';
import { Album } from '../../common/entities/album.entity';
import { Genre } from '../../common/entities/genre.entity';

@Injectable()
export class SongsService {
  constructor(
    @InjectRepository(Song)
    private readonly songRepository: Repository<Song>,
    @InjectRepository(Artist)
    private readonly artistRepository: Repository<Artist>,
    @InjectRepository(Album)
    private readonly albumRepository: Repository<Album>,
    @InjectRepository(Genre)
    private readonly genreRepository: Repository<Genre>,
  ) {}

  async findAll(page: number = 1, limit: number = 10): Promise<{ songs: Song[]; total: number }> {
    const [songs, total] = await this.songRepository.findAndCount({
      where: { status: SongStatus.PUBLISHED },
      relations: ['artist', 'album', 'genre'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { songs, total };
  }

  async findOne(id: string): Promise<Song> {
    const song = await this.songRepository.findOne({
      where: { id },
      relations: ['artist', 'album', 'genre'],
    });

    if (!song) {
      throw new NotFoundException('Canción no encontrada');
    }

    return song;
  }

  async findByArtist(artistId: string, page: number = 1, limit: number = 10): Promise<{ songs: Song[]; total: number }> {
    const [songs, total] = await this.songRepository.findAndCount({
      where: { artistId, status: SongStatus.PUBLISHED },
      relations: ['album', 'genre'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { songs, total };
  }

  async getTopSongs(limit: number = 10): Promise<Song[]> {
    return this.songRepository.find({
      where: { status: SongStatus.PUBLISHED },
      relations: ['artist', 'album', 'genre'],
      order: { totalStreams: 'DESC' },
      take: limit,
    });
  }

  async getSongsByGenre(genreId: string, page: number = 1, limit: number = 10): Promise<{ songs: Song[]; total: number }> {
    const [songs, total] = await this.songRepository.findAndCount({
      where: { genreId, status: SongStatus.PUBLISHED },
      relations: ['artist', 'album', 'genre'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { songs, total };
  }

  async searchSongs(query: string, page: number = 1, limit: number = 10): Promise<{ songs: Song[]; total: number }> {
    const [songs, total] = await this.songRepository
      .createQueryBuilder('song')
      .leftJoinAndSelect('song.artist', 'artist')
      .leftJoinAndSelect('song.album', 'album')
      .leftJoinAndSelect('song.genre', 'genre')
      .where('song.status = :status', { status: SongStatus.PUBLISHED })
      .andWhere('(song.title ILIKE :query OR artist.stageName ILIKE :query)', { query: `%${query}%` })
      .skip((page - 1) * limit)
      .take(limit)
      .orderBy('song.createdAt', 'DESC')
      .getManyAndCount();

    return { songs, total };
  }

  async incrementStreams(songId: string): Promise<void> {
    await this.songRepository.increment({ id: songId }, 'totalStreams', 1);
  }

  async likeSong(songId: string, userId: string): Promise<void> {
    // Implementar lógica de likes
    await this.songRepository.increment({ id: songId }, 'totalLikes', 1);
  }

  async unlikeSong(songId: string, userId: string): Promise<void> {
    // Implementar lógica de unlikes
    await this.songRepository.decrement({ id: songId }, 'totalLikes', 1);
  }
}









