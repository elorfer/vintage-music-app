import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';

import { Song, SongStatus } from '../../common/entities/song.entity';
import { SongUpload, UploadStatus } from '../../common/entities/song-upload.entity';
import { Artist } from '../../common/entities/artist.entity';
import { Album } from '../../common/entities/album.entity';
import { Genre } from '../../common/entities/genre.entity';
import { LocalStorageService } from './local-storage.service';
import { CoversStorageService } from '../covers/covers-storage.service';
import { AudioMetadataService } from '../../common/services/audio-metadata.service';
import { CompensationService } from './compensation.service';

export interface ProcessUploadData {
  uploadId: string;
  audioFileKey: string;
  coverFileKey?: string;
  title: string;
  artistId: string;
  albumId?: string;
  genreId?: string;
  status?: 'draft' | 'pending' | 'published' | 'rejected';
  duration?: number;
  userId: string;
}

/**
 * Servicio que procesa el upload de canción en background
 * Extrae metadatos, valida datos y crea el registro final
 */
@Injectable()
export class UploadProcessorService {
  private readonly logger = new Logger(UploadProcessorService.name);
  private readonly isDevelopment = process.env.NODE_ENV !== 'production';

  constructor(
    @InjectRepository(SongUpload)
    private readonly uploadRepository: Repository<SongUpload>,
    @InjectRepository(Song)
    private readonly songRepository: Repository<Song>,
    @InjectRepository(Artist)
    private readonly artistRepository: Repository<Artist>,
    @InjectRepository(Album)
    private readonly albumRepository: Repository<Album>,
    @InjectRepository(Genre)
    private readonly genreRepository: Repository<Genre>,
    private readonly localStorageService: LocalStorageService,
    private readonly coversStorageService: CoversStorageService,
    private readonly audioMetadataService: AudioMetadataService,
    private readonly compensationService: CompensationService,
    private readonly dataSource: DataSource,
  ) {}

