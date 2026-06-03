USE waf;

SET @tenant_id = UUID();
SET @config_id = UUID();

INSERT INTO tenants (
  id,
  name,
  slug,
  status
)
VALUES (
  @tenant_id,
  'Default Tenant',
  'default',
  'active'
);

INSERT INTO configs (
  id,
  tenant_id,
  mode,
  paranoia_level,
  blocking_threshold,
  body_inspection_limit_bytes,
  rate_limiting_enabled,
  trusted_proxies,
  active_rule_bundle_version
)
VALUES (
  @config_id,
  @tenant_id,
  'protection',
  1,
  8,
  65536,
  TRUE,
  JSON_ARRAY(),
  '1.0.0'
);