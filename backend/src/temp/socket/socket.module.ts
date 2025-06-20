import { Module } from "@nestjs/common";
import { SocketGateway } from "./socket.gateway";
import { PrismaModule } from "src/prisma/prisma.module";
import { TrackingGateway } from "./tracking.gateway";


@Module({
    imports: [PrismaModule],
    providers: [SocketGateway, TrackingGateway],
    exports: [SocketGateway, TrackingGateway],
})
export class SocketModule {}