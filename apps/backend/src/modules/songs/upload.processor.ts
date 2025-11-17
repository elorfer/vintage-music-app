import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Logger } from '@nestjs/common';

import { UploadProcessorService, ProcessUploadData } from './upload-processor.service';

/**
 * Worker de BullMQ que procesa uploads de canciones en background
 */
@Processor('song-upload')
export class UploadProcessor {
  private readonly logger = new Logger(UploadProcessor.name);

  constructor(private readonly uploadProcessorService: UploadProcessorService) {}

  @Process('process-song-upload')
  async handleProcessUpload(job: Job<ProcessUploadData>) {
    const startTime = Date.now();
    const { uploadId, title } = job.data;

    this.logger.log(`🔄 Procesando job ${job.id} para upload ${uploadId}: "${title}"`);

    try {
      // Actualizar progreso del job
      await job.progress(10);

      // Procesar upload
      const song = await this.uploadProcessorService.processUpload(job.data);

      await job.progress(100);

      const elapsed = Date.now() - startTime;
      this.logger.log(`✅ Job ${job.id} completado en ${elapsed}ms`);
      this.logger.log(`🎵 Canción creada: ${song.id} - "${song.title}"`);

      return {
        success: true,
        songId: song.id,
        uploadId,
        elapsed,
      };
    } catch (error) {
      const elapsed = Date.now() - startTime;
      this.logger.error(`❌ Job ${job.id} falló después de ${elapsed}ms: ${error.message}`);

      // Re-lanzar error para que BullMQ lo maneje (reintentos)
      throw error;
    }
  }
}



