import { Controller, Post, Body, HttpCode, HttpStatus, Get, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { SignInDto } from './dto/sign-in.dto';
import { SignUpDto } from './dto/sign-up.dto';

@ApiTags('Autenticación')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('sign-in')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Iniciar sesión' })
  @ApiBody({ type: SignInDto })
  @ApiResponse({
    status: 200,
    description: 'Login exitoso',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
        message: { type: 'string', example: 'Login exitoso' },
        data: {
          type: 'object',
          properties: {
            id: { type: 'string', example: 'USR001' },
            nombre: { type: 'string', example: 'Juan Pérez' },
            correo: { type: 'string', example: 'juan.perez@email.com' },
            tipo: { type: 'string', example: 'CLIENTE' },
            token: { type: 'string', example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' },
            cliente: {
              type: 'object',
              properties: {
                id: { type: 'string', example: 'CLI_USR001' },
                wallet_address: { type: 'string', example: '0x1234567890abcdef' },
                registros: { type: 'array', items: { type: 'object' } },
                notificaciones: { type: 'array', items: { type: 'object' } },
                tarjetas: { type: 'array', items: { type: 'object' } },
              },
            },
            empleado: {
              type: 'object',
              properties: {
                id: { type: 'string', example: 'EMP_USR001' },
                tipo: { type: 'string', example: 'CHOFER' },
                id_entidad: { type: 'string', example: 'ENT001' },
                id_micro: { type: 'string', example: 'MICRO001' },
                micros: { type: 'array', items: { type: 'object' } },
              },
            },
          },
        },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Credenciales inválidas',
  })
  async signIn(@Body() signInDto: SignInDto) {
    return await this.authService.signIn(signInDto);
  }

  @Post('sign-up')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Registrar usuario' })
  @ApiBody({ type: SignUpDto })
  @ApiResponse({
    status: 201,
    description: 'Usuario registrado exitosamente',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
        message: { type: 'string', example: 'Usuario registrado exitosamente' },
        data: {
          type: 'object',
          properties: {
            id: { type: 'string', example: 'USR001' },
            nombre: { type: 'string', example: 'Juan Pérez' },
            correo: { type: 'string', example: 'juan.perez@email.com' },
            tipo: { type: 'string', example: 'CLIENTE' },
          },
        },
      },
    },
  })
  @ApiResponse({
    status: 409,
    description: 'El email ya está registrado',
  })
  async signUp(@Body() signUpDto: SignUpDto) {
    return await this.authService.signUp(signUpDto);
  }

  @Get('empleado/:id/ruta')
  async getEmpleadoRuta(@Param('id') empleadoId: string) {
    return this.authService.getEmpleadoRuta(empleadoId);
  }
} 