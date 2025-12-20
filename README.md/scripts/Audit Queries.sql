-- ========================================
-- AUDIT QUERIES
-- Mining Database - Audit Log Analysis & Compliance
-- ========================================

-- 1. All Audit Log Entries (Recent First)
SELECT audit_id, username, action, object_type, object_id,
       attempted_on, success_flag, message
FROM audit_log
ORDER BY attempted_on DESC;

-- 2. Failed Operations Analysis
SELECT username, action, object_type, 
       COUNT(*) AS failed_attempts,
       MAX(attempted_on) AS last_failed_attempt
FROM audit_log
WHERE success_flag = 'N'
GROUP BY username, action, object_type
ORDER BY failed_attempts DESC, last_failed_attempt DESC;

-- 3. Successful Operations by User
SELECT username, 
       COUNT(*) AS total_operations,
       COUNT(CASE WHEN action = 'INSERT' THEN 1 END) AS inserts,
       COUNT(CASE WHEN action = 'UPDATE' THEN 1 END) AS updates,
       COUNT(CASE WHEN action = 'DELETE' THEN 1 END) AS deletes,
       MIN(attempted_on) AS first_activity,
       MAX(attempted_on) AS last_activity
FROM audit_log
WHERE success_flag = 'Y'
GROUP BY username
ORDER BY total_operations DESC;

-- 4. Audit Trail by Object Type
SELECT object_type, action, success_flag,
       COUNT(*) AS operation_count,
       MIN(attempted_on) AS first_occurrence,
       MAX(attempted_on) AS last_occurrence
FROM audit_log
GROUP BY object_type, action, success_flag
ORDER BY object_type, operation_count DESC;

-- 5. Blocked Operations (Weekday/Holiday Restrictions)
SELECT username, action, object_type, object_id,
       attempted_on, TO_CHAR(attempted_on, 'Day') AS day_of_week,
       message
FROM audit_log
WHERE success_flag = 'N' 
  AND message LIKE '%Restricted%'
ORDER BY attempted_on DESC;

-- 6. Recent Activity Timeline (Last 7 Days)
SELECT TO_CHAR(attempted_on, 'YYYY-MM-DD') AS activity_date,
       username, action, object_type, success_flag,
       COUNT(*) AS operation_count
FROM audit_log
WHERE attempted_on >= TRUNC(SYSDATE) - 7
GROUP BY TO_CHAR(attempted_on, 'YYYY-MM-DD'), username, action, object_type, success_flag
ORDER BY activity_date DESC, operation_count DESC;

-- 7. Mine Site Changes Audit
SELECT a.audit_id, a.username, a.action, a.attempted_on,
       a.success_flag, a.message, m.site_name, m.location
FROM audit_log a
LEFT JOIN mine_site m ON a.object_id = TO_CHAR(m.site_id)
WHERE a.object_type = 'MINE_SITE'
ORDER BY a.attempted_on DESC;

-- 8. Worker Modifications Audit
SELECT a.audit_id, a.username, a.action, a.attempted_on,
       a.message, w.name AS worker_name, w.role, w.safety_status
FROM audit_log a
LEFT JOIN worker w ON a.object_id = TO_CHAR(w.worker_id)
WHERE a.object_type = 'WORKER'
ORDER BY a.attempted_on DESC;

-- 9. Safety Status Changes Audit
SELECT a.audit_id, a.username, a.attempted_on,
       a.message, w.worker_id, w.name, w.safety_status
FROM audit_log a
JOIN worker w ON a.object_id = TO_CHAR(w.worker_id)
WHERE a.action IN ('SAFETY_CLEAR', 'SAFETY_ESCALATION')
ORDER BY a.attempted_on DESC;

-- 10. Extraction Operations Audit
SELECT a.audit_id, a.username, a.action, a.attempted_on,
       a.message, e.extraction_id, e.date_extracted, 
       e.quantity_tons, e.revenue_calculated
FROM audit_log a
LEFT JOIN extraction e ON a.object_id = TO_CHAR(e.extraction_id)
WHERE a.object_type = 'EXTRACTION'
ORDER BY a.attempted_on DESC;

