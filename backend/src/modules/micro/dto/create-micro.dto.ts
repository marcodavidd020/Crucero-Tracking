import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsBoolean, IsUUID, IsOptional } from 'class-validator';

export class CreateMicroDto {
  @ApiProperty({
    description: 'Placa del micro',
    example: 'ABC123',
  })
  @IsString()
  @IsNotEmpty()
  placa: string;

  @ApiProperty({
    description: 'Color del micro (código hexadecimal)',
    example: '#FFFF',
  })
  @IsString()
  @IsNotEmpty()
  color: string;

  @ApiProperty({
    description: 'Estado del micro',
    example: true,
  })
  @IsBoolean()
  estado: boolean;

  @ApiProperty({
    description: 'ID de la entidad operadora',
    example: '3876ab94-5ab8-4597-aa7d-6eb550568735',
  })
  @IsUUID()
  @IsNotEmpty()
  id_entidad: string;

  @ApiPropertyOptional({
    description: 'ID del empleado asignado al micro',
    example: 'ca156529-71f0-4e61-937f-60d1a11f157d',
  })
  @IsOptional()
  @IsUUID()
  id_empleado?: string;
} 