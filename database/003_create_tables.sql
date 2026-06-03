USE waf;

CREATE TABLE IF NOT EXISTS tenants (
  id CHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  status ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS configs (
  id CHAR(36) PRIMARY KEY,
  tenant_id CHAR(36) NOT NULL,
  mode ENUM('protection', 'monitor', 'simulation', 'emergency_lockdown') NOT NULL DEFAULT 'protection',
  paranoia_level INT NOT NULL DEFAULT 1,
  blocking_threshold INT NOT NULL DEFAULT 8,
  body_inspection_limit_bytes INT NOT NULL DEFAULT 65536,
  rate_limiting_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  trusted_proxies JSON NULL,
  active_rule_bundle_version VARCHAR(50) DEFAULT '1.0.0',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_configs_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(id)
    ON DELETE CASCADE,

  CONSTRAINT chk_configs_paranoia_level
    CHECK (paranoia_level BETWEEN 1 AND 4),

  CONSTRAINT chk_configs_blocking_threshold
    CHECK (blocking_threshold BETWEEN 1 AND 100)
);

CREATE TABLE IF NOT EXISTS rules (
  id VARCHAR(100) PRIMARY KEY,
  category ENUM('sqli', 'xss', 'path_traversal', 'headers', 'bot', 'protocol', 'rate_limit') NOT NULL,
  description TEXT NOT NULL,
  severity ENUM('info', 'low', 'medium', 'high', 'critical') NOT NULL,
  paranoia_level INT NOT NULL DEFAULT 1,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  current_version VARCHAR(50) NOT NULL DEFAULT '1.0.0',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT chk_rules_paranoia_level
    CHECK (paranoia_level BETWEEN 1 AND 4)
);

CREATE TABLE IF NOT EXISTS rule_versions (
  id CHAR(36) PRIMARY KEY,
  rule_id VARCHAR(100) NOT NULL,
  version VARCHAR(50) NOT NULL,
  definition JSON NOT NULL,
  created_by VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_rule_versions_rule
    FOREIGN KEY (rule_id) REFERENCES rules(id)
    ON DELETE CASCADE,

  UNIQUE KEY unique_rule_version (rule_id, version)
);

CREATE TABLE IF NOT EXISTS decisions (
  id CHAR(36) PRIMARY KEY,
  request_id VARCHAR(100) NOT NULL,
  tenant_id CHAR(36) NOT NULL,
  mode ENUM('protection', 'monitor', 'simulation', 'emergency_lockdown') NOT NULL,
  decision ENUM('allow', 'block', 'rate_limit', 'monitor', 'simulate') NOT NULL,
  status_code INT NULL,
  anomaly_score INT NOT NULL DEFAULT 0,
  matched_rule_ids JSON NULL,
  config_version VARCHAR(50) NULL,
  rule_bundle_version VARCHAR(50) NULL,
  method VARCHAR(20) NULL,
  path VARCHAR(2048) NULL,
  client_ip_hash VARCHAR(255) NULL,
  user_agent_hash VARCHAR(255) NULL,
  duration_ms DECIMAL(10, 3) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_decisions_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(id)
    ON DELETE CASCADE,

  INDEX idx_decisions_request_id (request_id),
  INDEX idx_decisions_tenant_created (tenant_id, created_at),
  INDEX idx_decisions_decision (decision),
  INDEX idx_decisions_score (anomaly_score)
);

CREATE TABLE IF NOT EXISTS events (
  id CHAR(36) PRIMARY KEY,
  request_id VARCHAR(100) NOT NULL,
  tenant_id CHAR(36) NOT NULL,
  event_type VARCHAR(100) NOT NULL,
  category VARCHAR(100) NULL,
  severity VARCHAR(50) NULL,
  sanitized_data JSON NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_events_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(id)
    ON DELETE CASCADE,

  INDEX idx_events_request_id (request_id),
  INDEX idx_events_tenant_created (tenant_id, created_at),
  INDEX idx_events_category (category),
  INDEX idx_events_severity (severity)
);

CREATE TABLE IF NOT EXISTS allowlists (
  id CHAR(36) PRIMARY KEY,
  tenant_id CHAR(36) NOT NULL,
  description TEXT NOT NULL,
  scope JSON NOT NULL,
  suppressed_rules JSON NOT NULL,
  reason TEXT NOT NULL,
  approved_by VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_allowlists_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(id)
    ON DELETE CASCADE,

  INDEX idx_allowlists_tenant (tenant_id),
  INDEX idx_allowlists_expires (expires_at)
);

CREATE TABLE IF NOT EXISTS denylists (
  id CHAR(36) PRIMARY KEY,
  tenant_id CHAR(36) NOT NULL,
  deny_type ENUM('ip', 'ip_hash', 'user_agent_hash', 'path', 'header', 'country', 'asn') NOT NULL,
  deny_value VARCHAR(500) NOT NULL,
  reason TEXT NOT NULL,
  action ENUM('block', 'rate_limit') NOT NULL DEFAULT 'block',
  expires_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_denylists_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(id)
    ON DELETE CASCADE,

  INDEX idx_denylists_tenant_type (tenant_id, deny_type),
  INDEX idx_denylists_expires (expires_at)
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id CHAR(36) PRIMARY KEY,
  tenant_id CHAR(36) NULL,
  actor_id VARCHAR(255) NOT NULL,
  action VARCHAR(100) NOT NULL,
  resource_type VARCHAR(100) NOT NULL,
  resource_id VARCHAR(255) NOT NULL,
  before_value JSON NULL,
  after_value JSON NULL,
  request_id VARCHAR(100) NOT NULL,
  source_ip_hash VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_audit_tenant_created (tenant_id, created_at),
  INDEX idx_audit_actor (actor_id),
  INDEX idx_audit_action (action)
);

CREATE TABLE IF NOT EXISTS admin_users (
  id CHAR(36) PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('viewer', 'security_analyst', 'rule_admin', 'tenant_admin', 'security_admin', 'auditor') NOT NULL DEFAULT 'viewer',
  status ENUM('active', 'inactive', 'locked') NOT NULL DEFAULT 'active',
  last_login_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS rate_limit_counters (
  id CHAR(36) PRIMARY KEY,
  tenant_id CHAR(36) NOT NULL,
  rate_key VARCHAR(255) NOT NULL,
  tokens DECIMAL(10, 3) NOT NULL DEFAULT 0,
  last_refill_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,

  CONSTRAINT fk_rate_limit_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(id)
    ON DELETE CASCADE,

  UNIQUE KEY unique_rate_key (tenant_id, rate_key),
  INDEX idx_rate_limit_expires (expires_at)
);