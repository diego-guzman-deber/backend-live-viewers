import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello() {
    return {
      status: 'success',
      message: '🚀 Backend de Live Views corriendo exitosamente en Dokploy!',
      timestamp: new Date().toISOString()
    };
  }
}
