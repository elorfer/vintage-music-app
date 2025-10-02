import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  Query,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';

import { PlaylistsService } from './playlists.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User } from '../../common/entities/user.entity';

@ApiTags('playlists')
@Controller('playlists')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class PlaylistsController {
  constructor(private readonly playlistsService: PlaylistsService) {}

  @Get()
  @ApiOperation({ summary: 'Obtener todas las playlists públicas' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Lista de playlists obtenida exitosamente' })
  async findAll(
    @Query('page', new ParseIntPipe({ optional: true })) page: number = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.playlistsService.findAll(page, limit);
  }

  @Get('featured')
  @ApiOperation({ summary: 'Obtener playlists destacadas' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Lista de playlists destacadas' })
  async getFeaturedPlaylists(
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.playlistsService.getFeaturedPlaylists(limit);
  }

  @Get('my-playlists')
  @ApiOperation({ summary: 'Obtener mis playlists' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Mis playlists' })
  async getMyPlaylists(
    @CurrentUser() user: User,
    @Query('page', new ParseIntPipe({ optional: true })) page: number = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.playlistsService.findByUser(user.id, page, limit);
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Obtener playlists de un usuario' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Playlists del usuario' })
  async findByUser(
    @Param('userId') userId: string,
    @Query('page', new ParseIntPipe({ optional: true })) page: number = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.playlistsService.findByUser(userId, page, limit);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener playlist por ID' })
  @ApiResponse({ status: 200, description: 'Playlist encontrada' })
  @ApiResponse({ status: 404, description: 'Playlist no encontrada' })
  async findOne(@Param('id') id: string) {
    return this.playlistsService.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Crear nueva playlist' })
  @ApiResponse({ status: 201, description: 'Playlist creada exitosamente' })
  async createPlaylist(
    @Body() playlistData: any,
    @CurrentUser() user: User,
  ) {
    return this.playlistsService.createPlaylist(user.id, playlistData);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Actualizar playlist' })
  @ApiResponse({ status: 200, description: 'Playlist actualizada exitosamente' })
  @ApiResponse({ status: 403, description: 'No tienes permisos para editar esta playlist' })
  async updatePlaylist(
    @Param('id') id: string,
    @Body() updateData: any,
    @CurrentUser() user: User,
  ) {
    return this.playlistsService.updatePlaylist(id, user.id, updateData);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Eliminar playlist' })
  @ApiResponse({ status: 200, description: 'Playlist eliminada exitosamente' })
  @ApiResponse({ status: 403, description: 'No tienes permisos para eliminar esta playlist' })
  async deletePlaylist(
    @Param('id') id: string,
    @CurrentUser() user: User,
  ) {
    await this.playlistsService.deletePlaylist(id, user.id);
    return { message: 'Playlist eliminada exitosamente' };
  }

  @Post(':id/songs/:songId')
  @ApiOperation({ summary: 'Agregar canción a playlist' })
  @ApiResponse({ status: 200, description: 'Canción agregada exitosamente' })
  async addSongToPlaylist(
    @Param('id') playlistId: string,
    @Param('songId') songId: string,
    @CurrentUser() user: User,
  ) {
    await this.playlistsService.addSongToPlaylist(playlistId, songId, user.id);
    return { message: 'Canción agregada exitosamente' };
  }

  @Delete(':id/songs/:songId')
  @ApiOperation({ summary: 'Remover canción de playlist' })
  @ApiResponse({ status: 200, description: 'Canción removida exitosamente' })
  async removeSongFromPlaylist(
    @Param('id') playlistId: string,
    @Param('songId') songId: string,
    @CurrentUser() user: User,
  ) {
    await this.playlistsService.removeSongFromPlaylist(playlistId, songId, user.id);
    return { message: 'Canción removida exitosamente' };
  }
}









