# Dashboard Specifications
## Smart Mineral Extraction and Safety Monitoring System

---

## 1. Executive Overview Dashboard

### Purpose
Provide senior management with high-level KPIs and strategic insights for decision-making.

### Target Users
- CEO, COO, Regional Directors
- Board Members
- Strategic Planning Team

### Refresh Rate
Every 4 hours (or on-demand)

---

### Layout & Components

#### 1.1 Header Section (Top Banner)
```
┌─────────────────────────────────────────────────────────────┐
│  EXECUTIVE DASHBOARD                        Last Updated: [Time] │
│  Smart Mineral Extraction & Safety System                      │
└─────────────────────────────────────────────────────────────┘
```

#### 1.2 KPI Cards Row
```
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ Total Revenue│ Total Extract│ Active Sites │ Safety Score │
│  $45.2M      │  125,340 tons│     70       │    94.5%     │
│  ↑ 12.5%     │  ↑ 8.2%      │  → 0         │  ↑ 2.1%      │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

**SQL for KPI Cards**:
```sql
-- Total Revenue (Current Month)
SELECT SUM(revenue_calculated) as total_revenue,
       ROUND((SUM(revenue_calculated) - LAG(SUM(revenue_calculated)) OVER (ORDER BY TO_CHAR(date_extracted, 'YYYY-MM'))) / 
       LAG(SUM(revenue_calculated)) OVER (ORDER BY TO_CHAR(date_extracted, 'YYYY-MM')) * 100, 1) as growth_pct
