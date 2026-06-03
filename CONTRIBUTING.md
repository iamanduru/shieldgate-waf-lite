# Contributing

## Branching Strategy

Use:

- `main` for stable code
- `develop` for active development
- `feature/*` for new features
- `fix/*` for bug fixes
- `security/*` for security work

## Before Opening a Pull Request

Run:

```bash
npm run typecheck
npm run build
npx prisma validate