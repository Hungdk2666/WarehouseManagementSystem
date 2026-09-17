# Warehouse Management System

![Java](https://img.shields.io/badge/Java-17-blue)
![Jakarta Servlet](https://img.shields.io/badge/Jakarta%20Servlet-Tomcat%2010.1-orange)
![Database](https://img.shields.io/badge/Database-MySQL-4479A1)
![UI](https://img.shields.io/badge/UI-JSP%20%2B%20Bootstrap%205-7952B3)

Warehouse Management System is a Java web application for managing warehouse operations from master data, import/export requests, stock execution, serial tracking, stocktake, reporting, and role-based access control.

The project was built with the classic Java web architecture: JSP for views, Servlets for request handling, Service classes for business rules, DAO classes for database access, and MySQL for persistence.

## Highlights

- Role-Based Access Control with 5 business roles: System Admin, Business Admin, Warehouse Manager, Warehouse Staff, and Sales Staff.
- Import workflow from purchase request to approval and physical receiving.
- Export workflow from sales/export request to approval and stock deduction.
- Serial-level product tracking with WMS serials and manufacturer serials.
- Inventory monitoring with stock quantity, stock history, and low-stock visibility.
- Stocktake module with count, verification, approval thresholds, and auditability.
- Business reports for stock, movements, period summary, and ticket data.
- Excel export support using Apache POI.
- Audit log and notification modules for operational traceability.

## Tech Stack

| Layer | Technology |
| --- | --- |
| Language | Java 17 |
| Web | Jakarta Servlet, JSP |
| Server | Apache Tomcat 10.1 |
| Database | MySQL |
| UI | Bootstrap 5, Bootstrap Icons, Chart.js, Tom Select |
| Reporting / Excel | Apache POI |
| Build / IDE | Ant, NetBeans project structure |

## Architecture

```text
Browser
  -> JSP pages in /web
  -> Servlet controllers in /src/java/controller
  -> Service classes in /src/java/service
  -> DAO classes in /src/java/dao
  -> MySQL database
```

Example flow for an import request:

```text
web/import_request/request-add.jsp
  -> controller/warehouse/ImportRequestServlet.java
  -> service/RequestService.java
  -> dao/RequestDAO.java
  -> Requests + Request_Details tables
```

Example flow for an export ticket:

```text
web/export_ticket/ticket-add.jsp
  -> controller/warehouse/ExportTicketServlet.java
  -> service/TicketService.java
  -> dao/TicketDAO.java
  -> Tickets + Ticket_Details + Inventories tables
```

## Main Modules

| Module | Description |
| --- | --- |
| Authentication | Login, logout, password reset, profile, change password |
| Admin | User management, role management, permission matrix, audit log |
| Master Data | Products, categories, brands, suppliers, customers, warehouses, internal destinations |
| Import | Import requests, approval, import tickets, serial scanning, partial receiving |
| Export | Export requests, approval, export tickets, stock validation, stock deduction |
| Inventory | Stock list, stock detail, product item history, warehouse stock |
| Stocktake | Stocktake creation, physical counting, verification, approval, threshold config |
| Reports | Stock report, ticket report, daily movement report, period summary |

## Database Setup

Use one script depending on your situation:

- Clean install: run `wms_db_v3.sql`
- Upgrade an existing database: run `migration.sql`

Detailed notes are in [DATABASE_SETUP.md](DATABASE_SETUP.md).

After importing the database, create your local database configuration:

```powershell
Copy-Item src/java/db.properties.example src/java/db.properties
```

Then edit `src/java/db.properties` with your local MySQL username and password.

## Run Locally

1. Install Java 17, MySQL, NetBeans, and Apache Tomcat 10.1.
2. Import the database using `wms_db_v3.sql`.
3. Create `src/java/db.properties` from `src/java/db.properties.example`.
4. Open the project in NetBeans.
5. Configure Tomcat 10.1 as the project server.
6. Clean and build the project.
7. Run the application and open the generated local URL.

You can also compile from PowerShell if Tomcat is installed in the path expected by `compile.ps1`:

```powershell
.\compile.ps1
```

## Demo Accounts

The seed database contains demo users. The default password is:

```text
123456
```

| Role | Username |
| --- | --- |
| System Admin | `khachung` |
| Business Admin | `leduy` |
| Warehouse Manager | `phuonglinh` |
| Warehouse Staff | `thanhhung` |
| Sales Staff | `vietanh` |

## Useful Documents

- [RDS Google Doc](https://docs.google.com/document/d/1x6crQ5Rcr8Nn2xQmBQ2TZg2tbv9-6mSD/edit?usp=sharing&ouid=100153851788808335048&rtpof=true&sd=true)
- [Requirement & Design Specification](WMS_Requirement_Design_Specification.md)
- [Database Setup](DATABASE_SETUP.md)
- [Demo Preparation Guide](Demo_Preparation_Guide.md)
- [SQL Practice Guide](SQL_Practice_Guide.md)
- [Reporting Rollup Runbook](docs/reporting-rollup-runbook.md)

## Repository Notes

- `src/java/db.properties` is intentionally ignored because it contains local database credentials.
- Build outputs such as `build/` and `dist/` should not be committed.
- Keep screenshots or demo GIFs in `docs/images/` if you add them later.

## Suggested Demo Flow

1. Login as Sales Staff and create an import/export request.
2. Login as Business Admin and approve the request.
3. Login as Warehouse Staff and execute the physical import/export ticket.
4. Open inventory and reports to show how stock data changed.

## Project Status

This project is a student capstone-style warehouse management system focused on business process clarity, database-backed workflows, RBAC, and operational traceability.
