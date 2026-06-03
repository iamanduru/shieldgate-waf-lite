# ShieldGate WAF Lite

ShieldGate WAF Lite is a lightweight backend Web Application Firewall designed to protect APIs and web applications through request inspection, risk scoring, logging, and rule-based decisions.

## Current Status

Sprint 1: Backend foundation

Completed:
- Node.js and TypeScript setup
- Fastify server
- Prisma and MySQL connection
- Health endpoint
- Readiness endpoint

## Local Development

Install dependencies:

```bash
npm install
```

Generate Prisma client:
```bash
npx prisma generate
```
Start server
```bash
npm run dev
```
Health check:
```bash
GET /healthz
```

Readiness check:
``` bash
GET /readyz
```

