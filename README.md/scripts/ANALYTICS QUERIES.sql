-- ========================================
-- ANALYTICS QUERIES
-- Mining Database - Advanced Analytics & Reporting
-- ========================================

-- 1. Revenue Analysis by Site and Mineral
SELECT m.site_name, m.region, min.mineral_name,
       COUNT(e.extraction_id) AS extraction_count,
       SUM(e.quantity_tons) AS total_quantity,
       SUM(e.revenue_calculated) AS total_revenue,
       AVG(e.revenue_calculated) AS avg_revenue_per_extraction
FROM extraction e
JOIN mine_site m ON e.site_id = m.site_id
JOIN mineral min ON e.mineral_id = min.mineral_id
GROUP BY m.site_name, m.region, min.mineral_name
ORDER BY total_revenue DESC NULLS LAST;

-- 2. Monthly Extraction Trends
SELECT TO_CHAR(date_extracted, 'YYYY-MM') AS month,
       COUNT(extraction_id) AS total_extractions,
       SUM(quantity_tons) AS total_quantity,
       SUM(revenue_calculated) AS total_revenue,
       AVG(quantity_tons) AS avg_quantity_per_extraction
FROM extraction
WHERE date_extracted >= ADD_MONTHS(TRUNC(SYSDATE), -12)
GROUP BY TO_CHAR(date_extracted, 'YYYY-MM')
ORDER BY month DESC;

-- 3. Top Performing Sites by Revenue
SELECT m.site_id, m.site_name, m.region, m.manager_name,
       COUNT(e.extraction_id) AS total_extractions,
       SUM(e.quantity_tons) AS total_quantity_tons,
       SUM(e.revenue_calculated) AS total_revenue,
       RANK() OVER (ORDER BY SUM(e.revenue_calculated) DESC NULLS LAST) AS revenue_rank
FROM mine_site m
LEFT JOIN extraction e ON m.site_id = e.site_id
GROUP BY m.site_id, m.site_name, m.region, m.manager_name
ORDER BY revenue_rank;

-- 4. Worker Productivity Analysis
SELECT w.worker_id, w.name, w.role, m.site_name,
       COUNT(e.extraction_id) AS operations_completed,
       SUM(e.quantity_tons) AS total_quantity_extracted,
       SUM(e.revenue_calculated) AS total_revenue_generated,
       AVG(e.quantity_tons) AS avg_quantity_per_operation
FROM worker w
LEFT JOIN extraction e ON w.worker_id = e.operator_id
LEFT JOIN mine_site m ON w.assigned_site = m.site_id
WHERE w.role IN ('Operator', 'Technician')
GROUP BY w.worker_id, w.name, w.role, m.site_name
HAVING COUNT(e.extraction_id) > 0
ORDER BY total_revenue_generated DESC NULLS LAST;

-- 5. Mineral Performance Analysis
SELECT min.mineral_name, min.market_price, min.unit,
       COUNT(e.extraction_id) AS times_extracted,
       SUM(e.quantity_tons) AS total_quantity,
       SUM(e.revenue_calculated) AS total_revenue,
       AVG(e.quantity_tons) AS avg_extraction_quantity
FROM mineral min
LEFT JOIN extraction e ON min.mineral_id = e.mineral_id
GROUP BY min.mineral_name, min.market_price, min.unit
ORDER BY total_revenue DESC NULLS LAST;

-- 6. Safety Incident Analysis by Site and Severity
SELECT m.site_name, m.region,
       COUNT(sr.report_id) AS total_incidents,
       SUM(CASE WHEN sr.severity_level = 1 THEN 1 ELSE 0 END) AS minor_incidents,
       SUM(CASE WHEN sr.severity_level = 2 THEN 1 ELSE 0 END) AS moderate_incidents,
       SUM(CASE WHEN sr.severity_level = 3 THEN 1 ELSE 0 END) AS severe_incidents,
       AVG(sr.severity_level) AS avg_severity,
       COUNT(DISTINCT sr.worker_id) AS affected_workers
FROM mine_site m
LEFT JOIN safety_report sr ON m.site_id = sr.site_id
GROUP BY m.site_name, m.region
ORDER BY total_incidents DESC, avg_severity DESC;

-- 7. Machinery Utilization and Maintenance Analysis
SELECT ms.site_name, m.status,
       COUNT(m.machine_id) AS machine_count,
       AVG(m.hours_run) AS avg_hours_run,
       SUM(m.hours_run) AS total_hours_run,
       COUNT(CASE WHEN m.next_maintenance < TRUNC(SYSDATE) THEN 1 END) AS overdue_maintenance
