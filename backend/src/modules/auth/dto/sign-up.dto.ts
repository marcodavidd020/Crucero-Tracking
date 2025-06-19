import { IsEmail, IsString, MinLength, IsEnum, IsOptional, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { TipoUsuario } from '../../usuario/entities/usuario.entity';

export class SignUpDto {
  @ApiProperty({
    description: 'ID único del usuario',
    example: 'USR001'
  })
  @IsString()
  @MaxLength(50)
  id: string;

  @ApiProperty({
    description: 'Nombre completo del usuario',
    example: 'Juan Pérez'
  })
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  nombre: string;

  @ApiProperty({
    description: 'Email del usuario',
    example: 'juan.perez@email.com'
  })
  @IsEmail()
  @MaxLength(200)
  correo: string;

  @ApiProperty({
    description: 'Contraseña del usuario',
    example: 'password123',
    minLength: 6
  })
  @IsString()
  @MinLength(6)
  @MaxLength(255)
  contrasena: string;

  @ApiProperty({
    description: 'Tipo de usuario',
    enum: TipoUsuario,
    example: TipoUsuario.CLIENTE
  })
  @IsOptional()
  @IsEnum(TipoUsuario)
  tipo?: TipoUsuario;

  // Datos adicionales para cliente
  @ApiProperty({
    description: 'Dirección de wallet para clientes',
    example: '0x1234567890abcdef',
    required: false
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  walletAddress?: string;

  // Datos adicionales para empleado
  @ApiProperty({
    description: 'ID de la entidad para empleados',
    example: 'ENT001',
    required: false
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  idEntidad?: string;

  @ApiProperty({
    description: 'ID del micro para choferes',
    example: 'MICRO001',
    required: false
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  idMicro?: string;

  @ApiProperty({
    description: 'Número de licencia para choferes',
    example: 'LIC123456',
    required: false
  })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  licencia?: string;
} 