FROM extraction
WHERE TO_CHAR(date_extracted, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM');

-- Total Extraction Volume (Current Month)
SELECT SUM(quantity_tons) as total_quantity
FROM extraction
WHERE TO_CHAR(date_extracted, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM');

-- Safety Score (Current Month)
SELECT ROUND((1 - COUNT(CASE WHEN severity_level >= 3 THEN 1 END) / NULLIF(COUNT(*), 0)) * 100, 1) as safety_score
FROM safety_report
WHERE TO_CHAR(date_reported, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM');
```

#### 1.3 Revenue Trend Chart (Line Chart)
```
Revenue Trend - Last 12 Months
┌─────────────────────────────────────────────┐
│           ╱╲                                │
│          ╱  ╲        ╱╲                     │
│         ╱    ╲      ╱  ╲     ╱             │
│        ╱      ╲    ╱    ╲   ╱              │
│       ╱        ╲  ╱      ╲ ╱               │
│──────┴─────────┴┴────────┴─────────────────│
│ Jan  Mar  May  Jul  Sep  Nov  Dec          │
└─────────────────────────────────────────────┘
```

**SQL Query**:
```sql
SELECT TO_CHAR(date_extracted, 'YYYY-MM') as month,
       SUM(revenue_calculated) as monthly_revenue
FROM extraction
WHERE date_extracted >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -12)
GROUP BY TO_CHAR(date_extracted, 'YYYY-MM')
ORDER BY month;
```

#### 1.4 Regional Performance Map
```
┌─────────────────────────────────────────────┐
│      Regional Revenue Distribution          │
│                                             │
│    Northern ████████ 32%                    │
│    Eastern  ██████████ 38%                  │
│    Western  ████ 18%                        │
│    Central  ████ 12%                        │
│                                             │
└─────────────────────────────────────────────┘
```

**SQL Query**:
```sql
SELECT m.region,
       SUM(e.revenue_calculated) as region_revenue,
       ROUND(SUM(e.revenue_calculated) / (SELECT SUM(revenue_calculated) FROM extraction) * 100, 1) as pct
FROM mine_site m
JOIN extraction e ON m.site_id = e.site_id
GROUP BY m.region
ORDER BY region_revenue DESC;
```

#### 1.5 Top 5 Performing Sites (Table)
```
┌────┬─────────────────────┬──────────┬────────────┐
│ #  │ Site Name           │ Region   │ Revenue    │
├────┼─────────────────────┼──────────┼────────────┤
│ 1  │ Kigali Gold Mine    │ Central  │ $2.5M      │
│ 2  │ Gatsibo Uranium     │ Eastern  │ $2.1M      │
│ 3  │ Nemba Gold Valley   │ Northern │ $1.8M      │
│ 4  │ Gicumbi Copper Zone │ Northern │ $1.6M      │
│ 5  │ Gasabo Diamond Hub  │ Central  │ $1.4M      │
└────┴─────────────────────┴──────────┴────────────┘
```

**SQL Query**:
```sql
SELECT ROWNUM as rank,
       m.site_name,
       m.region,
       SUM(e.revenue_calculated) as total_revenue
FROM mine_site m
JOIN extraction e ON m.site_id = e.site_id
WHERE e.date_extracted >= TRUNC(SYSDATE, 'MM')
GROUP BY m.site_name, m.region
ORDER BY total_revenue DESC
FETCH FIRST 5 ROWS ONLY;
```

#### 1.6 Safety Incident Overview (Gauge Chart)
```
Safety Incidents This Month
┌─────────────────────────────────────────────┐
│         ╱─────────────────────╲             │
│       ╱   LOW    MED    HIGH   ╲            │
│      │     •                    │           │
│       ╲                        ╱            │
│         ╲─────────────────────╱             │
│              12 Incidents                   │
│         (2 High, 4 Med, 6 Low)              │
└─────────────────────────────────────────────┘
```

**SQL Query**:
```sql
SELECT COUNT(*) as total_incidents,
       SUM(CASE WHEN severity_level = 3 THEN 1 ELSE 0 END) as high,
       SUM(CASE WHEN severity_level = 2 THEN 1 ELSE 0 END) as medium,
       SUM(CASE WHEN severity_level = 1 THEN 1 ELSE 0 END) as low
FROM safety_report
WHERE TO_CHAR(date_reported, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM');
```

---

## 2. Operations Dashboard

### Purpose
Monitor daily operations, extraction activities, and resource utilization.

### Target Users
- Operations Managers
- Site Managers
- Production Supervisors

### Refresh Rate
Every 2 hours

---

### Layout & Components

#### 2.1 Daily Extraction Summary
```
Today's Extraction: 1,245 tons | Revenue: $285,400
┌─────────────────────────────────────────────┐
│  Site Performance (Today)                   │
├─────────────────────┬───────────┬───────────┤
│ Kigali Gold Mine    │ 125.5 ton │ $42,300   │
│ Gicumbi Copper Zone │ 98.2 ton  │ $38,100   │
│ Musanze Mineral     │ 87.3 ton  │ $28,900   │
│ ...                 │ ...       │ ...       │
└─────────────────────┴───────────┴───────────┘
```

**SQL Query**:
```sql
SELECT m.site_name,
       SUM(e.quantity_tons) as daily_quantity,
       SUM(e.revenue_calculated) as daily_revenue
FROM mine_site m
JOIN extraction e ON m.site_id = e.site_id
WHERE TRUNC(e.date_extracted) = TRUNC(SYSDATE)
GROUP BY m.site_name
ORDER BY daily_revenue DESC;
```

#### 2.2 Worker Productivity Chart
```
Top 10 Operators (This Week)
┌─────────────────────────────────────────────┐
│ Jean Mugisha      ████████████ 156 tons     │
│ Patrick Hirwa     ██████████ 142 tons       │
│ Eric Nizeyimana   █████████ 138 tons        │
│ Alice Uwamariya   ████████ 125 tons         │
│ ...                                         │
└─────────────────────────────────────────────┘
```

**SQL Query**:
```sql
SELECT w.name,
       SUM(e.quantity_tons) as total_extracted
FROM worker w
JOIN extraction e ON w.worker_id = e.operator_id
WHERE e.date_extracted >= TRUNC(SYSDATE, 'IW')
GROUP BY w.name
ORDER BY total_extracted DESC
FETCH FIRST 10 ROWS ONLY;
```

#### 2.3 Shift Performance Comparison
```
Day Shift vs Night Shift (This Week)
┌─────────────────────────────────────────────┐
│                                             │
│  Day Shift:    ████████████ 2,450 tons     │
│                $425,000 revenue             │
│                                             │
│  Night Shift:  ████████ 1,890 tons         │
│                $312,000 revenue             │
└─────────────────────────────────────────────┘
```

**SQL Query**:
```sql
SELECT shift,
       SUM(quantity_tons) as total_quantity,
       SUM(revenue_calculated) as total_revenue
FROM extraction
WHERE date_extracted >= TRUNC(SYSDATE, 'IW')
GROUP BY shift;
```

#### 2.4 Machinery Status Overview
```
Equipment Status
┌──────────────┬──────────────┬──────────────┐
│  Active: 45  │ Maintenance:8│ Inactive: 47 │
│  (45%)       │  (8%)        │  (47%)       │
└──────────────┴──────────────┴──────────────┘

Maintenance Alerts: 12 machines overdue
```

**SQL Query**:
```sql
-- Status Summary
SELECT status,
       COUNT(*) as machine_count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM machinery), 1) as pct
FROM machinery
GROUP BY status;

-- Overdue Maintenance
SELECT COUNT(*) as overdue_count
FROM machinery
WHERE next_maintenance < TRUNC(SYSDATE);
```

#### 2.5 Mineral Extraction Breakdown (Pie Chart)
```
Extraction by Mineral Type (This Month)
┌─────────────────────────────────────────────┐
│             ╱────────╲                      │
│          ╱──Gold 28%──╲                     │
│        │───Copper 22%───│                   │
│        │──Iron 18%──────│                   │
│          ╲──Other 32%──╱                    │
│             ╲────────╱                      │
└─────────────────────────────────────────────┘
```

**SQL Query**:
```sql
SELECT min.mineral_name,
       SUM(e.quantity_tons) as total_quantity,
       ROUND(SUM(e.quantity_tons) / (SELECT SUM(quantity_tons) FROM extraction 
              WHERE TO_CHAR(date_extracted, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM')) * 100, 1) as pct
FROM mineral min
JOIN extraction e ON min.mineral_id = e.mineral_id
WHERE TO_CHAR(e.date_extracted, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM')
GROUP BY min.mineral_name
ORDER BY total_quantity DESC;
```

---

## 3. Safety Dashboard

### Purpose
Track safety incidents, monitor worker safety status, and ensure compliance.

### Target Users
- Safety Officers
- HSE Department
- Site Managers

### Refresh Rate
Real-time (every 15 minutes)

---

### Layout & Components

#### 3.1 Safety KPI Cards
```
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ Total        │ High Severity│ Workers Under│ Days Since   │
│ Incidents    │ Incidents    │ Review       │ Last Severe  │
│    24        │     3        │     8        │    12        │
│  ↓ 15%       │  → 0         │  ↓ 2         │              │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

**SQL Query**:
```sql
-- Total Incidents (This Month)
SELECT COUNT(*) as total_incidents
FROM safety_report
WHERE TO_CHAR(date_reported, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM');

-- High Severity Incidents
SELECT COUNT(*) as high_severity
FROM safety_report
WHERE severity_level = 3
  AND TO_CHAR(date_reported, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM');

-- Workers Under Review
SELECT COUNT(*) as under_review
FROM worker
WHERE safety_status = 'UNDER_REVIEW';

-- Days Since Last Severe Incident
SELECT TRUNC(SYSDATE) - MAX(TRUNC(date_reported)) as days_since
FROM safety_report
WHERE severity_level = 3;
```

#### 3.2 Incident Trend Chart
```
Safety Incidents - Last 6 Months
┌─────────────────────────────────────────────┐
│ 30│                                         │
│ 25│    •                                    │
│ 20│  •   •                                  │
│ 15│       •    •                            │
│ 10│              •   •                      │
│  5│                     •                   │
│  0├──────────────────────────────────────── │
│   Jul  Aug  Sep  Oct  Nov  Dec             │
└─────────────────────────────────────────────┘
```

**SQL Query**:
```sql
SELECT TO_CHAR(date_reported, 'YYYY-MM') as month,
       COUNT(*) as incident_count
FROM safety_report
WHERE date_reported >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -6)
GROUP BY TO_CHAR(date_reported, 'YYYY-MM')
ORDER BY month;
```

#### 3.3 Incidents by Site (Heatmap)
```
Site Safety Performance
┌─────────────────────┬──────────┬────────────┐
│ Site Name           │ Incidents│ Severity   │
├─────────────────────┼──────────┼────────────┤
│ Kigali Gold Mine    │    8     │ 🟡 Medium  │
│ Gicumbi Copper Zone │    5     │ 🟢 Low     │
│ Musanze Mineral     │   12     │ 🔴 High    │
│ Rubavu Sand Quarry  │    3     │ 🟢 Low     │
└─────────────────────┴──────────┴────────────┘
```

**SQL Query**:
```sql
SELECT m.site_name,
       COUNT(sr.report_id) as incident_count,
       AVG(sr.severity_level) as avg_severity,
       CASE 
           WHEN AVG(sr.severity_level) >= 2.5 THEN 'High'
           WHEN AVG(sr.severity_level) >= 1.5 THEN 'Medium'
           ELSE 'Low'
       END as risk_level
FROM mine_site m
LEFT JOIN safety_report sr ON m.site_id = sr.site_id
WHERE sr.date_reported >= ADD_MONTHS(SYSDATE, -1)
GROUP BY m.site_name
ORDER BY incident_count DESC;
```

#### 3.4 Incident Type Breakdown
```
Common Incident Types (This Month)
┌─────────────────────────────────────────────┐
│ Dust exposure       ████████ 8              │
│ Slippery surface    ██████ 6                │
│ Equipment fall      ████ 4                  │
│ Machine malfunction ███ 3                   │
│ Minor cut           ███ 3                   │
└─────────────────────────────────────────────┘
```

**SQL Query**:
```sql
SELECT incident_type,
       COUNT(*) as incident_count
FROM safety_report
WHERE TO_CHAR(date_reported, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM')
GROUP BY incident_type
ORDER BY incident_count DESC
FETCH FIRST 5 ROWS ONLY;
```

#### 3.5 Workers Under Safety Review (Table)
```
┌────┬─────────────────┬─────────────┬──────────────┐
│ ID │ Worker Name     │ Site        │ Last Incident│
├────┼─────────────────┼─────────────┼──────────────┤
│ 4  │ Bizimana Ange   │ Rubavu Sand │ 2024-12-10   │
│ 16 │ Uwera Sandrine  │ Rusizi Iron │ 2024-12-15   │
│ 35 │ Uwimana Eric    │ Kamonyi     │ 2024-12-18   │
└────┴─────────────────┴─────────────┴──────────────┘
```

**SQL Query**:
```sql
SELECT w.worker_id,
       w.name,
       m.site_name,
       MAX(sr.date_reported) as last_incident_date
FROM worker w
JOIN mine_site m ON w.assigned_site = m.site_id
JOIN safety_report sr ON w.worker_id = sr.worker_id
WHERE w.safety_status = 'UNDER_REVIEW'
GROUP BY w.worker_id, w.name, m.site_name
ORDER BY last_incident_date DESC;
```

---

## 4. Financial Dashboard

### Purpose
Track revenue, analyze financial performance, and monitor mineral market prices.

### Target Users
- CFO, Finance Team
- Business Analysts
- Executive Management

### Refresh Rate
Daily (updated at midnight)

---

### Layout & Components

#### 4.1 Financial KPI Cards
```
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ MTD Revenue  │ YTD Revenue  │ Avg Revenue/ │ Top Mineral  │
│              │              │ Extraction   │ by Revenue   │
│  $3.2M       │  $42.5M      │  $2,450      │  Gold        │
│  ↑ 8.5%      │  ↑ 15.2%     │  ↑ 3.2%      │  $12.5M      │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

**SQL Queries**:
```sql
-- MTD Revenue
SELECT SUM(revenue_calculated) as mtd_revenue
FROM extraction
WHERE TO_CHAR(date_extracted, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM');

-- YTD Revenue
SELECT SUM(revenue_calculated) as ytd_revenue
FROM extraction
WHERE TO_CHAR(date_extracted, 'YYYY') = TO_CHAR(SYSDATE, 'YYYY');

-- Average Revenue per Extraction
SELECT AVG(revenue_calculated) as avg_revenue
FROM extraction
WHERE TO_CHAR(date_extracted, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM');

-- Top Mineral by Revenue
SELECT min.mineral_name,
       SUM(e.revenue_calculated) as mineral_revenue
FROM mineral min
JOIN extraction e ON min.mineral_id = e.mineral_id
WHERE TO_CHAR(e.date_extracted, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM')
GROUP BY min.mineral_name
ORDER BY mineral_revenue DESC
FETCH FIRST 1 ROW ONLY;
```

#### 4.2 Revenue by Mineral Type (Bar Chart)
```
Revenue by Mineral (This Month)
┌─────────────────────────────────────────────┐
│ Gold        ████████████████ $1.2M          │
│ Copper      ████████████ $850K              │
│ Iron        ██████ $420K                    │
│ Uranium     ████████████████████ $1.5M      │
│ Diamond     ██████████ $680K                │
└─────────────────────────────────────────────┘
```

**SQL Query**:
```sql
SELECT min.mineral_name,
       SUM(e.revenue_calculated) as total_revenue
FROM mineral min
JOIN extraction e ON min.mineral_id = e.mineral_id
WHERE TO_CHAR(e.date_extracted, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM')
GROUP BY min.mineral_name
ORDER BY total_revenue DESC;
```

#### 4.3 Revenue Trend by Region (Stacked Area Chart)
```
Regional Revenue Trends (Last 6 Months)
┌─────────────────────────────────────────────┐
│           ╱╲        ╱╲                      │
│          ╱──╲      ╱──╲     ╱              │
│         ╱────╲    ╱────╲   ╱──             │
│        ╱──────╲  ╱──────╲ ╱────            │
│       ╱────────╲╱────────╲──────           │
│ Jul   Aug   Sep   Oct   Nov   Dec          │
│ Northern | Eastern | Western | Central      │
└─────────────────────────────────────────────┘
```

**SQL Query**:
```sql
SELECT TO_CHAR(e.date_extracted, 'YYYY-MM') as month,
       m.region,
       SUM(e.revenue_calculated) as monthly_revenue
FROM mine_site m
JOIN extraction e ON m.site_id = e.site_id
WHERE e.date_extracted >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -6)
GROUP BY TO_CHAR(e.date_extracted, 'YYYY-MM'), m.region
ORDER BY month, region;
```

#### 4.4 Top Revenue Generating Sites (Table)
```
┌────┬─────────────────────┬──────────┬────────────┐
│ #  │ Site Name           │ Region   │ MTD Revenue│
├────┼─────────────────────┼──────────┼────────────┤
│ 1  │ Gatsibo Uranium     │ Eastern  │ $425,600   │
│ 2  │ Kigali Gold Mine    │ Central  │ $382,100   │
│ 3  │ Gasabo Diamond Hub  │ Central  │ $298,400   │
│ 4  │ Nemba Gold Valley   │ Northern │ $275,800   │
│ 5  │ Gicumbi Copper Zone │ Northern │ $245,200   │
└────┴─────────────────────┴──────────┴────────────┘
```

**SQL Query**:
```sql
SELECT ROWNUM as rank,
       m.site_name,
       m.region,
       SUM(e.revenue_calculated) as mtd_revenue
FROM mine_site m
JOIN extraction e ON m.site_id = e.site_id
WHERE TO_CHAR(e.date_extracted, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM')
GROUP BY m.site_name, m.region
ORDER BY mtd_revenue DESC
FETCH FIRST 5 ROWS ONLY;
```

#### 4.5 Mineral Market Price Tracker
```
Current Market Prices (Top 10 by Value)
┌──────────────────┬────────────┬───────┬────────┐
│ Mineral          │ Price      │ Unit  │ Change │
├──────────────────┼────────────┼───────┼────────┤
│ Diamond          │ $150,000   │ kg    │ ↑ 2.5% │
│ Emerald          │ $120,000   │ kg    │ ↑ 1.8% │
│ Ruby             │ $130,000   │ kg    │ ↓ 0.5% │
│ Platinum         │ $95,000    │ kg    │ ↑ 3.2% │
│ Uranium          │ $90,000    │ kg    │ → 0.0% │
└──────────────────┴────────────┴───────┴────────┘
```

**SQL Query**:
```sql
SELECT mineral_name,
       market_price,
       unit
FROM mineral
ORDER BY market_price DESC
FETCH FIRST 10 ROWS ONLY;
```

---

## 5. Environmental Dashboard

### Purpose
Monitor environmental conservation activities and compliance status.

### Target Users
- Environmental Officers
- Compliance Team
- Site Managers

### Refresh Rate
Daily

---

### Layout & Components

#### 5.1 Conservation Activity Summary
```
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ Total        │ Tree Planting│ Water        │ Land         │
│ Activities   │ Activities   │ Treatment    │ Restoration  │
│    156       │     45       │     38       │     28       │
│  ↑ 12        │  ↑ 5         │  ↑ 3         │  ↑ 2         │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

**SQL Query**:
```sql
-- Total Activities
SELECT COUNT(*) as total_activities
FROM environment_conservation
WHERE TO_CHAR(date_recorded, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM');

-- By Activity Type
SELECT activity_type,
       COUNT(*) as activity_count
FROM environment_conservation
WHERE TO_CHAR(date_recorded, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM')
GROUP BY activity_type;
```

#### 5.2 Conservation Activities by Type (Donut Chart)
```
Activity Distribution (This Month)
┌─────────────────────────────────────────────┐
│           ╭─────────────╮                   │
│         ╭─│Tree Planting│─╮                 │
│        │  │    29%      │  │                │
│        │  ╰─────────────╯  │                │
│         ╰──Water Treatment─╯                │
│             (24%)   Land Restoration        │
│                      (18%)                  │
└─────────────────────────────────────────────┘
```

**SQL Query**:
```sql
SELECT activity_type,
       COUNT(*) as activity_count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM environment_conservation 
              WHERE TO_CHAR(date_recorded, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM')), 1) as pct
FROM environment_conservation
WHERE TO_CHAR(date_recorded, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM')
GROUP BY activity_type
ORDER BY activity_count DESC;
```

#### 5.3 Site Compliance Status (Table)
```
┌─────────────────────┬────────────┬──────────┬────────┐
│ Site Name           │ Activities │ Avg Impact│ Status │
├─────────────────────┼────────────┼──────────┼────────┤
│ Kigali Gold Mine    │    12      │   1.8    │ ✅ Good│
│ Gicumbi Copper Zone │     8      │   2.1    │ ✅ Good│
│ Musanze Mineral     │     4      │   2.8    │ ⚠️ Alert│
│ Rubavu Sand Quarry  │    15      │   1.5    │ ✅ Good│
└─────────────────────┴────────────┴──────────┴────────┘
```

**SQL Query**:
```sql
SELECT m.site_name,
       COUNT(ec.conservation_id) as activity_count,
       ROUND(AVG(ec.impact_level), 1) as avg_impact,
       CASE 
           WHEN AVG(ec.impact_level) <= 2 THEN 'Good'
           WHEN AVG(ec.impact_level) <= 2.5 THEN 'Alert'
           ELSE 'Critical'
       END as status
FROM mine_site m
LEFT JOIN environment_conservation ec ON m.site_id = ec.site_id
WHERE ec.date_recorded >= ADD_MONTHS(SYSDATE, -1)
GROUP BY m.site_name
ORDER BY avg_impact;
```

#### 5.4 Conservation Trend (Line Chart)
```
Conservation Activities - Last 6 Months
┌─────────────────────────────────────────────┐
│ 40│                              •          │
│ 35│                         •               │
│ 30│                    •                    │
│ 25│               •                         │
│ 20│          •                              │
│ 15│     •                                   │
│  0├──────────────────────────────────────── │
│   Jul  Aug  Sep  Oct  Nov  Dec             │
└─────────────────────────────────────────────┘
```

**SQL Query**:
```sql
SELECT TO_CHAR(date_recorded, 'YYYY-MM') as month,
       COUNT(*) as activity_count
FROM environment_conservation
WHERE date_recorded >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -6)
GROUP BY TO_CHAR(date_recorded, 'YYYY-MM')
ORDER BY month;
```

---

## 6. Site Manager Dashboar