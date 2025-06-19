import { PartialType } from '@nestjs/swagger';
import { CreateEntidadOperadoraDto } from './create-entidad-operadora.dto';

export class UpdateEntidadOperadoraDto extends PartialType(CreateEntidadOperadoraDto) {} 