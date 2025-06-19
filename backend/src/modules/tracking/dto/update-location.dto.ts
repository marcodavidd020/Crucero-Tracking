import { IsString, IsNumber, IsOptional, MaxLength, MinLength } from 'class-validator';

export class UpdateLocationDto {
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  id_micro: string;

  @IsNumber()
  latitud: number;

  @IsNumber()
  longitud: number;

  @IsOptional()
  @IsNumber()
  altura?: number;

  @IsOptional()
  @IsNumber()
  precision?: number;

  @IsOptional()
  @IsNumber()
  bateria?: number;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  imei?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  fuente?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  id_ruta?: string;
} 