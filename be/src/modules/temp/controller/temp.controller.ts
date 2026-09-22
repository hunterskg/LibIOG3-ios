import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { TempService } from '../services/temp.service';

@Controller('temp')
export class TempController {
  constructor(private readonly tempService: TempService) {}

  @Get()
  findAll() {
    return this.tempService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.tempService.findOne(id);
  }

  @Post()
  create(@Body('name') name: string) {
    return this.tempService.create(name);
  }
}
