import { Controller, Post, Delete, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { SeedersService } from './seeders.service';

@ApiTags('Seeders')
@Controller('seeders')
export class SeedersController {
  constructor(private readonly seedersService: SeedersService) {}

  @Post('run')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Ejecutar seeders para poblar la base de datos' })
  @ApiResponse({
    status: 200,
    description: 'Seeders ejecutados exitosamente',
  })
  async runSeeders() {
    await this.seedersService.seedAll();
    return {
      success: true,
      message: 'Seeders ejecutados exitosamente',
    };
  }

  @Delete('clear')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Limpiar toda la base de datos' })
  @ApiResponse({
    status: 200,
    description: 'Base de datos limpiada exitosamente',
  })
  async clearDatabase() {
    await this.seedersService.clearAll();
    return {
      success: true,
      message: 'Base de datos limpiada exitosamente',
    };
  }
} 