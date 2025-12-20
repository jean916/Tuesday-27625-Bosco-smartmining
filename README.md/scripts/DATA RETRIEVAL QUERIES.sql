-- ========================================
-- DATA RETRIEVAL QUERIES
-- Mining Database - Basic SELECT Operations
-- ========================================

-- 1. Retrieve all mine sites with their managers
SELECT site_id, site_name, location, region, manager_name, created_on
FROM mine_site
ORDER BY site_name;

-- 2. Get all minerals with their market prices
SELECT mineral_id, mineral_name, market_price, unit
FROM mineral
ORDER BY market_price DESC;

-- 3. List all workers with their assigned sites
SELECT w.worker_id, w.name, w.role, w.hire_date, w.safety_status, w.contact,
       m.site_name, m.location
FROM worker w
LEFT JOIN mine_site m ON w.assigned_site = m.site_id
ORDER BY w.name;

-- 4. Get all machinery with maintenance status
SELECT machine_id, machine_name, site_id, last_maintenance, 
       next_maintenance, status, hours_run
FROM machinery
ORDER BY next_maintenance;

-- 5. Retrieve all extractions with site and mineral details
SELECT e.extraction_id, e.date_extracted, e.quantity_tons, e.shift,
       m.site_name, min.mineral_name, min.market_price,
       e.revenue_calculated, w.name AS operator_name
FROM extraction e
JOIN mine_site m ON e.site_id = m.site_id
JOIN mineral min ON e.mineral_id = min.mineral_id
LEFT JOIN worker w ON e.operator_id = w.worker_id
ORDER BY e.date_extracted DESC;

-- 6. List all safety incidents with severity level 3 or higher
SELECT sr.report_id, sr.date_reported, sr.incident_type, sr.severity_level,
       m.site_name, w.name AS worker_name, sr.description, sr.action_taken
FROM safety_report sr
JOIN mine_site m ON sr.site_id = m.site_id
LEFT JOIN worker w ON sr.worker_id = w.worker_id
WHERE sr.severity_level >= 3
ORDER BY sr.date_reported DESC;

-- 7. Get all environment conservation activities
SELECT ec.conservation_id, ec.date_recorded, ec.activity_type, ec.impact_level,
       m.site_name, m.region, ec.notes
FROM environment_conservation ec
JOIN mine_site m ON ec.site_id = m.site_id
ORDER BY ec.date_recorded DESC;

-- 8. Retrieve workers by role
SELECT role, COUNT(*) AS worker_count
FROM worker
GROUP BY role
ORDER BY worker_count DESC;

-- 9. Get machinery that needs maintenance (overdue)
SELECT m.machine_id, m.machine_name, ms.site_name, m.last_maintenance,
       m.next_maintenance, m.status, m.hours_run,
       TRUNC(SYSDATE - m.next_maintenance) AS days_overdue
FROM machinery m
JOIN mine_site ms ON m.site_id = ms.site_id
WHERE m.next_maintenance < TRUNC(SYSDATE)
ORDER BY days_overdue DESC;

-- 10. List all workers with safety status 'UNDER_REVIEW'
SELECT w.worker_id, w.name, w.role, w.safety_status, w.contact,
       m.site_name, m.region
FROM worker w
LEFT JOIN mine_site m ON w.assigned_site = m.site_id
WHERE w.safety_status = 'UNDER_REVIEW'
ORDER BY w.name;

-- 11. Get extraction summary by site
SELECT m.site_name, m.region, 
       COUNT(e.extraction_id) AS total_extractions,
       SUM(e.quantity_tons) AS total_quantity_tons,
       SUM(e.revenue_calculated) AS total_revenue
FROM mine_site m
LEFT JOIN extraction e ON m.site_id = e.site_id
GROUP BY m.site_name, m.region
ORDER BY total_revenue DESC NULLS LAST;

-- 12. Retrieve all holidays
SELECT holiday_date, description,
       TO_CHAR(holiday_date, 'Day') AS day_of_week
FROM holiday
ORDER BY holiday_date;

-- 13. Get workers hired in the last 5 years
SELECT worker_id, name, role, hire_date, 
       TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)/12, 1) AS years_employed
FROM worker
WHERE hire_date >= ADD_MONTHS(SYSDATE, -60)
ORDER BY hire_date DESC;

-- 14. List active machinery by site
SELECT ms.site_name, m.machine_name, m.status, m.hours_run, m.next_maintenance
FROM machinery m
JOIN mine_site ms ON m.site_id = ms.site_id
WHERE m.status = 'Active'
ORDER BY ms.site_name, m.machine_name;

-- 15. Get recent extractions (last 30 days)
SELECT e.extraction_id, e.date_extracted, m.site_name, min.mineral_name,
       e.quantity_tons, e.shift, w.name AS operator_name
FROM extraction e
JOIN mine_site m ON e.site_id = m.site_id
JOIN mineral min ON e.mineral_id = min.mineral_id
LEFT JOIN worker w ON e.operator_id = w.worker_id
WHERE e.date_extracted >= TRUNC(SYSDATE) - 30
ORDER BY e.date_extracted DESC;

-- 16. Retrieve minerals by price range
SELECT mineral_name, market_price, unit
FROM mineral
WHERE market_price BETWEEN 1000 AND 50000
ORDER BY market_price;

-- 17. Get workers by assigned site
SELECT m.site_name, m.region, w.name, w.role, w.hire_date
FROM worker w
JOIN mine_site m ON w.assigned_site = m.site_id
ORDER BY m.site_name, w.role, w.name;

-- 18. List all safety incidents by site
SELECT m.site_name, COUNT(sr.report_id) AS incident_count,
       AVG(sr.severity_level) AS avg_severity
FROM mine_site m
LEFT JOIN safety_report sr ON m.site_id = sr.site_id
GROUP BY m.site_name
ORDER BY incident_count DESC;

-- 19. Get environment conservation activities by impact level
SELECT impact_level, activity_type, COUNT(*) AS activity_count
FROM environment_conservation
GROUP BY impact_level, activity_type
ORDER BY impact_level DESC, activity_count DESC;

-- 20. Retrieve extraction records with NULL operators
SELECT e.extraction_id, e.date_extracted, m.site_name, 
       min.mineral_name, e.quantity_tons, e.shift
FROM extraction e
JOIN mine_site m ON e.site_id = m.site_id
JOIN mineral min ON e.mineral_id = min.mineral_id
WHERE e.operator_id IS NULL
ORDER BY e.date_extracted DESC;