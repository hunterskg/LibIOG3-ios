import { Type } from 'class-transformer';
import { IsInt, IsOptional, Min } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class PageReq {
  @ApiPropertyOptional({ example: 1, default: 1 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  page: number = 1;

  @ApiPropertyOptional({ example: 10, default: 10 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  size: number = 10;
}

export class Page<T> {
  data!: T[];
  total!: number;
  req!: PageReq;

  static of<T>(data: T[], total: number, req: PageReq): Page<T> {
    const page = new Page<T>();
    page.data = data;
    page.total = total;
    page.req = req;
    return page;
  }
}
