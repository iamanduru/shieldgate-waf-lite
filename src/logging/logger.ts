import pino, { type LoggerOptions } from "pino";
import { env, isDevelopment } from "../config/env.js";

const loggerOptions: LoggerOptions = {
  level: env.LOG_LEVEL,
  redact: {
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
  },
};

if (isDevelopment) {
  loggerOptions.transport = {
    target: "pino-pretty",
    options: {
      colorize: true,
      translateTime: "SYS:standard",
      ignore: "pid,hostname",
    },
  };
}

export const logger = pino(loggerOptions);