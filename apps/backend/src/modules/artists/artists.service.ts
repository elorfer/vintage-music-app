import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Artist } from '../../common/entities/artist.entity';
import { User } from '../../common/entities/user.entity';
import { Song } from '../../common/entities/song.entity';
import { Album } from '../../common/entities/album.entity';

@Injectable()
export class ArtistsService {
  constructor(
    @InjectRepository(Artist)
    private readonly artistRepository: Repository<Artist>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Song)
    private readonly songRepository: Repository<Song>,
    @InjectRepository(Album)
    private readonly albumRepository: Repository<Album>,
  ) {}

  async findAll(page: number = 1, limit: number = 10): Promise<{ artists: Artist[]; total: number }> {
    const [artists, total] = await this.artistRepository.findAndCount({
      relations: ['user', 'songs', 'albums'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { artists, total };
  }

  async findOne(id: string): Promise<Artist> {
    const artist = await this.artistRepository.findOne({
      where: { id },
      relations: ['user', 'songs', 'albums'],
    });

    if (!artist) {
      throw new NotFoundException('Artista no encontrado');
    }

    return artist;
  }

  async findByUserId(userId: string): Promise<Artist> {
    const artist = await this.artistRepository.findOne({
      where: { userId },
      relations: ['user', 'songs', 'albums'],
    });

    if (!artist) {
      throw new NotFoundException('Artista no encontrado');
    }

    return artist;
  }

  async getArtistStats(artistId: string): Promise<any> {
    const artist = await this.findOne(artistId);
    
    const totalSongs = await this.songRepository.count({
      where: { artistId },
    });

    const totalAlbums = await this.albumRepository.count({
      where: { artistId },
    });

    const totalStreams = await this.songRepository
      .createQueryBuilder('song')
      .select('SUM(song.totalStreams)', 'total')
      .where('song.artistId = :artistId', { artistId })
      .getRawOne();

    return {
      artist,
      stats: {
        totalSongs,
        totalAlbums,
        totalStreams: parseInt(totalStreams.total) || 0,
        totalFollowers: artist.totalFollowers,
        monthlyListeners: artist.monthlyListeners,
      },
    };
  }

  async updateArtistProfile(artistId: string, updateData: any): Promise<Artist> {
    const artist = await this.findOne(artistId);
    
    Object.assign(artist, updateData);
    return this.artistRepository.save(artist);
  }

  async verifyArtist(artistId: string): Promise<Artist> {
    const artist = await this.findOne(artistId);
    artist.verificationStatus = true;
    return this.artistRepository.save(artist);
  }

  async getTopArtists(limit: number = 10): Promise<Artist[]> {
    return this.artistRepository.find({
      relations: ['user'],
      order: { totalStreams: 'DESC' },
      take: limit,
    });
  }

  async getVerifiedArtists(page: number = 1, limit: number = 10): Promise<{ artists: Artist[]; total: number }> {
    const [artists, total] = await this.artistRepository.findAndCount({
      where: { verificationStatus: true },
      relations: ['user'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { artists, total };
  }
}









