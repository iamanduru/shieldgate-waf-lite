# Pull Request Summary

## What changed?

Describe the change clearly.

## Type of change

- [ ] Feature
- [ ] Bug fix
- [ ] Security hardening
- [ ] Refactor
- [ ] Documentation
- [ ] Test update
- [ ] Database change
- [ ] CI/CD change

## Security checklist

- [ ] No secrets or credentials committed
- [ ] No raw request bodies logged
- [ ] Sensitive fields are redacted
- [ ] Input validation added or preserved
- [ ] Auth/RBAC impact considered
- [ ] Database permissions remain least-privileged
- [ ] Error responses do not expose internals

## Testing

- [ ] I ran `npm run typecheck`
- [ ] I ran `npm run build`
- [ ] I ran `npx prisma validate`
- [ ] I tested affected endpoints locally

## Notes for reviewer

Add anything the reviewer should pay attention to.