FROM machinery m
JOIN mine_site ms ON m.site_id = ms.site_id
GROUP BY ms.site_name, m.status
ORDER BY ms.site_name, m.status;

-- 8. Day vs Night Shift Performance
SELECT e.shift,
       COUNT(e.extraction_id) AS total_extractions,
       SUM(e.quantity_tons) AS total_quantity,
       AVG(e.quantity_tons) AS avg_quantity,
       SUM(e.revenue_calculated) AS total_revenue,
       AVG(e.revenue_calculated) AS avg_revenue
FROM extraction e
GROUP BY e.shift
ORDER BY total_revenue DESC;

-- 9. Regional Performance Comparison
SELECT m.region,
       COUNT(DISTINCT m.site_id) AS site_count,
       COUNT(DISTINCT w.worker_id) AS worker_count,
       COUNT(e.extraction_id) AS total_extractions,
       SUM(e.quantity_tons) AS total_quantity_tons,
       SUM(e.revenue_calculated) AS total_revenue,
       AVG(e.revenue_calculated) AS avg_revenue_per_extraction
FROM mine_site m
LEFT JOIN worker w ON m.site_id = w.assigned_site
LEFT JOIN extraction e ON m.site_id = e.site_id
GROUP BY m.region
ORDER BY total_revenue DESC NULLS LAST;

-- 10. Quarterly Revenue Trends
SELECT TO_CHAR(date_extracted, 'YYYY') AS year,
       TO_CHAR(date_extracted, 'Q') AS quarter,
       COUNT(extraction_id) AS extraction_count,
       SUM(quantity_tons) AS total_quantity,
       SUM(revenue_calculated) AS total_revenue
FROM extraction
WHERE date_extracted >= ADD_MONTHS(TRUNC(SYSDATE), -24)
GROUP BY TO_CHAR(date_extracted, 'YYYY'), TO_CHAR(date_extracted, 'Q')
ORDER BY year DESC, quarter DESC;

-- 11. Worker Tenure and Experience Analysis
SELECT role,
       COUNT(worker_id) AS worker_count,
       AVG(MONTHS_BETWEEN(SYSDATE, hire_date)/12) AS avg_years_experience,
       MIN(hire_date) AS earliest_hire,
       MAX(hire_date) AS latest_hire
FROM worker
GROUP BY role
ORDER BY avg_years_experience DESC;

-- 12. Environment Conservation Impact by Site
SELECT m.site_name, m.region,
       COUNT(ec.conservation_id) AS conservation_activities,
       COUNT(CASE WHEN ec.impact_level = 1 THEN 1 END) AS low_impact,
       COUNT(CASE WHEN ec.impact_level = 2 THEN 1 END) AS medium_impact,
       COUNT(CASE WHEN ec.impact_level = 3 THEN 1 END) AS high_impact,
       AVG(ec.impact_level) AS avg_impact_level
FROM mine_site m
LEFT JOIN environment_conservation ec ON m.site_id = ec.site_id
GROUP BY m.site_name, m.region
ORDER BY conservation_activities DESC;

-- 13. Top 10 Most Valuable Minerals
SELECT mineral_name, market_price, unit,
       RANK() OVER (ORDER BY market_price DESC) AS price_rank
FROM mineral
ORDER BY price_rank
FETCH FIRST 10 ROWS ONLY;

-- 14. Extraction Efficiency by Operator
SELECT w.name, w.role, m.site_name,
       COUNT(e.extraction_id) AS total_operations,
       AVG(e.quantity_tons) AS avg_quantity_per_op,
       SUM(e.revenue_calculated) AS total_revenue,
       AVG(e.revenue_calculated) AS avg_revenue_per_op,
       MIN(e.date_extracted) AS first_operation,
       MAX(e.date_extracted) AS last_operation
FROM worker w
JOIN extraction e ON w.worker_id = e.operator_id
JOIN mine_site m ON w.assigned_site = m.site_id
GROUP BY w.name, w.role, m.site_name
HAVING COUNT(e.extraction_id) >= 3
ORDER BY total_revenue DESC;

-- 15. Safety Incident Rate per Worker
SELECT m.site_name, w.name, w.role,
       COUNT(sr.report_id) AS incident_count,
       AVG(sr.severity_level) AS avg_severity,
       MAX(sr.date_reported) AS last_incident_date,
       w.safety_status
FROM worker w
JOIN mine_site m ON w.assigned_site = m.site_id
LEFT JOIN safety_report sr ON w.worker_id = sr.worker_id
GROUP BY m.site_name, w.name, w.role, w.safety_status
HAVING COUNT(sr.report_id) > 0
ORDER BY incident_count DESC, avg_severity DESC;

