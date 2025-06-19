import { Injectable, UnauthorizedException, ConflictException, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { Usuario, TipoUsuario } from '../usuario/entities/usuario.entity';
import { Cliente } from '../cliente/entities/cliente.entity';
import { Empleado, TipoEmpleado } from '../empleado/entities/empleado.entity';
import { Micro } from '../micro/entities/micro.entity';
import { SignInDto } from './dto/sign-in.dto';
import { SignUpDto } from './dto/sign-up.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly jwtService: JwtService,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    @InjectRepository(Cliente)
    private readonly clienteRepository: Repository<Cliente>,
    @InjectRepository(Empleado)
    private readonly empleadoRepository: Repository<Empleado>,
    @InjectRepository(Micro)
    private readonly microRepository: Repository<Micro>,
  ) {}

  async signIn(signInDto: SignInDto) {
    const usuario = await this.usuarioRepository.findOne({
      where: { correo: signInDto.correo, activo: true },
      relations: ['cliente', 'empleado', 'empleado.micro', 'empleado.entidad'],
    });

    if (!usuario) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    const isPasswordValid = await bcrypt.compare(signInDto.contrasena, usuario.contrasena);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    // Actualizar último login
    usuario.ultimoLogin = new Date();
    await this.usuarioRepository.save(usuario);

    // Generar token
    const payload = { 
      sub: usuario.id, 
      correo: usuario.correo, 
      tipo: usuario.tipo 
    };
    const token = await this.jwtService.signAsync(payload);

    // Preparar respuesta según el tipo de usuario
    const userResponse: any = {
      id: usuario.id,
      nombre: usuario.nombre,
      correo: usuario.correo,
      tipo: usuario.tipo,
      token,
    };

    if (usuario.tipo === TipoUsuario.CLIENTE && usuario.cliente) {
      userResponse.cliente = {
        id: usuario.cliente.id,
        wallet_address: usuario.cliente.walletAddress,
        registros: usuario.cliente.registros || [],
        notificaciones: usuario.cliente.notificaciones || [],
        tarjetas: usuario.cliente.tarjetas || [],
      };
    }

    if (usuario.tipo === TipoUsuario.EMPLEADO && usuario.empleado) {
      const micros = usuario.empleado.micro ? [{
        id: usuario.empleado.micro.id,
        placa: usuario.empleado.micro.placa,
        modelo: usuario.empleado.micro.modelo,
      }] : [];

      userResponse.empleado = {
        id: usuario.empleado.id,
        tipo: usuario.empleado.tipo,
        id_entidad: usuario.empleado.idEntidad,
        id_micro: usuario.empleado.idMicro,
        micros,
      };
    }

    return {
      success: true,
      message: 'Login exitoso',
      data: userResponse,
    };
  }

  async signUp(signUpDto: SignUpDto) {
    // Verificar si el usuario ya existe
    const existingUser = await this.usuarioRepository.findOne({
      where: { correo: signUpDto.correo },
    });

    if (existingUser) {
      throw new ConflictException('El email ya está registrado');
    }

    // Hash de la contraseña
    const hashedPassword = await bcrypt.hash(signUpDto.contrasena, 10);

    // Crear usuario
    const usuario = this.usuarioRepository.create({
      id: signUpDto.id,
      nombre: signUpDto.nombre,
      correo: signUpDto.correo,
      contrasena: hashedPassword,
      tipo: signUpDto.tipo || TipoUsuario.CLIENTE,
    });

    const savedUser = await this.usuarioRepository.save(usuario);

    // Crear perfil específico según el tipo
    if (savedUser.tipo === TipoUsuario.CLIENTE) {
      const cliente = this.clienteRepository.create({
        id: `CLI_${savedUser.id}`,
        userId: savedUser.id,
        walletAddress: signUpDto.walletAddress,
        registros: [],
        notificaciones: [],
        tarjetas: [],
        saldo: 0,
      });
      await this.clienteRepository.save(cliente);
    }

    if (savedUser.tipo === TipoUsuario.EMPLEADO) {
      if (!signUpDto.idEntidad) {
        throw new ConflictException('ID de entidad es requerido para empleados');
      }

      const empleado = this.empleadoRepository.create({
        id: `EMP_${savedUser.id}`,
        userId: savedUser.id,
        tipo: signUpDto.idMicro ? TipoEmpleado.CHOFER : TipoEmpleado.ADMIN,
        idEntidad: signUpDto.idEntidad,
        idMicro: signUpDto.idMicro,
        licencia: signUpDto.licencia,
        fechaContratacion: new Date(),
        activo: true,
      });
      await this.empleadoRepository.save(empleado);
    }

    return {
      success: true,
      message: 'Usuario registrado exitosamente',
      data: {
        id: savedUser.id,
        nombre: savedUser.nombre,
        correo: savedUser.correo,
        tipo: savedUser.tipo,
      },
    };
  }

  async validateToken(token: string): Promise<any> {
    try {
      return this.jwtService.verify(token);
    } catch (error) {
      return null;
    }
  }

  async generateMicroToken(microId: string): Promise<string> {
    return this.jwtService.sign({ 
      microId, 
      type: 'micro',
      iat: Math.floor(Date.now() / 1000) 
    });
  }

  async validateMicroToken(token: string): Promise<{ microId: string } | null> {
    const payload = await this.validateToken(token);
    if (payload && payload.type === 'micro' && payload.microId) {
      return { microId: payload.microId };
    }
    return null;
  }

  async findUserById(id: string): Promise<Usuario> {
    const usuario = await this.usuarioRepository.findOne({
      where: { id, activo: true },
      relations: ['cliente', 'empleado', 'empleado.micro', 'empleado.entidad'],
    });

    if (!usuario) {
      throw new NotFoundException('Usuario no encontrado');
    }

    return usuario;
  }

  async getEmpleadoRuta(empleadoId: string): Promise<any> {
    const empleado = await this.empleadoRepository.findOne({
      where: { id: empleadoId },
      relations: ['entidad', 'micro'],
    });

    if (!empleado) {
      throw new NotFoundException('Empleado no encontrado');
    }

    // Por ahora, asignar la primera ruta de la entidad
    // En el futuro, esto debería ser una relación directa
    const query = `
      SELECT r.* FROM rutas r 
      WHERE r.id_entidad = $1 
      ORDER BY r.created_at ASC 
      LIMIT 1
    `;
    
    const result = await this.usuarioRepository.query(query, [empleado.idEntidad]);
    
    return {
      empleado: {
        id: empleado.id,
        tipo: empleado.tipo,
        id_entidad: empleado.idEntidad,
        id_micro: empleado.idMicro,
        micro: empleado.micro,
      },
      ruta: result[0] || null,
    };
  }
} 