-- 11. Machinery Maintenance Alerts
SELECT a.audit_id, a.username, a.attempted_on, a.message,
       m.machine_id, m.machine_name, m.next_maintenance, m.status
FROM audit_log a
LEFT JOIN machinery m ON a.object_id = TO_CHAR(m.machine_id)
WHERE a.action = 'MAINT_OVERDUE'
ORDER BY a.attempted_on DESC;

-- 12. Mineral Price Changes Audit
SELECT a.audit_id, a.username, a.attempted_on, a.message,
       m.mineral_name, m.market_price, m.unit
FROM audit_log a
LEFT JOIN mineral m ON a.object_id = TO_CHAR(m.mineral_id)
WHERE a.object_type = 'MINERAL' AND a.action = 'UPDATE'
ORDER BY a.attempted_on DESC;

-- 13. Environment Conservation Activity Audit
SELECT a.audit_id, a.username, a.action, a.attempted_on,
       a.message, ec.activity_type, ec.impact_level,
       ms.site_name
FROM audit_log a
LEFT JOIN environment_conservation ec ON a.object_id = TO_CHAR(ec.conservation_id)
LEFT JOIN mine_site ms ON ec.site_id = ms.site_id
WHERE a.object_type = 'ENV_CONSERVATION'
ORDER BY a.attempted_on DESC;

-- 14. Holiday Management Audit
SELECT a.audit_id, a.username, a.action, a.attempted_on,
       a.object_id AS holiday_date, a.message
FROM audit_log a
WHERE a.object_type = 'HOLIDAY'
ORDER BY a.attempted_on DESC;

-- 15. User Activity Summary Report
SELECT username,
       COUNT(*) AS total_actions,
       COUNT(CASE WHEN success_flag = 'Y' THEN 1 END) AS successful,
       COUNT(CASE WHEN success_flag = 'N' THEN 1 END) AS failed,
       ROUND(COUNT(CASE WHEN success_flag = 'Y' THEN 1 END) * 100.0 / COUNT(*), 2) AS success_rate,
       MIN(attempted_on) AS first_action,
       MAX(attempted_on) AS last_action,
       COUNT(DISTINCT object_type) AS object_types_accessed
FROM audit_log
GROUP BY username
ORDER BY total_actions DESC;

-- 16. Daily Operations Audit Summary
SELECT TO_CHAR(attempted_on, 'YYYY-MM-DD') AS operation_date,
       COUNT(*) AS total_operations,
       COUNT(CASE WHEN success_flag = 'Y' THEN 1 END) AS successful_ops,
       COUNT(CASE WHEN success_flag = 'N' THEN 1 END) AS failed_ops,
       COUNT(DISTINCT username) AS active_users,
       COUNT(DISTINCT object_type) AS affected_objects
FROM audit_log
WHERE attempted_on >= TRUNC(SYSDATE) - 30
GROUP BY TO_CHAR(attempted_on, 'YYYY-MM-DD')
ORDER BY operation_date DESC;

-- 17. Object-Level Change History
SELECT object_type, object_id,
       COUNT(*) AS total_changes,
       COUNT(CASE WHEN action = 'INSERT' THEN 1 END) AS created,
       COUNT(CASE WHEN action = 'UPDATE' THEN 1 END) AS updated,
       COUNT(CASE WHEN action = 'DELETE' THEN 1 END) AS deleted,
       MIN(attempted_on) AS first_change,
       MAX(attempted_on) AS last_change,
       COUNT(DISTINCT username) AS users_involved
FROM audit_log
WHERE success_flag = 'Y'
GROUP BY object_type, object_id
HAVING COUNT(*) > 1
ORDER BY total_changes DESC;

-- 18. Security Compliance: Blocked Access Attempts
SELECT username, object_type, action,
       COUNT(*) AS blocked_attempts,
       MIN(attempted_on) AS first_attempt,
       MAX(attempted_on) AS last_attempt,
       LISTAGG(DISTINCT message, '; ') WITHIN GROUP (ORDER BY attempted_on) AS block_reasons
