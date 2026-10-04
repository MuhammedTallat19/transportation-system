import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class GovernoratesService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    const data = await this.prisma.governorate.findMany({
      where: { is_active: true },
      orderBy: { name: 'asc' },
      select: { id: true, name: true, name_ar: true, is_active: true },
    });
    return { data: data.map((g) => ({ id: g.id, name: g.name, nameAr: g.name_ar, isActive: g.is_active })) };
  }
}
