import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class PaginationDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  pageSize?: number = 20;
}

export function paginate<T>(items: T[], page: number, pageSize: number, total?: number) {
  return {
    data: items,
    page,
    pageSize,
    total: total ?? items.length,
  };
}
