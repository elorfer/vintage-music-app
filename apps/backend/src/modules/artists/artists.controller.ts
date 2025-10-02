import {
  Controller,
  Get,
  Patch,
  Param,
  Body,
  UseGuards,
  Query,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';

import { ArtistsService } from './artists.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User, UserRole } from '../../common/entities/user.entity';

@ApiTags('artists')
@Controller('artists')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ArtistsController {
  constructor(private readonly artistsService: ArtistsService) {}

  @Get()
  @ApiOperation({ summary: 'Obtener todos los artistas' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Lista de artistas obtenida exitosamente' })
  async findAll(
    @Query('page', new ParseIntPipe({ optional: true })) page: number = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.artistsService.findAll(page, limit);
  }

  @Get('top')
  @ApiOperation({ summary: 'Obtener artistas más populares' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Lista de artistas top' })
  async getTopArtists(
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.artistsService.getTopArtists(limit);
  }

  @Get('verified')
  @ApiOperation({ summary: 'Obtener artistas verificados' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Lista de artistas verificados' })
  async getVerifiedArtists(
    @Query('page', new ParseIntPipe({ optional: true })) page: number = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number = 10,
  ) {
    return this.artistsService.getVerifiedArtists(page, limit);
  }

  @Get('profile')
  @Roles(UserRole.ARTIST)
  @UseGuards(RolesGuard)
  @ApiOperation({ summary: 'Obtener perfil del artista autenticado' })
  @ApiResponse({ status: 200, description: 'Perfil del artista' })
  async getMyProfile(@CurrentUser() user: User) {
    return this.artistsService.findByUserId(user.id);
  }

  @Get('profile/stats')
  @Roles(UserRole.ARTIST)
  @UseGuards(RolesGuard)
  @ApiOperation({ summary: 'Obtener estadísticas del artista autenticado' })
  @ApiResponse({ status: 200, description: 'Estadísticas del artista' })
  async getMyStats(@CurrentUser() user: User) {
    const artist = await this.artistsService.findByUserId(user.id);
    return this.artistsService.getArtistStats(artist.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener artista por ID' })
  @ApiResponse({ status: 200, description: 'Artista encontrado' })
  @ApiResponse({ status: 404, description: 'Artista no encontrado' })
  async findOne(@Param('id') id: string) {
    return this.artistsService.findOne(id);
  }

  @Get(':id/stats')
  @ApiOperation({ summary: 'Obtener estadísticas de un artista' })
  @ApiResponse({ status: 200, description: 'Estadísticas del artista' })
  @ApiResponse({ status: 404, description: 'Artista no encontrado' })
  async getArtistStats(@Param('id') id: string) {
    return this.artistsService.getArtistStats(id);
  }

  @Patch('profile')
  @Roles(UserRole.ARTIST)
  @UseGuards(RolesGuard)
  @ApiOperation({ summary: 'Actualizar perfil del artista autenticado' })
  @ApiResponse({ status: 200, description: 'Perfil actualizado exitosamente' })
  async updateMyProfile(
    @CurrentUser() user: User,
    @Body() updateData: any,
  ) {
    const artist = await this.artistsService.findByUserId(user.id);
    return this.artistsService.updateArtistProfile(artist.id, updateData);
  }

  @Patch(':id/verify')
  @Roles(UserRole.ADMIN)
  @UseGuards(RolesGuard)
  @ApiOperation({ summary: 'Verificar artista (Solo Admin)' })
  @ApiResponse({ status: 200, description: 'Artista verificado exitosamente' })
  @ApiResponse({ status: 404, description: 'Artista no encontrado' })
  async verifyArtist(@Param('id') id: string) {
    return this.artistsService.verifyArtist(id);
  }
}









