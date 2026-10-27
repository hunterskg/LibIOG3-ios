import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Gate } from '../../domain/entities/gate.entity';
import { Device } from '../../domain/entities/device.entity';
import { GateStatus } from '../../domain/enums/gate-status.enum';
import { DeviceStatus } from '../../domain/enums/device-status.enum';
import { CreateGateReq, GateRes, UpdateGateReq } from '../../domain/dtos/gate.dto';

@Injectable()
export class GateService {
  constructor(
    @InjectRepository(Gate) private readonly gateRepo: Repository<Gate>,
    @InjectRepository(Device) private readonly deviceRepo: Repository<Device>,
  ) {}

  async create(req: CreateGateReq): Promise<GateRes> {
    const code = req.code.trim();
    const exists = await this.gateRepo.findOne({ where: { code } });
    if (exists) throw new ConflictException('Gate code already exists');
    return GateRes.of(await this.gateRepo.save(this.gateRepo.create({ ...req, code })));
  }

  async list(): Promise<GateRes[]> {
    return (await this.gateRepo.find({ order: { createdAt: 'DESC' } })).map(GateRes.of);
  }

  async listStaff(gateId: string) {
    const gate = await this.gateRepo.findOne({ where: { id: gateId } });
    if (!gate) throw new NotFoundException('Gate not found');
    const devices = await this.deviceRepo.find({
      where: { gateId, status: DeviceStatus.ACTIVE },
      relations: { staff: true },
      order: { assignedAt: 'DESC' },
    });
    return devices.map(({ staffId, staff }) => ({
      staffId,
      name: staff.fullName,
      email: staff.email,
    }));
  }

  async get(id: string): Promise<GateRes> {
    const gate = await this.gateRepo.findOne({ where: { id } });
    if (!gate) throw new NotFoundException('Gate not found');
    return GateRes.of(gate);
  }

  async update(id: string, req: UpdateGateReq): Promise<GateRes> {
    const gate = await this.gateRepo.findOne({ where: { id } });
    if (!gate) throw new NotFoundException('Gate not found');
    Object.assign(gate, req);
    return GateRes.of(await this.gateRepo.save(gate));
  }

  async remove(id: string): Promise<void> {
    const gate = await this.gateRepo.findOne({ where: { id } });
    if (!gate) throw new NotFoundException('Gate not found');
    await this.gateRepo.manager.transaction(async (manager) => {
      await manager.update(Device, { gateId: id }, { gateId: null });
      await manager.remove(Gate, gate);
    });
  }

}
