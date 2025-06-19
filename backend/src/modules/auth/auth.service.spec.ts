import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { Usuario, TipoUsuario } from '../usuario/entities/usuario.entity';
import { Cliente } from '../cliente/entities/cliente.entity';
import { Empleado } from '../empleado/entities/empleado.entity';
import { Micro } from '../micro/entities/micro.entity';
import * as bcrypt from 'bcrypt';

describe('AuthService', () => {
  let service: AuthService;
  let mockUsuarioRepository: any;
  let mockClienteRepository: any;
  let mockEmpleadoRepository: any;
  let mockMicroRepository: any;
  let mockJwtService: any;

  beforeEach(async () => {
    mockUsuarioRepository = {
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
    };

    mockClienteRepository = {
      create: jest.fn(),
      save: jest.fn(),
    };

    mockEmpleadoRepository = {
      create: jest.fn(),
      save: jest.fn(),
    };

    mockMicroRepository = {};

    mockJwtService = {
      signAsync: jest.fn(),
      sign: jest.fn(),
      verify: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: getRepositoryToken(Usuario), useValue: mockUsuarioRepository },
        { provide: getRepositoryToken(Cliente), useValue: mockClienteRepository },
        { provide: getRepositoryToken(Empleado), useValue: mockEmpleadoRepository },
        { provide: getRepositoryToken(Micro), useValue: mockMicroRepository },
        { provide: JwtService, useValue: mockJwtService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('signIn', () => {
    const signInDto = {
      correo: 'test@example.com',
      contrasena: 'password123',
    };

    it('should sign in successfully for a client', async () => {
      const hashedPassword = await bcrypt.hash('password123', 10);
      const mockUser = {
        id: 'USR001',
        nombre: 'Test User',
        correo: 'test@example.com',
        contrasena: hashedPassword,
        tipo: TipoUsuario.CLIENTE,
        activo: true,
        ultimoLogin: null,
        cliente: {
          id: 'CLI_USR001',
          walletAddress: '0x123',
          registros: [],
          notificaciones: [],
          tarjetas: [],
        },
      };

      mockUsuarioRepository.findOne.mockResolvedValue(mockUser);
      mockUsuarioRepository.save.mockResolvedValue(mockUser);
      mockJwtService.signAsync.mockResolvedValue('jwt-token');

      const result = await service.signIn(signInDto);

      expect(result.success).toBe(true);
      expect(result.data.tipo).toBe(TipoUsuario.CLIENTE);
      expect(result.data.cliente).toBeDefined();
      expect(mockUsuarioRepository.save).toHaveBeenCalled();
    });

    it('should throw UnauthorizedException for invalid credentials', async () => {
      mockUsuarioRepository.findOne.mockResolvedValue(null);

      await expect(service.signIn(signInDto)).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException for wrong password', async () => {
      const mockUser = {
        id: 'USR001',
        correo: 'test@example.com',
        contrasena: await bcrypt.hash('wrongpassword', 10),
        activo: true,
      };

      mockUsuarioRepository.findOne.mockResolvedValue(mockUser);

      await expect(service.signIn(signInDto)).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('signUp', () => {
    const signUpDto = {
      id: 'USR001',
      nombre: 'Test User',
      correo: 'test@example.com',
      contrasena: 'password123',
      tipo: TipoUsuario.CLIENTE,
      walletAddress: '0x123',
    };

    it('should register a new client successfully', async () => {
      mockUsuarioRepository.findOne.mockResolvedValue(null);
      mockUsuarioRepository.create.mockReturnValue(signUpDto);
      mockUsuarioRepository.save.mockResolvedValue({ ...signUpDto, id: 'USR001' });
      mockClienteRepository.create.mockReturnValue({});
      mockClienteRepository.save.mockResolvedValue({});

      const result = await service.signUp(signUpDto);

      expect(result.success).toBe(true);
      expect(result.data.correo).toBe(signUpDto.correo);
      expect(mockUsuarioRepository.save).toHaveBeenCalled();
      expect(mockClienteRepository.save).toHaveBeenCalled();
    });

    it('should throw ConflictException for existing email', async () => {
      mockUsuarioRepository.findOne.mockResolvedValue({ id: 'existing' });

      await expect(service.signUp(signUpDto)).rejects.toThrow(ConflictException);
    });
  });

  describe('validateToken', () => {
    it('should validate token successfully', async () => {
      const mockPayload = { sub: 'USR001', correo: 'test@example.com' };
      mockJwtService.verify.mockReturnValue(mockPayload);

      const result = await service.validateToken('valid-token');

      expect(result).toEqual(mockPayload);
    });

    it('should return null for invalid token', async () => {
      mockJwtService.verify.mockImplementation(() => {
        throw new Error('Invalid token');
      });

      const result = await service.validateToken('invalid-token');

      expect(result).toBeNull();
    });
  });
}); 