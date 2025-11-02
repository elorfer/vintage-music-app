import {
  Controller,
  Get,
  Query,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';

import { SongsService } from './songs.service';

@ApiTags('public-songs')
@Controller('public/songs')
export class PublicSongsController {
  constructor(private readonly songsService: SongsService) {}

  @Get('top')
  @ApiOperation({ summary: 'Obtener canciones más populares (público)' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Número de canciones a devolver' })
  @ApiResponse({ status: 200, description: 'Lista de canciones top obtenida exitosamente' })
  async getTopSongs(
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.songsService.getTopSongs(limit);
  }

  @Get()
  @ApiOperation({ summary: 'Obtener todas las canciones (público)' })
  @ApiQuery({ name: 'page', required: false, type: Number, description: 'Número de página' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Elementos por página' })
  @ApiResponse({ status: 200, description: 'Lista de canciones obtenida exitosamente' })
  async findAll(
    @Query('page', new ParseIntPipe({ optional: true })) page: number = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.songsService.findAll(page, limit);
  }
}

