import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsEmail, IsOptional } from 'class-validator';

export class CreateEntidadOperadoraDto {
  @ApiProperty({
    description: 'Nombre de la entidad operadora',
    example: 'Crucero del Sur',
  })
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @ApiProperty({
    description: 'NIT de la entidad operadora',
    example: '1234567891',
  })
  @IsString()
  @IsNotEmpty()
  nit: string;

  @ApiPropertyOptional({
    description: 'Dirección física de la entidad',
    example: 'Av. Alemana 123, Santa Cruz de la Sierra, Bolivia',
  })
  @IsOptional()
  @IsString()
  direccion?: string;

  @ApiPropertyOptional({
    description: 'Teléfono de contacto',
    example: '3-123-4567',
  })
  @IsOptional()
  @IsString()
  telefono?: string;

  @ApiPropertyOptional({
    description: 'Email de contacto de la entidad',
    example: 'contacto@crucero.bo',
  })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({
    description: 'Nombre del representante legal',
    example: 'Juan Carlos Perez',
  })
  @IsOptional()
  @IsString()
  representante?: string;
} 