import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z
    .enum(["development", "test", "staging", "production"])
    .default("development"),

  PORT: z.coerce.number().int().min(1).max(65535).default(8080),

  HOST: z.string().min(1).default("127.0.0.1"),

  APP_NAME: z.string().min(1).default("ShieldGate WAF Lite"),

  APP_ENV: z.string().min(1).default("development"),

  DATABASE_URL: z
    .string()
    .min(1, "DATABASE_URL is required")
    .refine((value) => value.startsWith("mysql://"), {
      message: "DATABASE_URL must use mysql://",
    })
    .refine((value) => !value.includes("root:"), {
      message: "DATABASE_URL must not use the MySQL root user",
    }),

  DEFAULT_MODE: z
    .enum(["protection", "monitor", "simulation", "emergency_lockdown"])
    .default("protection"),

  DEFAULT_PARANOIA_LEVEL: z.coerce.number().int().min(1).max(4).default(1),

  DEFAULT_BLOCKING_THRESHOLD: z.coerce.number().int().min(1).max(100).default(8),

  LOG_LEVEL: z
    .enum(["fatal", "error", "warn", "info", "debug", "trace", "silent"])
    .default("info"),

  CORS_ORIGIN: z.string().min(1).default("http://localhost:3000"),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  const issues = parsed.error.issues.map((issue) => ({
    path: issue.path.join("."),
    message: issue.message,
  }));

  console.error("Invalid environment configuration:", JSON.stringify(issues, null, 2));
  process.exit(1);
}

export const env = Object.freeze(parsed.data);

export const isProduction = env.NODE_ENV === "production";
export const isDevelopment = env.NODE_ENV === "development";