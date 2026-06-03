import { buildApp } from "./app.js";
import { env } from "../config/env.js";
import { logger } from "../logging/logger.js";
import { closeDatabaseConnection } from "../db/prisma.js";

async function startServer(): Promise<void> {
  const app = await buildApp();

  const shutdown = async (signal: NodeJS.Signals) => {
    logger.info({ signal }, "Shutdown signal received");

    try {
      await app.close();
      await closeDatabaseConnection();

      logger.info("Server shutdown completed");
      process.exit(0);
    } catch (error) {
      logger.error({ error }, "Server shutdown failed");
      process.exit(1);
    }
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);

  process.on("unhandledRejection", (reason) => {
    logger.fatal({ reason }, "Unhandled promise rejection");
    process.exit(1);
  });

  process.on("uncaughtException", (error) => {
    logger.fatal({ error }, "Uncaught exception");
    process.exit(1);
  });

  try {
    await app.listen({
      host: env.HOST,
      port: env.PORT,
    });

    logger.info(
      {
        service: env.APP_NAME,
        environment: env.APP_ENV,
        host: env.HOST,
        port: env.PORT,
      },
      "WAF Lite server started"
    );
  } catch (error) {
    logger.fatal({ error }, "Failed to start server");
    process.exit(1);
  }
}

await startServer();