-- 16. Machinery Age and Performance
SELECT ms.site_name, m.machine_name, m.status,
       m.hours_run,
       TRUNC(MONTHS_BETWEEN(SYSDATE, m.last_maintenance)/12, 1) AS years_since_maintenance,
       TRUNC(SYSDATE - m.next_maintenance) AS days_overdue,
       CASE 
           WHEN m.next_maintenance < TRUNC(SYSDATE) THEN 'Overdue'
           WHEN m.next_maintenance <= TRUNC(SYSDATE) + 30 THEN 'Due Soon'
           ELSE 'Current'
       END AS maintenance_status
FROM machinery m
JOIN mine_site ms ON m.site_id = ms.site_id
ORDER BY days_overdue DESC NULLS LAST;

-- 17. Revenue Contribution by Mineral Category
SELECT 
    CASE 
        WHEN market_price >= 50000 THEN 'Premium (50K+)'
        WHEN market_price >= 10000 THEN 'High Value (10K-50K)'
        WHEN market_price >= 1000 THEN 'Medium Value (1K-10K)'
        ELSE 'Standard (<1K)'
    END AS mineral_category,
    COUNT(DISTINCT min.mineral_id) AS mineral_count,
    SUM(e.revenue_calculated) AS total_revenue,
    AVG(e.revenue_calculated) AS avg_revenue_per_extraction
FROM mineral min
LEFT JOIN extraction e ON min.mineral_id = e.mineral_id
GROUP BY 
    CASE 
        WHEN market_price >= 50000 THEN 'Premium (50K+)'
        WHEN market_price >= 10000 THEN 'High Value (10K-50K)'
        WHEN market_price >= 1000 THEN 'Medium Value (1K-10K)'
        ELSE 'Standard (<1K)'
    END
ORDER BY total_revenue DESC NULLS LAST;

-- 18. Worker Allocation Across Sites
SELECT m.site_name, m.region,
       COUNT(w.worker_id) AS total_workers,
       COUNT(CASE WHEN w.role = 'Operator' THEN 1 END) AS operators,
       COUNT(CASE WHEN w.role = 'Technician' THEN 1 END) AS technicians,
       COUNT(CASE WHEN w.role = 'Safety Officer' THEN 1 END) AS safety_officers,
       COUNT(CASE WHEN w.safety_status = 'CLEARED' THEN 1 END) AS cleared_workers,
       COUNT(CASE WHEN w.safety_status = 'UNDER_REVIEW' THEN 1 END) AS under_review
FROM mine_site m
LEFT JOIN worker w ON m.site_id = w.assigned_site
GROUP BY m.site_name, m.region
ORDER BY total_workers DESC;

-- 19. Year-over-Year Performance Comparison
SELECT 
    TO_CHAR(date_extracted, 'YYYY') AS year,
    COUNT(extraction_id) AS total_extractions,
    SUM(quantity_tons) AS total_quantity,
    SUM(revenue_calculated) AS total_revenue,
    LAG(SUM(revenue_calculated)) OVER (ORDER BY TO_CHAR(date_extracted, 'YYYY')) AS prev_year_revenue,
    ROUND(
        (SUM(revenue_calculated) - LAG(SUM(revenue_calculated)) OVER (ORDER BY TO_CHAR(date_extracted, 'YYYY'))) / 
        NULLIF(LAG(SUM(revenue_calculated)) OVER (ORDER BY TO_CHAR(date_extracted, 'YYYY')), 0) * 100, 
        2
    ) AS revenue_growth_pct
FROM extraction
GROUP BY TO_CHAR(date_extracted, 'YYYY')
ORDER BY year DESC;

-- 20. Comprehensive Site Performance Dashboard
SELECT m.site_id, m.site_name, m.region, m.manager_name,
       COUNT(DISTINCT w.worker_id) AS worker_count,
       COUNT(DISTINCT mach.machine_id) AS machine_count,
       COUNT(e.extraction_id) AS extraction_count,
       SUM(e.quantity_tons) AS total_quantity_extracted,
       SUM(e.revenue_calculated) AS total_revenue,
       COUNT(sr.report_id) AS safety_incidents,
       AVG(sr.severity_level) AS avg_incident_severity,
       COUNT(ec.conservation_id) AS conservation_activities
FROM mine_site m
LEFT JOIN worker w ON m.site_id = w.assigned_site
LEFT JOIN machinery mach ON m.site_id = mach.site_id
LEFT JOIN extraction e ON m.site_id = e.site_id
LEFT JOIN safety_report sr ON m.site_id = sr.site_id
LEFT JOIN environment_conservation ec ON m.site_id = ec.site_id
GROUP BY m.site_id, m.site_name, m.region, m.manager_name
ORDER BY total_revenue DESC NULLS LAST;