  /**
   * Procesa el upload completo
   * 1. Lee archivos desde storage
   * 2. Extrae metadatos del audio
   * 3. Valida entidades relacionadas
   * 4. Crea registro de canción
   * 5. Actualiza estado del upload
   */
  async processUpload(data: ProcessUploadData): Promise<Song> {
    const startTime = Date.now();
    this.logger.log('═══════════════════════════════════════════════════════════');
    this.logger.log('⚙️ PROCESANDO UPLOAD DE CANCIÓN');
    this.logger.log(`🆔 Upload ID: ${data.uploadId}`);
    this.logger.log(`📝 Título: ${data.title}`);
    this.logger.log('═══════════════════════════════════════════════════════════');

    // Obtener registro de upload
    const uploadRecord = await this.uploadRepository.findOne({
      where: { uploadId: data.uploadId },
    });

    if (!uploadRecord) {
      throw new NotFoundException(`Upload no encontrado: ${data.uploadId}`);
    }

    // Si ya está completado, retornar la canción existente
    if (uploadRecord.status === UploadStatus.COMPLETED && uploadRecord.songId) {
      const existingSong = await this.songRepository.findOne({
        where: { id: uploadRecord.songId },
      });
      if (existingSong) {
        this.logger.log(`♻️ Upload ya completado, retornando canción existente`);
        return existingSong;
      }
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Paso 1: Leer archivos desde storage
      this.logger.log('📂 Leyendo archivos desde storage...');
      const audioBuffer = await this.readFileFromStorage(data.audioFileKey, 'audio');
      let coverBuffer: Buffer | undefined;
      if (data.coverFileKey) {
        coverBuffer = await this.readFileFromStorage(data.coverFileKey, 'cover');
      }

      // Paso 2: Extraer metadatos del audio (proceso pesado)
      this.logger.log('🔍 Extrayendo metadatos del audio...');
      const metadata = await this.audioMetadataService.extractMetadata(
        audioBuffer,
        'audio/mpeg', // Asumimos MP3, se puede mejorar detectando el tipo real
      );

      this.logger.log(`✅ Metadatos extraídos:`);
      this.logger.log(`   - Duración: ${metadata.duration}s (${Math.floor(metadata.duration / 60)}:${(metadata.duration % 60).toString().padStart(2, '0')})`);
      if (metadata.codec) {
        this.logger.log(`   - Codec: ${metadata.codec}`);
      }
      if (metadata.bitrate) {
        this.logger.log(`   - Bitrate: ${metadata.bitrate} bps`);
      }

      // Usar duración extraída si está disponible, sino usar la proporcionada o 0
      const finalDuration = metadata.duration > 0 
        ? metadata.duration 
        : (data.duration ?? 0);

      if (finalDuration <= 0) {
        this.logger.warn(`⚠️ ADVERTENCIA: La duración es 0`);
      }

      // Paso 3: Validar entidades relacionadas (dentro de transacción)
      this.logger.log('🔍 Validando entidades relacionadas...');
      
      const artist = await queryRunner.manager.findOne(Artist, {
        where: { id: data.artistId },
      });

      if (!artist) {
        throw new NotFoundException('Artista no encontrado');
      }
      this.logger.log(`✅ Artista validado: ${artist.stageName || artist.id}`);

      if (data.albumId) {
        const album = await queryRunner.manager.findOne(Album, {
          where: { id: data.albumId },
        });

        if (!album) {
          throw new NotFoundException('Álbum no encontrado');
        }
        this.logger.log(`✅ Álbum validado: ${album.title}`);
      }

      if (data.genreId) {
        const genre = await queryRunner.manager.findOne(Genre, {
          where: { id: data.genreId },
        });

        if (!genre) {
          throw new NotFoundException('Género no encontrado');
        }
        this.logger.log(`✅ Género validado: ${genre.name}`);
      }

      // Paso 4: Obtener URLs de archivos (ya están subidos)
      const audioUrl = this.localStorageService.getPublicUrl(data.audioFileKey);
      const coverUrl = data.coverFileKey
        ? this.coversStorageService.getPublicUrl(data.coverFileKey)
        : undefined;

      // Paso 5: Crear registro de canción (dentro de transacción)
      this.logger.log('💾 Creando registro de canción...');
      const song = queryRunner.manager.create(Song, {
        title: data.title,
        fileUrl: audioUrl,
        coverArtUrl: coverUrl,
        artistId: data.artistId,
        albumId: data.albumId,
        genreId: data.genreId,
        status: data.status === 'pending' || data.status === 'published' 
          ? SongStatus.PUBLISHED 
          : data.status === 'draft' 
          ? SongStatus.DRAFT 
          : SongStatus.DRAFT,
        duration: finalDuration,
        totalStreams: 0,
        totalLikes: 0,
      });

      const savedSong = await queryRunner.manager.save(Song, song);
      this.logger.log(`✅ Canción creada: ${savedSong.id}`);

      // Paso 6: Actualizar registro de upload (dentro de transacción)
      await queryRunner.manager.update(
        SongUpload,
        { id: uploadRecord.id },
        {
          status: UploadStatus.COMPLETED,
          songId: savedSong.id,
          metadata: {
            duration: metadata.duration,
            bitrate: metadata.bitrate,
            codec: metadata.codec,
            sampleRate: metadata.sampleRate,
            channels: metadata.channels,
            format: metadata.format,
            title: metadata.title,
            artist: metadata.artist,
            album: metadata.album,
          },
        },
      );

      // Commit de la transacción
      await queryRunner.commitTransaction();

      const elapsed = Date.now() - startTime;
      this.logger.log(`✅ Procesamiento completado en ${elapsed}ms`);
      this.logger.log(`🎉 Canción "${savedSong.title}" creada exitosamente`);
      this.logger.log('═══════════════════════════════════════════════════════════');

      return savedSong;
    } catch (error) {
      this.logger.error(`❌ Error al procesar upload: ${error.message}`);
      
      // Rollback de la transacción
      await queryRunner.rollbackTransaction();

      // Actualizar registro con error
      await this.uploadRepository.update(
        { uploadId: data.uploadId },
        {
          status: UploadStatus.FAILED,
          error: error.message,
        },
      );

      // Aplicar compensación: limpiar archivos
      await this.compensationService.cleanupFiles({
        audioFileKey: data.audioFileKey,
        coverFileKey: data.coverFileKey,
      });

      // Marcar compensación aplicada
      await this.uploadRepository.update(
        { uploadId: data.uploadId },
        { compensationApplied: true },
      );

      // Re-lanzar el error
      if (error instanceof BadRequestException || error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException(`Error al procesar upload: ${error.message}`);
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Lee un archivo desde storage
   */
  private async readFileFromStorage(
    fileKey: string,
    type: 'audio' | 'cover',
  ): Promise<Buffer> {
    // Por ahora, asumimos que los archivos están en local storage
    // En producción, esto debería leer desde S3 o el storage configurado
    const fs = require('fs');
    const path = require('path');
    
    const uploadsDir = path.join(process.cwd(), 'uploads');
    const filePath = path.join(uploadsDir, fileKey);

    if (!fs.existsSync(filePath)) {
      throw new NotFoundException(`Archivo no encontrado: ${fileKey}`);
    }

    return fs.readFileSync(filePath);
  }
}



