USE waf;

DELIMITER //

CREATE PROCEDURE record_waf_decision (
  IN p_id CHAR(36),
  IN p_request_id VARCHAR(100),
  IN p_tenant_id CHAR(36),
  IN p_mode VARCHAR(50),
  IN p_decision VARCHAR(50),
  IN p_status_code INT,
  IN p_anomaly_score INT,
  IN p_matched_rule_ids JSON,
  IN p_config_version VARCHAR(50),
  IN p_rule_bundle_version VARCHAR(50),
  IN p_method VARCHAR(20),
  IN p_path VARCHAR(2048),
  IN p_client_ip_hash VARCHAR(255),
  IN p_user_agent_hash VARCHAR(255),
  IN p_duration_ms DECIMAL(10, 3)
)
BEGIN
  INSERT INTO decisions (
    id,
    request_id,
    tenant_id,
    mode,
    decision,
    status_code,
    anomaly_score,
    matched_rule_ids,
    config_version,
    rule_bundle_version,
    method,
    path,
    client_ip_hash,
    user_agent_hash,
    duration_ms
  )
  VALUES (
    p_id,
    p_request_id,
    p_tenant_id,
    p_mode,
    p_decision,
    p_status_code,
    p_anomaly_score,
    p_matched_rule_ids,
    p_config_version,
    p_rule_bundle_version,
    p_method,
    p_path,
    p_client_ip_hash,
    p_user_agent_hash,
    p_duration_ms
  );
END //

CREATE PROCEDURE record_security_event (
  IN p_id CHAR(36),
  IN p_request_id VARCHAR(100),
  IN p_tenant_id CHAR(36),
  IN p_event_type VARCHAR(100),
  IN p_category VARCHAR(100),
  IN p_severity VARCHAR(50),
  IN p_sanitized_data JSON
)
BEGIN
  INSERT INTO events (
    id,
    request_id,
    tenant_id,
    event_type,
    category,
    severity,
    sanitized_data
  )
  VALUES (
    p_id,
    p_request_id,
    p_tenant_id,
    p_event_type,
    p_category,
    p_severity,
    p_sanitized_data
  );
END //

CREATE PROCEDURE record_audit_log (
  IN p_id CHAR(36),
  IN p_tenant_id CHAR(36),
  IN p_actor_id VARCHAR(255),
  IN p_action VARCHAR(100),
  IN p_resource_type VARCHAR(100),
  IN p_resource_id VARCHAR(255),
  IN p_before_value JSON,
  IN p_after_value JSON,
  IN p_request_id VARCHAR(100),
  IN p_source_ip_hash VARCHAR(255)
)
BEGIN
  INSERT INTO audit_logs (
    id,
    tenant_id,
    actor_id,
    action,
    resource_type,
    resource_id,
    before_value,
    after_value,
    request_id,
    source_ip_hash
  )
  VALUES (
    p_id,
    p_tenant_id,
    p_actor_id,
    p_action,
    p_resource_type,
    p_resource_id,
    p_before_value,
    p_after_value,
    p_request_id,
    p_source_ip_hash
  );
END //

CREATE PROCEDURE get_security_summary (
  IN p_tenant_id CHAR(36),
  IN p_from TIMESTAMP,
  IN p_to TIMESTAMP
)
BEGIN
  SELECT
    COUNT(*) AS total_requests,
    SUM(CASE WHEN decision = 'allow' THEN 1 ELSE 0 END) AS allowed_requests,
    SUM(CASE WHEN decision = 'block' THEN 1 ELSE 0 END) AS blocked_requests,
    SUM(CASE WHEN decision = 'rate_limit' THEN 1 ELSE 0 END) AS rate_limited_requests,
    AVG(anomaly_score) AS average_anomaly_score,
    MAX(anomaly_score) AS highest_anomaly_score
  FROM decisions
  WHERE tenant_id = p_tenant_id
    AND created_at BETWEEN p_from AND p_to;
END //

CREATE PROCEDURE cleanup_expired_security_data ()
BEGIN
  DELETE FROM allowlists
  WHERE expires_at IS NOT NULL
    AND expires_at < CURRENT_TIMESTAMP;

  DELETE FROM denylists
  WHERE expires_at IS NOT NULL
    AND expires_at < CURRENT_TIMESTAMP;

  DELETE FROM rate_limit_counters
  WHERE expires_at < CURRENT_TIMESTAMP;
END //

DELIMITER ;