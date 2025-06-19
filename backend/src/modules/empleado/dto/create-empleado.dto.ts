import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsEmail, IsEnum, IsUUID, ValidateNested, IsOptional } from 'class-validator';
import { Type } from 'class-transformer';

class EmpleadoDataDto {
  @ApiProperty({
    description: 'Tipo de empleado',
    example: 'CHOFER',
    enum: ['CHOFER', 'ADMIN'],
  })
  @IsEnum(['CHOFER', 'ADMIN'])
  @IsNotEmpty()
  tipo: string;

  @ApiProperty({
    description: 'ID de la entidad operadora',
    example: 'e85c0f3d-5a5a-4b4b-9c1d-97e23e5a7c9b',
  })
  @IsUUID()
  @IsNotEmpty()
  id_entidad: string;
}

export class CreateEmpleadoDto {
  @ApiProperty({
    description: 'Nombre completo del empleado',
    example: 'María López',
  })
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @ApiProperty({
    description: 'Correo electrónico del empleado',
    example: 'maria.lopez@municipalidad.gob.bo',
  })
  @IsEmail()
  @IsNotEmpty()
  correo: string;

  @ApiProperty({
    description: 'Contraseña del empleado',
    example: 'Xyz789012!',
  })
  @IsString()
  @IsNotEmpty()
  contrasena: string;

  @ApiProperty({
    description: 'Tipo de usuario',
    example: 'EMPLEADO',
    enum: ['EMPLEADO', 'CLIENTE'],
  })
  @IsEnum(['EMPLEADO', 'CLIENTE'])
  @IsNotEmpty()
  tipo: string;

  @ApiProperty({
    description: 'Datos específicos del empleado',
    type: EmpleadoDataDto,
  })
  @ValidateNested()
  @Type(() => EmpleadoDataDto)
  @IsNotEmpty()
  empleado: EmpleadoDataDto;
} 