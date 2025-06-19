import { PartialType } from '@nestjs/mapped-types';
import { CreateRutaDto } from './create-ruta.dto';
 
export class UpdateRutaDto extends PartialType(CreateRutaDto) {} 