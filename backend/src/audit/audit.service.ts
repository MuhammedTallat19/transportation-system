import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface AuditLogParams {
  actorUserId?: string;
  action: string;
  entityType: string;
  entityId?: string;
  beforeState?: unknown;
  afterState?: unknown;
  ipAddress?: string;
}

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async log(params: AuditLogParams) {
    return this.prisma.auditLog.create({
      data: {
        actor_user_id: params.actorUserId,
        action: params.action,
        entity_type: params.entityType,
        entity_id: params.entityId,
        before_state: params.beforeState as object | undefined,
        after_state: params.afterState as object | undefined,
        ip_address: params.ipAddress,
      },
    });
  }

  async findMany(filters: {
    entityType?: string;
    entityId?: string;
    actorUserId?: string;
    page?: number;
    pageSize?: number;
  }) {
    const page = filters.page ?? 1;
    const pageSize = filters.pageSize ?? 20;
    const where = {
      ...(filters.entityType ? { entity_type: filters.entityType } : {}),
      ...(filters.entityId ? { entity_id: filters.entityId } : {}),
      ...(filters.actorUserId ? { actor_user_id: filters.actorUserId } : {}),
    };

    const [data, total] = await Promise.all([
      this.prisma.auditLog.findMany({
        where,
        orderBy: { created_at: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.auditLog.count({ where }),
    ]);

    return { data, page, pageSize, total };
  }
}