FROM audit_log
WHERE success_flag = 'N'
GROUP BY username, object_type, action
HAVING COUNT(*) >= 3
ORDER BY blocked_attempts DESC;

-- 19. Audit Trail for Specific Worker
-- Replace :worker_id with actual worker ID when running
SELECT a.audit_id, a.username, a.action, a.object_type,
       a.attempted_on, a.success_flag, a.message,
       w.name, w.role, w.safety_status
FROM audit_log a
JOIN worker w ON a.object_id = TO_CHAR(w.worker_id)
WHERE w.worker_id = :worker_id
  AND a.object_type = 'WORKER'
ORDER BY a.attempted_on DESC;

-- 20. Audit Trail for Specific Site
-- Replace :site_id with actual site ID when running
SELECT a.audit_id, a.username, a.action, a.object_type,
       a.attempted_on, a.success_flag, a.message,
       m.site_name, m.location, m.region
FROM audit_log a
JOIN mine_site m ON a.object_id = TO_CHAR(m.site_id)
WHERE m.site_id = :site_id
  AND a.object_type = 'MINE_SITE'
ORDER BY a.attempted_on DESC;

-- 21. Comprehensive Compliance Report
SELECT 
    TO_CHAR(attempted_on, 'YYYY-MM') AS month,
    object_type,
    COUNT(*) AS total_operations,
    COUNT(CASE WHEN success_flag = 'Y' THEN 1 END) AS successful,
    COUNT(CASE WHEN success_flag = 'N' THEN 1 END) AS blocked,
    ROUND(COUNT(CASE WHEN success_flag = 'N' THEN 1 END) * 100.0 / COUNT(*), 2) AS block_rate,
    COUNT(DISTINCT username) AS unique_users
FROM audit_log
WHERE attempted_on >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -6)
GROUP BY TO_CHAR(attempted_on, 'YYYY-MM'), object_type
ORDER BY month DESC, total_operations DESC;

-- 22. Peak Activity Hours Analysis
SELECT TO_CHAR(attempted_on, 'HH24') AS hour_of_day,
       COUNT(*) AS operation_count,
       COUNT(DISTINCT username) AS active_users,
       COUNT(CASE WHEN success_flag = 'N' THEN 1 END) AS failed_operations
FROM audit_log
WHERE attempted_on >= TRUNC(SYSDATE) - 30
GROUP BY TO_CHAR(attempted_on, 'HH24')
ORDER BY hour_of_day;

-- 23. Audit Log Integrity Check
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT audit_id) AS unique_audit_ids,
    MIN(attempted_on) AS earliest_record,
    MAX(attempted_on) AS latest_record,
    COUNT(CASE WHEN username IS NULL THEN 1 END) AS missing_username,
    COUNT(CASE WHEN action IS NULL THEN 1 END) AS missing_action,
    COUNT(CASE WHEN object_type IS NULL THEN 1 END) AS missing_object_type
FROM audit_log;

-- 24. Recent Safety-Related Audit Events
SELECT a.audit_id, a.username, a.action, a.attempted_on,
       a.message, w.name AS worker_name, w.safety_status,
       m.site_name
FROM audit_log a
LEFT JOIN worker w ON a.object_id = TO_CHAR(w.worker_id)
LEFT JOIN mine_site m ON w.assigned_site = m.site_id
WHERE (a.action IN ('SAFETY_CLEAR', 'SAFETY_ESCALATION')
   OR a.object_type = 'WORKER' AND a.message LIKE '%safety%')
ORDER BY a.attempted_on DESC;

-- 25. Suspicious Activity Detection
SELECT username, object_type,
       COUNT(*) AS rapid_operations,
       MIN(attempted_on) AS start_time,
       MAX(attempted_on) AS end_time,
       ROUND((MAX(attempted_on) - MIN(attempted_on)) * 24 * 60, 2) AS duration_minutes
FROM audit_log
WHERE attempted_on >= TRUNC(SYSDATE) - 1
GROUP BY username, object_type, TRUNC(attempted_on, 'HH')
HAVING COUNT(*) > 50
ORDER BY rapid_operations DESC;