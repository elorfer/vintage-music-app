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
  BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';

import { FeaturedService } from './featured.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User } from '../../common/entities/user.entity';

@ApiTags('featured')
@Controller('featured')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class FeaturedController {
  constructor(private readonly featuredService: FeaturedService) {}

  @Get('songs')
  @ApiOperation({ summary: 'Obtener canciones destacadas' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Número de canciones a devolver (1-100)' })
  @ApiResponse({ status: 200, description: 'Lista de canciones destacadas' })
  @ApiResponse({ status: 400, description: 'Límite inválido' })
  async getFeaturedSongs(
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    if (limit < 1 || limit > 100) {
      throw new BadRequestException('El límite debe estar entre 1 y 100');
    }
    return this.featuredService.getFeaturedSongs(limit);
  }

  @Get('artists')
  @ApiOperation({ summary: 'Obtener artistas destacados' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Número de artistas a devolver (1-100)' })
  @ApiResponse({ status: 200, description: 'Lista de artistas destacados' })
  @ApiResponse({ status: 400, description: 'Límite inválido' })
  async getFeaturedArtists(
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    if (limit < 1 || limit > 100) {
      throw new BadRequestException('El límite debe estar entre 1 y 100');
    }
    return this.featuredService.getFeaturedArtists(limit);
  }

  @Get('playlists')
  @ApiOperation({ summary: 'Obtener playlists destacadas' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Número de playlists a devolver (1-100)' })
  @ApiResponse({ status: 200, description: 'Lista de playlists destacadas' })
  @ApiResponse({ status: 400, description: 'Límite inválido' })
  async getFeaturedPlaylists(
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    if (limit < 1 || limit > 100) {
      throw new BadRequestException('El límite debe estar entre 1 y 100');
    }
    return this.featuredService.getFeaturedPlaylists(limit);
  }

  @Post('songs/:id/feature')
  @ApiOperation({ summary: 'Destacar una canción' })
  @ApiResponse({ status: 200, description: 'Canción destacada exitosamente' })
  @ApiResponse({ status: 404, description: 'Canción no encontrada' })
  async featureSong(@Param('id') id: string) {
    return this.featuredService.setSongFeatured(id, true);
  }

  @Delete('songs/:id/feature')
  @ApiOperation({ summary: 'Quitar destacado de una canción' })
  @ApiResponse({ status: 200, description: 'Canción ya no está destacada' })
  @ApiResponse({ status: 404, description: 'Canción no encontrada' })
  async unfeatureSong(@Param('id') id: string) {
    return this.featuredService.setSongFeatured(id, false);
  }

  @Post('artists/:id/feature')
  @ApiOperation({ summary: 'Destacar un artista' })
  @ApiResponse({ status: 200, description: 'Artista destacado exitosamente' })
  @ApiResponse({ status: 404, description: 'Artista no encontrado' })
  async featureArtist(@Param('id') id: string) {
    return this.featuredService.setArtistFeatured(id, true);
  }

  @Delete('artists/:id/feature')
  @ApiOperation({ summary: 'Quitar destacado de un artista' })
  @ApiResponse({ status: 200, description: 'Artista ya no está destacado' })
  @ApiResponse({ status: 404, description: 'Artista no encontrado' })
  async unfeatureArtist(@Param('id') id: string) {
    return this.featuredService.setArtistFeatured(id, false);
  }

  @Post('playlists/:id/feature')
  @ApiOperation({ summary: 'Destacar una playlist' })
  @ApiResponse({ status: 200, description: 'Playlist destacada exitosamente' })
  @ApiResponse({ status: 404, description: 'Playlist no encontrada' })
  async featurePlaylist(@Param('id') id: string) {
    return this.featuredService.setPlaylistFeatured(id, true);
  }

  @Delete('playlists/:id/feature')
  @ApiOperation({ summary: 'Quitar destacado de una playlist' })
  @ApiResponse({ status: 200, description: 'Playlist ya no está destacada' })
  @ApiResponse({ status: 404, description: 'Playlist no encontrada' })
  async unfeaturePlaylist(@Param('id') id: string) {
    return this.featuredService.setPlaylistFeatured(id, false);
  }
}

