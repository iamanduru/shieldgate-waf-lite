import { PrismaClient } from "@prisma/client";
import { logger } from "../logging/logger.js";

const globalForPrisma = globalThis as unknown as {
  prisma?: PrismaClient;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: ["error", "warn"],
  });

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}

export async function checkDatabaseConnection(): Promise<boolean> {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return true;
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown database error";

    logger.error({ message }, "Database health check failed");
    return false;
  }
}

export async function closeDatabaseConnection(): Promise<void> {
  await prisma.$disconnect();
}