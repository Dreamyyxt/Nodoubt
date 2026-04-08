import { Injectable } from "@nestjs/common";

@Injectable()
export class AppService {
  getHealth() {
    return {
      status: "ok",
      service: "app-server",
      timestamp: new Date().toISOString(),
    };
  }
}

