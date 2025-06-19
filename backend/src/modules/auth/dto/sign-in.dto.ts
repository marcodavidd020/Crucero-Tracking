import { IsEmail, IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class SignInDto {
  @ApiProperty({
    description: 'Email del usuario',
    example: 'juan.perez@email.com'
  })
  @IsEmail()
  correo: string;

  @ApiProperty({
    description: 'Contraseña del usuario',
    example: 'password123',
    minLength: 6
  })
  @IsString()
  @MinLength(6)
  contrasena: string;
} 