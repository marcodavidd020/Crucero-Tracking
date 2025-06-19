import { PartialType } from '@nestjs/swagger';
import { CreateMicroDto } from './create-micro.dto';

export class UpdateMicroDto extends PartialType(CreateMicroDto) {} 