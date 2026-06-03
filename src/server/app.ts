import Fastify, { type FastifyError } from "fastify";
import type { FastifyServerOptions } from "fastify";
import helmet from "@fastify/helmet";
import cors from "@fastify/cors";
import crypto from "node:crypto";

import { env, isProduction } from "../config/env.js";
import { checkDatabaseConnection } from "../db/prisma.js";

function createRequestId(): string {
  return `waf_${crypto.randomUUID()}`;
}

function getSecurityHeadersConfig() {
  return {
    global: true,
    contentSecurityPolicy: false,
    hidePoweredBy: true,
    frameguard: {
      action: "deny" as const,
    },
    noSniff: true,
    xssFilter: true,
    referrerPolicy: {
      policy: "no-referrer" as const,
    },
  };
}

function getErrorStatusCode(error: FastifyError): number {
  if (typeof error.statusCode === "number" && error.statusCode >= 400) {
    return error.statusCode;
  }

  return 500;
}

function getLoggerRedactionConfig() {
  return {
    paths: [
      "req.headers.authorization",
      "req.headers.cookie",
      "req.headers['set-cookie']",
      "headers.authorization",
      "headers.cookie",
      "headers['set-cookie']",
      "*.password",
      "*.token",
      "*.access_token",
      "*.refresh_token",
      "*.api_key",
      "*.secret",
    ],
    censor: "[REDACTED]",
  };
}

function getFastifyLoggerOptions(): NonNullable<FastifyServerOptions["logger"]> {
  if (isProduction) {
    return {
      level: env.LOG_LEVEL,
      redact: getLoggerRedactionConfig(),
    };
  }

  return {
    level: env.LOG_LEVEL,
    redact: getLoggerRedactionConfig(),
    transport: {
      target: "pino-pretty",
      options: {
        colorize: true,
        translateTime: "SYS:standard",
        ignore: "pid,hostname",
      },
    },
  };
}

export async function buildApp() {
  const app = Fastify({
    logger: getFastifyLoggerOptions(),
    trustProxy: false,
    requestIdHeader: "x-request-id",
    requestIdLogLabel: "request_id",

    genReqId: (request) => {
      const incomingRequestId = request.headers["x-request-id"];

      if (
        typeof incomingRequestId === "string" &&
        incomingRequestId.length <= 100
      ) {
        return incomingRequestId;
      }

      return createRequestId();
    },

    bodyLimit: 64 * 1024,
    connectionTimeout: 10_000,
    keepAliveTimeout: 5_000,
    requestTimeout: 15_000,

    ajv: {
      customOptions: {
        removeAdditional: false,
        coerceTypes: false,
        allErrors: false,
      },
    },
  });

  await app.register(helmet, getSecurityHeadersConfig());

  await app.register(cors, {
    origin: isProduction ? false : env.CORS_ORIGIN,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["content-type", "authorization", "x-request-id"],
    exposedHeaders: ["x-request-id"],
    credentials: false,
    maxAge: 300,
  });

  app.addHook("onRequest", async (request, reply) => {
    reply.header("x-request-id", request.id);
    reply.header("cache-control", "no-store");
  });

  app.setErrorHandler((error: FastifyError, request, reply) => {
    request.log.error(
      {
        err: error,
        request_id: request.id,
        method: request.method,
        url: request.url,
      },
      "Unhandled request error"
    );

    const statusCode = getErrorStatusCode(error);

    return reply.status(statusCode).send({
      error: statusCode >= 500 ? "internal_server_error" : "request_error",
      message:
        statusCode >= 500
          ? "The request could not be processed."
          : error.message,
      request_id: request.id,
    });
  });

  app.setNotFoundHandler((request, reply) => {
    return reply.status(404).send({
      error: "not_found",
      message: "The requested resource was not found.",
      request_id: request.id,
    });
  });

  app.get("/healthz", async (_request, reply) => {
    return reply.status(200).send({
      status: "ok",
      service: env.APP_NAME,
      environment: env.APP_ENV,
    });
  });

  app.get("/readyz", async (request, reply) => {
    const databaseOk = await checkDatabaseConnection();

    if (!databaseOk) {
      request.log.warn(
        {
          request_id: request.id,
          database: "unavailable",
        },
        "Readiness check failed"
      );

      return reply.status(503).send({
        status: "not_ready",
        database: "unavailable",
        rules: "not_loaded_yet",
        request_id: request.id,
      });
    }

    return reply.status(200).send({
      status: "ready",
      database: "ok",
      rules: "not_loaded_yet",
      request_id: request.id,
    });
  });

  app.get("/", async (_request, reply) => {
    return reply.status(200).send({
      service: env.APP_NAME,
      status: "running",
      mode: env.DEFAULT_MODE,
    });
  });

  return app;
}