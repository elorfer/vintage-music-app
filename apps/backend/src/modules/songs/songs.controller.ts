import {
  Controller,
  Get,
  Post,
  Param,
  UseGuards,
  Query,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';

import { SongsService } from './songs.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User } from '../../common/entities/user.entity';

@ApiTags('songs')
@Controller('songs')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SongsController {
  constructor(private readonly songsService: SongsService) {}

  @Get()
  @ApiOperation({ summary: 'Obtener todas las canciones' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Lista de canciones obtenida exitosamente' })
  async findAll(
    @Query('page', new ParseIntPipe({ optional: true })) page: number = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.songsService.findAll(page, limit);
  }

  @Get('top')
  @ApiOperation({ summary: 'Obtener canciones más populares' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Lista de canciones top' })
  async getTopSongs(
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.songsService.getTopSongs(limit);
  }

  @Get('search')
  @ApiOperation({ summary: 'Buscar canciones' })
  @ApiQuery({ name: 'q', required: true, type: String, description: 'Término de búsqueda' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Resultados de búsqueda' })
  async searchSongs(
    @Query('q') query: string,
    @Query('page', new ParseIntPipe({ optional: true })) page: number = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.songsService.searchSongs(query, page, limit);
  }

  @Get('artist/:artistId')
  @ApiOperation({ summary: 'Obtener canciones de un artista' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Canciones del artista' })
  async findByArtist(
    @Param('artistId') artistId: string,
    @Query('page', new ParseIntPipe({ optional: true })) page: number = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.songsService.findByArtist(artistId, page, limit);
  }

  @Get('genre/:genreId')
  @ApiOperation({ summary: 'Obtener canciones por género' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Canciones del género' })
  async getSongsByGenre(
    @Param('genreId') genreId: string,
    @Query('page', new ParseIntPipe({ optional: true })) page: number = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.songsService.getSongsByGenre(genreId, page, limit);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener canción por ID' })
  @ApiResponse({ status: 200, description: 'Canción encontrada' })
  @ApiResponse({ status: 404, description: 'Canción no encontrada' })
  async findOne(@Param('id') id: string) {
    return this.songsService.findOne(id);
  }

  @Post(':id/stream')
  @ApiOperation({ summary: 'Registrar reproducción de canción' })
  @ApiResponse({ status: 200, description: 'Reproducción registrada' })
  async streamSong(
    @Param('id') id: string,
    @CurrentUser() user: User,
  ) {
    await this.songsService.incrementStreams(id);
    return { message: 'Reproducción registrada' };
  }

  @Post(':id/like')
  @ApiOperation({ summary: 'Dar like a una canción' })
  @ApiResponse({ status: 200, description: 'Like registrado' })
  async likeSong(
    @Param('id') id: string,
    @CurrentUser() user: User,
  ) {
    await this.songsService.likeSong(id, user.id);
    return { message: 'Like registrado' };
  }

  @Post(':id/unlike')
  @ApiOperation({ summary: 'Quitar like de una canción' })
  @ApiResponse({ status: 200, description: 'Like removido' })
  async unlikeSong(
    @Param('id') id: string,
    @CurrentUser() user: User,
  ) {
    await this.songsService.unlikeSong(id, user.id);
    return { message: 'Like removido' };
  }
}









