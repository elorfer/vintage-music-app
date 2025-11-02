import {
  Controller,
  Get,
  Query,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';

import { ArtistsService } from './artists.service';

@ApiTags('public-artists')
@Controller('public/artists')
export class PublicArtistsController {
  constructor(private readonly artistsService: ArtistsService) {}

  @Get('top')
  @ApiOperation({ summary: 'Obtener artistas más populares (público)' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Número de artistas a devolver' })
  @ApiResponse({ status: 200, description: 'Lista de artistas top obtenida exitosamente' })
  async getTopArtists(
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.artistsService.getTopArtists(limit);
  }

  @Get()
  @ApiOperation({ summary: 'Obtener todos los artistas (público)' })
  @ApiQuery({ name: 'page', required: false, type: Number, description: 'Número de página' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Elementos por página' })
  @ApiResponse({ status: 200, description: 'Lista de artistas obtenida exitosamente' })
  async findAll(
    @Query('page', new ParseIntPipe({ optional: true })) page: number = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.artistsService.findAll(page, limit);
  }
}

