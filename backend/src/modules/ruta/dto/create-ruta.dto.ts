import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNumber, IsOptional, IsNotEmpty } from 'class-validator';

export class CreateRutaDto {
  @ApiProperty({
    description: 'Nombre de la ruta',
    example: 'Ruta B',
  })
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @ApiPropertyOptional({
    description: 'Descripción de la ruta',
    example: 'Ruta B de Santa Cruz',
  })
  @IsOptional()
  @IsString()
  descripcion?: string;

  @ApiProperty({
    description: 'Latitud del origen',
    example: '40.7127837',
  })
  @IsString()
  @IsNotEmpty()
  origenLat: string;

  @ApiProperty({
    description: 'Longitud del origen',
    example: '-74.0059413',
  })
  @IsString()
  @IsNotEmpty()
  origenLong: string;

  @ApiProperty({
    description: 'Latitud del destino',
    example: '40.7127837',
  })
  @IsString()
  @IsNotEmpty()
  destinoLat: string;

  @ApiProperty({
    description: 'Longitud del destino',
    example: '-74.0059413',
  })
  @IsString()
  @IsNotEmpty()
  destinoLong: string;

  @ApiProperty({
    description: 'Distancia de la ruta en metros',
    example: 100.0,
  })
  @IsNumber()
  distancia: number;

  @ApiProperty({
    description: 'Tiempo de la ruta en minutos',
    example: 5.5,
  })
  @IsNumber()
  tiempo: number;

  @ApiProperty({
    description: 'Vertices de la ruta (JSON string)',
    example: '12345678',
  })
  @IsString()
  @IsNotEmpty()
  vertices: string;

  @ApiPropertyOptional({
    description: 'ID de la entidad operadora (se pasa por parámetro de URL)',
    example: 'ba9a8fc5-8366-40ab-8d77-347448750acf',
  })
  @IsOptional()
  @IsString()
  id_entidad?: string;
} 