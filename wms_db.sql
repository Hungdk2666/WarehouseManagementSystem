-- ========================================================
-- WAREHOUSE MANAGEMENT SYSTEM (WMS) - DATABASE v3
-- ========================================================
-- CLEAN INSTALL / RESET ONLY.
-- This file contains the complete current schema, reporting rollups and seed data.
-- Run this file by itself. It drops and recreates wms_db.
-- Do not run migration.sql after this file.
-- ========================================================
-- Thay đổi so với v2:
--  + Gộp Import_Requests + Export_Requests          → Requests        (type IN/OUT)
--  + Gộp Import_Request_Details + Export_Request_Details → Request_Details
--  + Gộp Import_Tickets + Export_Tickets            → Tickets         (type IN/OUT)
--  + Gộp Import_Ticket_Details + Export_Ticket_Details → Ticket_Details
--  + Product_Item_Movements: 2 FK (import_ticket_id, export_ticket_id) → 1 FK ticket_id
--  + Bỏ confirmReceiveTransfer riêng — TRANSFER tự sinh Request IN-TRANSFER bên kho đích
--  + Permissions: gộp/đổi tên thành REQUEST_*_IN/_OUT, TICKET_*_IN/_OUT
--  + Áp dụng Cách 1: warehouse_id trong Requests/Tickets vai trò suy từ type
--      type='IN'  → warehouse_id = kho nhận hàng
--      type='OUT' → warehouse_id = kho xuất hàng
-- ========================================================

DROP DATABASE IF EXISTS wms_db;
CREATE DATABASE IF NOT EXISTS wms_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE wms_db;

-- ========================================================
-- PART 1: CORE AUTHENTICATION & RBAC
-- ========================================================

CREATE TABLE Roles (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    role_name   VARCHAR(50)  NOT NULL UNIQUE,
    description VARCHAR(255),
    status      BOOLEAN DEFAULT TRUE
);

CREATE TABLE Permissions (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    permission_name VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT
);

CREATE TABLE Role_Permissions (
    role_id       INT,
    permission_id INT,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id)       REFERENCES Roles(id)       ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES Permissions(id) ON DELETE CASCADE
);

CREATE TABLE Warehouses (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_name VARCHAR(100) NOT NULL UNIQUE,
    address        VARCHAR(255),
    status         BOOLEAN DEFAULT TRUE,
    created_at     DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Users (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    username     VARCHAR(50)  NOT NULL,
    password     VARCHAR(255) NOT NULL,
    email        VARCHAR(100),
    full_name    VARCHAR(100),
    status       BOOLEAN DEFAULT TRUE,
    role_id      INT,
    reset_code   VARCHAR(10)  DEFAULT NULL,
    reset_code_expires_at DATETIME DEFAULT NULL,
    reset_attempts INT NOT NULL DEFAULT 0,
    warehouse_id INT          DEFAULT NULL,
    UNIQUE KEY idx_users_username (username),
    UNIQUE KEY idx_users_email (email),
    FOREIGN KEY (role_id)      REFERENCES Roles(id)      ON DELETE SET NULL,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(id) ON DELETE SET NULL
);

-- ========================================================
-- PART 2: MASTER DATA
-- ========================================================

CREATE TABLE Suppliers (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(150) NOT NULL,
    contact_name  VARCHAR(100),
    phone         VARCHAR(20),
    email         VARCHAR(100),
    address       TEXT,
    status        BOOLEAN DEFAULT TRUE
);

CREATE TABLE Categories (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description   TEXT,
    status        BOOLEAN DEFAULT TRUE
);

CREATE TABLE Brands (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    brand_name  VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    status      BOOLEAN DEFAULT TRUE
);

CREATE TABLE Customers (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(150) NOT NULL,
    phone         VARCHAR(20)  NULL,
    email         VARCHAR(100) NULL,
    address       TEXT         NULL,
    external_ref  VARCHAR(100) NULL,
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    status        BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Internal_Destinations (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    destination_name VARCHAR(150) NOT NULL,
    destination_type ENUM('SHOWROOM','WARRANTY_CENTER','OTHER') NOT NULL DEFAULT 'OTHER',
    address          TEXT,
    status           BOOLEAN DEFAULT TRUE
);

CREATE TABLE Products (
    id                       INT AUTO_INCREMENT PRIMARY KEY,
    product_name             VARCHAR(150) NOT NULL,
    sku                      VARCHAR(50)  NOT NULL UNIQUE,
    unit                     VARCHAR(20)  NOT NULL DEFAULT 'cái',
    min_stock                INT          NOT NULL DEFAULT 5,
    average_cost             DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    status                   BOOLEAN DEFAULT TRUE,
    category_id              INT DEFAULT NULL,
    brand_id                 INT DEFAULT NULL,
    FOREIGN KEY (category_id) REFERENCES Categories(id) ON DELETE SET NULL,
    FOREIGN KEY (brand_id)    REFERENCES Brands(id)     ON DELETE SET NULL
);

CREATE TABLE Product_Specifications (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    spec_key  VARCHAR(100) NOT NULL,
    spec_value VARCHAR(255) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE
);

CREATE TABLE Inventories (
    warehouse_id INT NOT NULL,
    product_id   INT NOT NULL,
    quantity            INT NOT NULL DEFAULT 0,
    quarantine_quantity INT NOT NULL DEFAULT 0,
    PRIMARY KEY (warehouse_id, product_id),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id)   REFERENCES Products(id)   ON DELETE CASCADE
);

-- ========================================================
-- PART 3: UNIFIED REQUESTS & TICKETS
-- ========================================================
-- Cách 1 — warehouse_id vai trò suy từ type:
--   type='IN'  → warehouse_id = kho nhận | partner = nguồn (supplier/customer trả/kho đi)
--   type='OUT' → warehouse_id = kho xuất | partner = đích   (customer/internal dest/kho đến)
--
-- Ma trận (type, reason, partner_type) hợp lệ:
--   ('IN',  'PURCHASE',      'SUPPLIER')      — nhập từ NCC
--   ('IN',  'RETURN',        'CUSTOMER')      — khách trả hàng, ref_ticket_id trỏ Ticket OUT gốc
--   ('IN',  'TRANSFER',      'WAREHOUSE')     — nhận chuyển kho, ref_ticket_id trỏ Ticket OUT đối ứng
--   ('OUT', 'TRANSFER',      'WAREHOUSE')     — chuyển sang kho khác (≠ warehouse_id)
--   ('OUT', 'CUSTOMER_SALE', 'CUSTOMER')      — bán cho khách
--   ('OUT', 'DISPLAY',       'INTERNAL_DEST') — trưng bày showroom
--   ('OUT', 'WARRANTY',      'INTERNAL_DEST') — gửi bảo hành
-- ========================================================

CREATE TABLE Requests (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    request_code        VARCHAR(50) NOT NULL UNIQUE,
    type                ENUM('IN','OUT') NOT NULL,
    reason              ENUM(
        'PURCHASE','RETURN',                                        -- IN
        'TRANSFER',                                                 -- IN hoặc OUT
        'DISPLAY','WARRANTY','CUSTOMER_SALE'                        -- OUT
    ) NOT NULL,
    warehouse_id        INT NOT NULL,
    partner_type        ENUM('SUPPLIER','CUSTOMER','WAREHOUSE','INTERNAL_DEST','NONE') NOT NULL,
    partner_id          INT NULL,
    ref_ticket_id       INT NULL,        -- RETURN: trỏ Ticket OUT gốc | IN-TRANSFER: trỏ Ticket OUT đối ứng
    return_reason       ENUM('CUSTOMER_REJECTION','QUALITY_DEFECT','WRONG_ITEM','EXCESS_QUANTITY','OTHER') NULL,
    shipping_address    TEXT NULL,
    expected_serials    TEXT NULL,
    expected_date       DATE NULL,
    staff_id            INT NOT NULL,
    requested_condition ENUM('NEW','USED','DAMAGED') NOT NULL DEFAULT 'NEW',
    status              ENUM('PENDING','APPROVED','PARTIALLY_COMPLETED','PARTIALLY_CLOSED_IN_TRANSIT','IN_TRANSIT',
                             'COMPLETED','PARTIALLY_CLOSED','RETURNING','RETURNED','REJECTED','REVOKED','CANCELLED')
                        NOT NULL DEFAULT 'PENDING',
    auto_approved       BOOLEAN NOT NULL DEFAULT FALSE,   -- TRUE khi Request được hệ thống auto-tạo (IN-TRANSFER đối ứng)
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_by         INT DEFAULT NULL,
    approved_at         DATETIME DEFAULT NULL,
    cancel_requested_by INT DEFAULT NULL,
    cancel_requested_at DATETIME DEFAULT NULL,
    cancel_reason       TEXT DEFAULT NULL,
    cancelled_by        INT DEFAULT NULL,
    cancelled_at        DATETIME DEFAULT NULL,
    KEY idx_requests_warehouse_type_status_date (warehouse_id, type, status, created_at),
    FOREIGN KEY (warehouse_id)        REFERENCES Warehouses(id) ON DELETE RESTRICT,
    -- FK ref_ticket_id → Tickets được thêm bằng ALTER TABLE sau khi tạo Tickets (tránh circular)
    FOREIGN KEY (staff_id)            REFERENCES Users(id)      ON DELETE RESTRICT,
    FOREIGN KEY (approved_by)         REFERENCES Users(id)      ON DELETE SET NULL,
    FOREIGN KEY (cancel_requested_by) REFERENCES Users(id)      ON DELETE SET NULL,
    FOREIGN KEY (cancelled_by)        REFERENCES Users(id)      ON DELETE SET NULL,
    CONSTRAINT chk_req_type_reason CHECK (
        (type='IN'  AND reason IN ('PURCHASE','RETURN','TRANSFER')) OR
        (type='OUT' AND reason IN ('TRANSFER','DISPLAY','WARRANTY','CUSTOMER_SALE'))
    ),
    CONSTRAINT chk_req_partner CHECK (
        (reason='PURCHASE'      AND partner_type='SUPPLIER'      AND partner_id IS NOT NULL) OR
        -- RETURN: chỉ cần ref_ticket_id, partner suy ra từ Ticket xuất gốc (có thể CUSTOMER/INTERNAL_DEST/NONE)
        (reason='RETURN'        AND partner_type IN ('CUSTOMER','INTERNAL_DEST','NONE')) OR
        (type='IN'  AND reason='TRANSFER' AND partner_type='WAREHOUSE' AND partner_id IS NOT NULL AND partner_id != warehouse_id AND ref_ticket_id IS NOT NULL) OR
        (type='OUT' AND reason='TRANSFER' AND partner_type='WAREHOUSE' AND partner_id IS NOT NULL AND partner_id != warehouse_id) OR
        (reason='CUSTOMER_SALE' AND partner_type='CUSTOMER'      AND partner_id IS NOT NULL) OR
        (reason IN ('DISPLAY','WARRANTY') AND partner_type='INTERNAL_DEST' AND partner_id IS NOT NULL)
    )
);

CREATE TABLE Request_Details (
    request_id       INT,
    product_id       INT,
    quantity         INT           NOT NULL,
    unit_price       DECIMAL(12,2) NULL,    -- chỉ bắt buộc cho IN-PURCHASE, OUT và IN-RETURN/TRANSFER NULL
    PRIMARY KEY (request_id, product_id),
    FOREIGN KEY (request_id) REFERENCES Requests(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE RESTRICT
);

CREATE TABLE Tickets (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    ticket_code   VARCHAR(50) NOT NULL UNIQUE,
    type          ENUM('IN','OUT') NOT NULL,    -- denormalize từ Requests cho query nhanh
    request_id    INT NOT NULL,
    warehouse_id  INT NOT NULL,                  -- cùng vai trò như Requests.warehouse_id
    keeper_id     INT NOT NULL,
    status        ENUM('DRAFT','CONFIRMED','IN_TRANSIT','COMPLETED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
    return_status ENUM('NONE','PARTIAL','FULL') NOT NULL DEFAULT 'NONE',  -- chỉ dùng cho type=OUT
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    confirmed_by  INT DEFAULT NULL,
    confirmed_at  DATETIME DEFAULT NULL,
    KEY idx_tickets_report_type_status_date (type, status, confirmed_at, warehouse_id),
    FOREIGN KEY (request_id)   REFERENCES Requests(id)   ON DELETE RESTRICT,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (keeper_id)    REFERENCES Users(id)      ON DELETE RESTRICT,
    FOREIGN KEY (confirmed_by) REFERENCES Users(id)      ON DELETE SET NULL
);

CREATE TABLE Ticket_Details (
    ticket_id        INT,
    product_id       INT,
    quantity         INT           NOT NULL,
    unit_cost        DECIMAL(12,2) NOT NULL DEFAULT 0.00,    -- IN: giá nhập | OUT: giá vốn xuất
    PRIMARY KEY (ticket_id, product_id),
    FOREIGN KEY (ticket_id)  REFERENCES Tickets(id)  ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE RESTRICT
);

-- Thêm FK Requests.ref_ticket_id sau khi Tickets đã tồn tại (tránh circular)
ALTER TABLE Requests
    ADD CONSTRAINT fk_req_ref_ticket FOREIGN KEY (ref_ticket_id)
        REFERENCES Tickets(id) ON DELETE RESTRICT;

-- ========================================================
-- PART 4: PHYSICAL ITEM TRACKING
-- ========================================================

CREATE TABLE Product_Items (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    product_id     INT NOT NULL,
    serial_number  VARCHAR(100) NOT NULL UNIQUE,
    manufacturer_serial VARCHAR(100) NULL,
    status         ENUM('IN_STOCK','EXPORTED','IN_TRANSIT','QUARANTINE','LOST') NOT NULL DEFAULT 'IN_STOCK',
    item_condition ENUM('NEW','USED','DAMAGED') NOT NULL DEFAULT 'NEW',
    warehouse_id   INT NOT NULL DEFAULT 1,
    created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id)   REFERENCES Products(id)   ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(id) ON DELETE RESTRICT,
    UNIQUE KEY uk_product_manufacturer_serial (product_id, manufacturer_serial),
    KEY idx_product_items_inventory_status (warehouse_id, product_id, status, item_condition)
);

CREATE TABLE Product_Item_Movements (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    product_item_id   INT NOT NULL,
    ticket_id         INT NULL,    -- 1 FK duy nhất thay vì 2 (import_ticket_id, export_ticket_id)
    action            ENUM('IMPORT_IN','EXPORT_OUT','TRANSFER_OUT','TRANSFER_IN','RETURN_IN','QUARANTINE','STOCKTAKE_ADJUST') NOT NULL,
    from_warehouse_id INT NULL,
    to_warehouse_id   INT NOT NULL,
    condition_at_time ENUM('NEW','USED','DAMAGED') NOT NULL,
    created_at        DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by        INT NULL,
    FOREIGN KEY (product_item_id)   REFERENCES Product_Items(id) ON DELETE CASCADE,
    FOREIGN KEY (ticket_id)         REFERENCES Tickets(id)       ON DELETE RESTRICT,
    FOREIGN KEY (from_warehouse_id) REFERENCES Warehouses(id)    ON DELETE RESTRICT,
    FOREIGN KEY (to_warehouse_id)   REFERENCES Warehouses(id)    ON DELETE RESTRICT,
    FOREIGN KEY (created_by)        REFERENCES Users(id)         ON DELETE SET NULL
);

-- ========================================================
-- PART 5: NOTIFICATIONS
-- ========================================================

CREATE TABLE Notifications (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT NOT NULL,
    title      VARCHAR(150) NOT NULL,
    message    TEXT NOT NULL,
    link       VARCHAR(255) NULL,
    is_read    BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE
);

-- ========================================================
-- PART 6: INVENTORY CONTROL & AUDITING
-- ========================================================

CREATE TABLE Stocktakes (
    id                    INT AUTO_INCREMENT PRIMARY KEY,
    stocktake_code        VARCHAR(50) NOT NULL UNIQUE,
    warehouse_id          INT NOT NULL,
    scope                 ENUM('FULL','PARTIAL') NOT NULL DEFAULT 'PARTIAL',
    count_mode            ENUM('QUANTITY','SERIAL') NOT NULL DEFAULT 'QUANTITY',
    status                ENUM('DRAFT','COUNTING','SUBMITTED','L1_APPROVED','APPROVED','REJECTED','ADJUSTED','CANCELLED')
                          NOT NULL DEFAULT 'DRAFT',
    requires_l2_approval  BOOLEAN NOT NULL DEFAULT FALSE,
    variance_percent      DECIMAL(5,2) NULL,
    variance_value        DECIMAL(15,2) NULL,
    notes                 TEXT,
    reject_reason         TEXT NULL,
    verification_status   ENUM('NONE','REQUIRED','COMPLETED') NOT NULL DEFAULT 'NONE',
    verified_by           INT NULL,
    verified_at           DATETIME NULL,
    created_at            DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by            INT NOT NULL,
    counted_by            INT NULL,
    counted_at            DATETIME NULL,
    submitted_at          DATETIME NULL,
    l1_approved_by        INT NULL,
    l1_approved_at        DATETIME NULL,
    l2_approved_by        INT NULL,
    l2_approved_at        DATETIME NULL,
    adjusted_at           DATETIME NULL,
    FOREIGN KEY (warehouse_id)   REFERENCES Warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by)     REFERENCES Users(id)      ON DELETE RESTRICT,
    FOREIGN KEY (counted_by)     REFERENCES Users(id)      ON DELETE SET NULL,
    FOREIGN KEY (l1_approved_by) REFERENCES Users(id)      ON DELETE SET NULL,
    FOREIGN KEY (l2_approved_by) REFERENCES Users(id)      ON DELETE SET NULL,
    FOREIGN KEY (verified_by)    REFERENCES Users(id)      ON DELETE SET NULL
);

CREATE TABLE Stocktake_Details (
    stocktake_id    INT,
    product_id      INT,
    theoretical_qty INT NOT NULL,
    actual_qty      INT NOT NULL DEFAULT 0,
    damaged_qty     INT NOT NULL DEFAULT 0,
    theoretical_new_qty      INT NOT NULL DEFAULT 0,
    theoretical_used_qty     INT NOT NULL DEFAULT 0,
    theoretical_damaged_qty  INT NOT NULL DEFAULT 0,
    actual_new_qty           INT NOT NULL DEFAULT 0,
    actual_used_qty          INT NOT NULL DEFAULT 0,
    actual_damaged_qty       INT NOT NULL DEFAULT 0,
    variance_reason ENUM('NONE','LOST','FOUND','DAMAGED','EXPIRED','MISCOUNT','OTHER') NOT NULL DEFAULT 'NONE',
    note            VARCHAR(255) NULL,
    PRIMARY KEY (stocktake_id, product_id),
    FOREIGN KEY (stocktake_id) REFERENCES Stocktakes(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id)   REFERENCES Products(id)   ON DELETE RESTRICT
);

-- Track từng serial khi count_mode='SERIAL'
CREATE TABLE Stocktake_Items (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    stocktake_id    INT NOT NULL,
    product_item_id INT NULL,                  -- NULL khi scanned_status='EXTRA' (serial mới chưa có trong DB)
    product_id      INT NOT NULL,
    serial_number   VARCHAR(100) NOT NULL,
    scanned_status  ENUM('FOUND','MISSING','DAMAGED','EXTRA') NOT NULL,
    new_condition   ENUM('NEW','USED','DAMAGED') NULL,
    note            VARCHAR(255) NULL,
    phase           ENUM('COUNT','VERIFY') NOT NULL DEFAULT 'COUNT',
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (stocktake_id)    REFERENCES Stocktakes(id)    ON DELETE CASCADE,
    FOREIGN KEY (product_item_id) REFERENCES Product_Items(id) ON DELETE RESTRICT,
    FOREIGN KEY (product_id)      REFERENCES Products(id)      ON DELETE RESTRICT,
    UNIQUE KEY uk_stocktake_serial (stocktake_id, serial_number)
);

-- Config ngưỡng duyệt 2 cấp — chỉ Business Admin sửa được
CREATE TABLE Stocktake_Config (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    threshold_percent   DECIMAL(5,2) NOT NULL DEFAULT 5.00,
    threshold_value     DECIMAL(15,2) NOT NULL DEFAULT 10000000,
    updated_by          INT,
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (updated_by) REFERENCES Users(id) ON DELETE SET NULL
);

-- Thẻ kho — reference_id trỏ về Tickets.id; riêng transaction_type=STOCKTAKE trỏ về Stocktakes.id.
CREATE TABLE Product_Ledger (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    product_id       INT NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,  -- IMPORT, EXPORT, TRANSFER_IN, TRANSFER_OUT, RETURN, STOCKTAKE
    reference_id     INT NOT NULL,          -- ID chứng từ, xác định bảng nguồn theo transaction_type
    change_quantity          INT NOT NULL,
    balance_quantity         INT NOT NULL,
    change_new_quantity      INT NULL,
    change_used_quantity     INT NULL,
    change_damaged_quantity  INT NULL,
    balance_new_quantity     INT NULL,
    balance_used_quantity    INT NULL,
    balance_damaged_quantity INT NULL,
    warehouse_id             INT NOT NULL DEFAULT 1,
    created_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by       INT,
    KEY idx_ledger_report_date_wh_product (created_at, warehouse_id, product_id, id),
    KEY idx_ledger_snapshot_wh_product_date (warehouse_id, product_id, created_at, id),
    FOREIGN KEY (product_id)   REFERENCES Products(id)   ON DELETE CASCADE,
    FOREIGN KEY (created_by)   REFERENCES Users(id)      ON DELETE SET NULL,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(id) ON DELETE CASCADE
);

CREATE TABLE Inventory_Daily_Snapshots (
    snapshot_date DATE NOT NULL,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    last_ledger_id INT NOT NULL,
    new_quantity INT NOT NULL DEFAULT 0,
    used_quantity INT NOT NULL DEFAULT 0,
    damaged_quantity INT NOT NULL DEFAULT 0,
    total_quantity INT NOT NULL DEFAULT 0,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (snapshot_date, warehouse_id, product_id),
    KEY idx_daily_snapshot_lookup (warehouse_id, product_id, snapshot_date),
    CONSTRAINT fk_daily_snapshot_warehouse FOREIGN KEY (warehouse_id) REFERENCES Warehouses(id) ON DELETE CASCADE,
    CONSTRAINT fk_daily_snapshot_product FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE
);

CREATE TABLE Inventory_Daily_Movements (
    movement_date DATE NOT NULL,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    import_new INT NOT NULL DEFAULT 0,
    export_new INT NOT NULL DEFAULT 0,
    import_used INT NOT NULL DEFAULT 0,
    export_used INT NOT NULL DEFAULT 0,
    import_damaged INT NOT NULL DEFAULT 0,
    export_damaged INT NOT NULL DEFAULT 0,
    adjustment_new INT NOT NULL DEFAULT 0,
    adjustment_used INT NOT NULL DEFAULT 0,
    adjustment_damaged INT NOT NULL DEFAULT 0,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (movement_date, warehouse_id, product_id),
    KEY idx_daily_movement_lookup (warehouse_id, product_id, movement_date),
    CONSTRAINT fk_daily_movement_warehouse FOREIGN KEY (warehouse_id) REFERENCES Warehouses(id) ON DELETE CASCADE,
    CONSTRAINT fk_daily_movement_product FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE
);

CREATE TABLE Reporting_Rollup_State (
    rollup_name VARCHAR(60) NOT NULL,
    coverage_start DATE NOT NULL,
    last_processed_ledger_id INT NOT NULL DEFAULT 0,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (rollup_name)
);

-- ========================================================
-- PART 7: SYSTEM MONITORING
-- ========================================================

CREATE TABLE Audit_Logs (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT,
    action     VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    details    TEXT,
    KEY idx_audit_logs_created_at_id (created_at, id),
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE SET NULL
);

-- Keep daily reporting tables synchronized with every new ledger row.
DELIMITER $$
CREATE TRIGGER trg_product_ledger_reporting_rollup
AFTER INSERT ON Product_Ledger
FOR EACH ROW
BEGIN
    INSERT INTO Inventory_Daily_Snapshots (
        snapshot_date, warehouse_id, product_id, last_ledger_id,
        new_quantity, used_quantity, damaged_quantity, total_quantity
    ) VALUES (
        DATE(NEW.created_at), NEW.warehouse_id, NEW.product_id, NEW.id,
        IFNULL(NEW.balance_new_quantity, IFNULL(NEW.balance_quantity, 0)),
        IFNULL(NEW.balance_used_quantity, 0),
        IFNULL(NEW.balance_damaged_quantity, 0),
        IFNULL(NEW.balance_quantity,
            IFNULL(NEW.balance_new_quantity, 0) + IFNULL(NEW.balance_used_quantity, 0) + IFNULL(NEW.balance_damaged_quantity, 0))
    ) ON DUPLICATE KEY UPDATE
        last_ledger_id = IF(VALUES(last_ledger_id) >= last_ledger_id, VALUES(last_ledger_id), last_ledger_id),
        new_quantity = IF(VALUES(last_ledger_id) >= last_ledger_id, VALUES(new_quantity), new_quantity),
        used_quantity = IF(VALUES(last_ledger_id) >= last_ledger_id, VALUES(used_quantity), used_quantity),
        damaged_quantity = IF(VALUES(last_ledger_id) >= last_ledger_id, VALUES(damaged_quantity), damaged_quantity),
        total_quantity = IF(VALUES(last_ledger_id) >= last_ledger_id, VALUES(total_quantity), total_quantity);

    IF NEW.transaction_type <> 'OPENING_BALANCE' THEN
        INSERT INTO Inventory_Daily_Movements (
            movement_date, warehouse_id, product_id,
            import_new, export_new, import_used, export_used, import_damaged, export_damaged,
            adjustment_new, adjustment_used, adjustment_damaged
        ) VALUES (
            DATE(NEW.created_at), NEW.warehouse_id, NEW.product_id,
            IF(NEW.transaction_type IN ('IMPORT','RETURN','TRANSFER_IN','TRANSFER_RETURN'),
                GREATEST(IFNULL(NEW.change_new_quantity, IFNULL(NEW.change_quantity, 0)), 0), 0),
            IF(NEW.transaction_type IN ('EXPORT','TRANSFER_OUT','TRANSFER_RETURN_OUT'),
                GREATEST(-IFNULL(NEW.change_new_quantity, IFNULL(NEW.change_quantity, 0)), 0), 0),
            IF(NEW.transaction_type IN ('IMPORT','RETURN','TRANSFER_IN','TRANSFER_RETURN'),
                GREATEST(IFNULL(NEW.change_used_quantity, 0), 0), 0),
            IF(NEW.transaction_type IN ('EXPORT','TRANSFER_OUT','TRANSFER_RETURN_OUT'),
                GREATEST(-IFNULL(NEW.change_used_quantity, 0), 0), 0),
            IF(NEW.transaction_type IN ('IMPORT','RETURN','TRANSFER_IN','TRANSFER_RETURN'),
                GREATEST(IFNULL(NEW.change_damaged_quantity, 0), 0), 0),
            IF(NEW.transaction_type IN ('EXPORT','TRANSFER_OUT','TRANSFER_RETURN_OUT'),
                GREATEST(-IFNULL(NEW.change_damaged_quantity, 0), 0), 0),
            IF(NEW.transaction_type = 'STOCKTAKE', IFNULL(NEW.change_new_quantity, IFNULL(NEW.change_quantity, 0)), 0),
            IF(NEW.transaction_type = 'STOCKTAKE', IFNULL(NEW.change_used_quantity, 0), 0),
            IF(NEW.transaction_type = 'STOCKTAKE', IFNULL(NEW.change_damaged_quantity, 0), 0)
        ) ON DUPLICATE KEY UPDATE
            import_new = import_new + VALUES(import_new),
            export_new = export_new + VALUES(export_new),
            import_used = import_used + VALUES(import_used),
            export_used = export_used + VALUES(export_used),
            import_damaged = import_damaged + VALUES(import_damaged),
            export_damaged = export_damaged + VALUES(export_damaged),
            adjustment_new = adjustment_new + VALUES(adjustment_new),
            adjustment_used = adjustment_used + VALUES(adjustment_used),
            adjustment_damaged = adjustment_damaged + VALUES(adjustment_damaged);
    END IF;

    INSERT INTO Reporting_Rollup_State (rollup_name, coverage_start, last_processed_ledger_id)
    VALUES ('LEDGER_DAILY', DATE(NEW.created_at), NEW.id)
    ON DUPLICATE KEY UPDATE
        coverage_start = LEAST(coverage_start, VALUES(coverage_start)),
        last_processed_ledger_id = GREATEST(last_processed_ledger_id, VALUES(last_processed_ledger_id));
END$$
DELIMITER ;


-- ========================================================
-- DATA SEEDING
-- ========================================================

-- Roles
INSERT INTO Roles (id, role_name, description, status) VALUES
(1, 'System Admin',      'Phòng IT - quản trị hệ thống, người dùng, phân quyền',              TRUE),
(2, 'Business Admin',    'Giám đốc - phê duyệt phiếu, xem báo cáo tổng quan',                  TRUE),
(3, 'Warehouse Manager', 'Quản lý kho - quản lý master data, giám sát kho và duyệt kiểm kê',   TRUE),
(4, 'Warehouse Staff',   'Thủ kho - tạo phiếu nhập/xuất, đếm kiểm kê',                        TRUE),
(5, 'Sales Staff',       'Nhân viên KD - tạo yêu cầu xuất/nhập, quản lý NCC/KH',               TRUE);

-- Permissions (gộp/đổi tên cho schema v3)
INSERT INTO Permissions (id, permission_name, description) VALUES
-- System Admin
(1,  'USER_VIEW',                 'Xem danh sách và thông tin người dùng'),
(2,  'USER_ADD',                  'Thêm mới người dùng'),
(3,  'USER_EDIT',                 'Sửa thông tin người dùng'),
(4,  'USER_TOGGLE',               'Tắt/Bật trạng thái người dùng'),
(5,  'ROLE_VIEW',                 'Xem danh sách vai trò hệ thống'),
(6,  'ROLE_ADD',                  'Thêm mới vai trò'),
(7,  'ROLE_EDIT',                 'Sửa tên vai trò'),
(8,  'ROLE_TOGGLE',               'Tắt/Bật trạng thái vai trò'),
(9,  'ROLE_ASSIGN',               'Phân quyền (Permissions) cho vai trò'),
(10, 'AUDIT_LOG_VIEW',            'Xem nhật ký kiểm toán'),
-- Master Data
(11, 'SUPPLIER_VIEW',             'Xem danh sách nhà cung cấp'),
(12, 'SUPPLIER_ADD',              'Thêm mới nhà cung cấp'),
(13, 'SUPPLIER_EDIT',             'Sửa nhà cung cấp'),
(14, 'SUPPLIER_TOGGLE',           'Tắt/Bật trạng thái nhà cung cấp'),
(15, 'PRODUCT_VIEW',              'Xem danh sách và chi tiết sản phẩm'),
(16, 'PRODUCT_ADD',               'Thêm mới sản phẩm'),
(17, 'PRODUCT_EDIT',              'Sửa sản phẩm'),
(18, 'PRODUCT_TOGGLE',            'Tắt/Bật sản phẩm'),
(19, 'CATEGORY_VIEW',             'Xem danh sách ngành hàng'),
(20, 'CATEGORY_ADD',              'Thêm mới ngành hàng'),
(21, 'CATEGORY_EDIT',             'Sửa ngành hàng'),
(22, 'CATEGORY_TOGGLE',           'Tắt/Bật ngành hàng'),
(23, 'BRAND_VIEW',                'Xem danh sách thương hiệu'),
(24, 'BRAND_ADD',                 'Thêm mới thương hiệu'),
(25, 'BRAND_EDIT',                'Sửa thương hiệu'),
(26, 'BRAND_TOGGLE',              'Tắt/Bật thương hiệu'),
(27, 'DESTINATION_VIEW',          'Xem danh sách điểm nhận nội bộ'),
(28, 'DESTINATION_ADD',           'Thêm điểm nhận nội bộ'),
(29, 'DESTINATION_EDIT',          'Sửa điểm nhận nội bộ'),
(30, 'DESTINATION_TOGGLE',        'Tắt/Bật điểm nhận nội bộ'),
-- Requests IN (gộp từ IMPORT_REQ_*)
(31, 'REQUEST_VIEW_IN',           'Xem yêu cầu nhập kho'),
(32, 'REQUEST_ADD_IN',            'Tạo yêu cầu nhập kho'),
(33, 'REQUEST_EDIT_IN',           'Sửa yêu cầu nhập kho'),
(34, 'REQUEST_CANCEL_IN',         'Hủy yêu cầu nhập kho'),
(35, 'REQUEST_APPROVE_IN',        'Duyệt/từ chối yêu cầu nhập kho'),
(36, 'REQUEST_REQUEST_CANCEL_IN', 'Đề xuất hủy yêu cầu nhập đã duyệt'),
(37, 'REQUEST_APPROVE_CANCEL_IN', 'Duyệt yêu cầu hủy nhập'),
-- Requests OUT (gộp từ EXPORT_REQ_*)
(38, 'REQUEST_VIEW_OUT',          'Xem yêu cầu xuất kho'),
(39, 'REQUEST_ADD_OUT',           'Tạo yêu cầu xuất kho'),
(40, 'REQUEST_EDIT_OUT',          'Sửa yêu cầu xuất kho'),
(41, 'REQUEST_CANCEL_OUT',        'Hủy yêu cầu xuất kho'),
(42, 'REQUEST_APPROVE_OUT',       'Duyệt/từ chối yêu cầu xuất kho'),
(43, 'REQUEST_REQUEST_CANCEL_OUT','Đề xuất hủy yêu cầu xuất đã duyệt'),
(44, 'REQUEST_APPROVE_CANCEL_OUT','Duyệt yêu cầu hủy xuất'),
-- Tickets IN (gộp từ IMPORT_TICKET_*)
(45, 'TICKET_VIEW_IN',            'Xem phiếu nhập kho'),
(46, 'TICKET_ADD_IN',             'Tạo phiếu nhập kho'),
(47, 'TICKET_CONFIRM_IN',         'Confirm phiếu nhập, chốt tồn'),
(48, 'TICKET_CANCEL_IN',          'Hủy phiếu nhập kho'),
-- Tickets OUT (gộp từ EXPORT_TICKET_*)
(49, 'TICKET_VIEW_OUT',           'Xem phiếu xuất kho'),
(50, 'TICKET_ADD_OUT',            'Tạo phiếu xuất kho'),
(51, 'TICKET_CONFIRM_OUT',        'Confirm phiếu xuất, chốt tồn'),
(52, 'TICKET_CANCEL_OUT',         'Hủy phiếu xuất kho'),
-- Stocktake
(53, 'STOCKTAKE_VIEW',            'Xem danh sách và chi tiết phiếu kiểm kê'),
(54, 'STOCKTAKE_CREATE',          'Tạo phiếu kiểm kê (Warehouse Manager)'),
(55, 'STOCKTAKE_COUNT',           'Đếm thực tế trên phiếu (Warehouse Staff)'),
(56, 'STOCKTAKE_SUBMIT',          'Gửi phiếu đếm xong lên duyệt'),
(57, 'STOCKTAKE_APPROVE_L1',      'Duyệt cấp 1 phiếu kiểm kê (Warehouse Manager)'),
(58, 'STOCKTAKE_REJECT',          'Bác bỏ phiếu kiểm kê'),
-- Analytics
(59, 'STOCK_LEDGER_VIEW',         'Xem lịch sử thẻ kho'),
(60, 'LOW_STOCK_ALERT_VIEW',      'Xem cảnh báo tồn thấp'),
(61, 'DASHBOARD_VIEW',            'Xem dashboard tổng quan'),
(62, 'INVENTORY_VALUE_VIEW',      'Xem báo cáo giá trị kho'),
-- Customer
(63, 'CUSTOMER_VIEW',             'Xem danh sách khách hàng'),
(64, 'CUSTOMER_ADD',              'Thêm khách hàng mới'),
(65, 'CUSTOMER_EDIT',             'Chỉnh sửa thông tin khách hàng'),
(66, 'CUSTOMER_DELETE',           'Xóa khách hàng'),
-- Warehouse
(67, 'WAREHOUSE_VIEW',            'Xem danh sách kho hàng'),
(68, 'WAREHOUSE_ADD',             'Thêm kho hàng mới'),
(69, 'WAREHOUSE_EDIT',            'Chỉnh sửa và đổi trạng thái kho'),
-- Stocktake duyệt cấp 2 + config (Business Admin)
(70, 'STOCKTAKE_APPROVE_L2',      'Duyệt cấp 2 khi chênh lệch vượt ngưỡng (Business Admin)'),
(71, 'STOCKTAKE_CONFIG',          'Sửa ngưỡng duyệt 2 cấp kiểm kê (Business Admin)'),
-- Inventory (tách khỏi Product)
(72, 'INVENTORY_VIEW',            'Xem tồn kho theo từng warehouse'),
(73, 'INVENTORY_EXPORT',          'Xuất báo cáo tồn kho'),
(74, 'INVENTORY_VIEW_ALL',        'Xem tồn kho tất cả các kho (không bị giới hạn theo kho được gắn)'),
(75, 'SYSTEM_LOG_VIEW',           'Xem nhật ký hệ thống (người dùng, vai trò, phân quyền, mật khẩu) — System Admin');

-- Role_Permissions
-- 1. System Admin (IT — kỹ thuật; KHÔNG có AUDIT_LOG_VIEW nghiệp vụ, thay bằng SYSTEM_LOG_VIEW)
INSERT INTO Role_Permissions (role_id, permission_id) VALUES
(1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(1,7),(1,8),(1,9),(1,75);

-- 2. Business Admin (giám đốc duyệt) — bao gồm STOCKTAKE_APPROVE_L2 + STOCKTAKE_CONFIG
INSERT INTO Role_Permissions (role_id, permission_id) VALUES
(2,10),(2,11),(2,15),(2,19),(2,23),(2,27),
(2,31),(2,35),(2,37),(2,38),(2,42),(2,44),
(2,45),(2,49),(2,53),(2,58),(2,70),(2,71),(2,72),(2,73),
(2,59),(2,60),(2,61),(2,62),
(2,63),(2,64),(2,65),(2,66),(2,67);

-- 3. Warehouse Manager (master data, giám sát kho, tạo+duyệt L1 kiểm kê — không confirm/cancel phiếu)
INSERT INTO Role_Permissions (role_id, permission_id) VALUES
(3,11),(3,12),(3,13),(3,14),(3,15),(3,16),(3,17),(3,18),
(3,19),(3,20),(3,21),(3,22),(3,23),(3,24),(3,25),(3,26),
(3,27),(3,28),(3,29),(3,30),
(3,31),(3,38),
(3,45),(3,49),
(3,53),(3,54),(3,57),(3,58),(3,59),(3,60),
(3,63),(3,67),(3,69),(3,72),(3,73);

-- 4. Warehouse Staff (tạo + confirm + cancel phiếu nhập/xuất, đếm kiểm kê)
INSERT INTO Role_Permissions (role_id, permission_id) VALUES
(4,11),(4,15),(4,19),(4,23),(4,27),
(4,45),(4,46),(4,47),(4,48),(4,49),(4,50),(4,51),(4,52),
(4,53),(4,55),(4,56),
(4,59),(4,72),
(4,31),(4,38);

-- 5. Sales Staff (tạo yêu cầu, quản lý NCC/KH)
INSERT INTO Role_Permissions (role_id, permission_id) VALUES
(5,11),(5,12),(5,13),(5,14),
(5,15),(5,19),(5,23),
(5,31),(5,32),(5,33),(5,34),(5,36),
(5,38),(5,39),(5,40),(5,41),(5,43),
(5,45),(5,49),
(5,63),(5,64),(5,65);

-- Warehouses
INSERT INTO Warehouses (id, warehouse_name, address, status) VALUES
(1, 'Kho Hà Nội',  '123 Đường Cầu Giấy, Hà Nội',  TRUE),
(2, 'Kho TP.HCM',  '456 Đường Cộng Hòa, TP.HCM',   TRUE);

-- Users (password '123456' SHA-256)
INSERT INTO Users (id, username, password, email, full_name, status, role_id, warehouse_id) VALUES
(1, 'khachung',   '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'khachung@wms.local',   'Kha Chung',   TRUE, 1, NULL),
(2, 'leduy',      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'leduy@wms.local',     'Le Duy',      TRUE, 2, NULL),
(3, 'phuonglinh', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'phuonglinh@wms.local','Phuong Linh', TRUE, 3, 1),
(4, 'thanhhung',  '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'thanhhung@wms.local', 'Thanh Hung',  TRUE, 4, 1),
(5, 'vietanh',    '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'vietanh@wms.local',   'Viet Anh',    TRUE, 5, NULL),
(6, 'quanlikhohcm','8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'qlkho.hcm@wms.local', 'Quan Ly Kho HCM', TRUE, 3, 2),
(7, 'thukhohcm',   '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'thukho.hcm@wms.local','Thu Kho HCM',     TRUE, 4, 2),
(8, 'salehcm',    '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'sales.hcm@wms.local', 'Sales HCM',       TRUE, 5, NULL);

-- Suppliers
INSERT INTO Suppliers (id, supplier_name, contact_name, phone, email, address, status) VALUES
(1, 'Công ty Thiết bị Điện lạnh Hoà Phát',  'Nguyễn Văn Hoà', '0912345678', 'hoaphat@dienlanh.vn',        '123 Đường Giải Phóng, Hai Bà Trưng, Hà Nội',     TRUE),
(2, 'Tổng kho Phân phối Daikin Việt Nam',   'Trần Thế Minh',  '0987654321', 'sales@daikindistributor.vn', '456 Đường Nguyễn Văn Linh, Long Biên, Hà Nội',   TRUE),
(3, 'Nhà phân phối Điện máy Panasonic',     'Lê Thuỳ Trang',  '0901234567', 'contact@panasonic-dist.vn',  '789 Đường Cộng Hoà, Tân Bình, TP. Hồ Chí Minh',  TRUE);

-- Categories
INSERT INTO Categories (id, category_name, description, status) VALUES
(1, 'Điều hòa',  'Máy điều hòa không khí, máy lạnh treo tường, âm trần', TRUE),
(2, 'Tủ lạnh',   'Tủ lạnh gia đình, tủ mát, tủ cấp đông',                TRUE),
(3, 'Máy giặt',  'Máy giặt lồng đứng, lồng ngang và máy sấy',            TRUE);

-- Brands
INSERT INTO Brands (id, brand_name, description, status) VALUES
(1, 'Panasonic',  'Thương hiệu điện máy gia dụng Nhật Bản',      TRUE),
(2, 'Daikin',     'Thương hiệu điều hòa hàng đầu từ Nhật Bản',   TRUE),
(3, 'LG',         'Thương hiệu thiết bị gia dụng Hàn Quốc',      TRUE),
(4, 'Samsung',    'Tập đoàn công nghệ & gia dụng Hàn Quốc',      TRUE),
(5, 'Electrolux', 'Thương hiệu gia dụng Thụy Điển',              TRUE);

-- Customers
INSERT INTO Customers (id, customer_name, phone, email, address, external_ref) VALUES
(1, 'Nguyễn Văn An',  '0912345678', 'vanan@gmail.com',   '12 Nguyễn Trãi, Thanh Xuân, Hà Nội',  NULL),
(2, 'Trần Thị Bình',  '0987654321', 'thibinh@gmail.com', '45 Lê Lợi, Quận 1, TP.HCM',           NULL),
(3, 'Lê Minh Cường',  '0901234567', NULL,                '78 Trần Phú, Đà Nẵng',                NULL);

-- Internal_Destinations
INSERT INTO Internal_Destinations (id, destination_name, destination_type, address, status) VALUES
(1, 'Showroom Cầu Giấy Hà Nội',    'SHOWROOM',        '100 Đường Cầu Giấy, Cầu Giấy, Hà Nội',      TRUE),
(2, 'Showroom Lê Lợi TP. HCM',     'SHOWROOM',        '200 Đường Lê Lợi, Quận 1, TP. Hồ Chí Minh', TRUE),
(3, 'Trung tâm Bảo hành Miền Bắc', 'WARRANTY_CENTER', '50 Đường Trường Chinh, Đống Đa, Hà Nội',     TRUE);

-- Products
INSERT INTO Products (id, product_name, sku, unit, min_stock, average_cost, status, category_id, brand_id) VALUES
(1, 'Điều hòa Panasonic Inverter 9000 BTU',  'PANA-9000',    'cái', 5, 8500000.00,  TRUE, 1, 1),
(2, 'Điều hòa Daikin Inverter 12000 BTU',    'DAIKIN-12000', 'cái', 5, 11200000.00, TRUE, 1, 2),
(3, 'Tủ lạnh LG Inverter 635 Lít',           'LG-635L',      'cái', 3, 20415000.00, TRUE, 2, 3),
(4, 'Tủ lạnh Samsung Inverter 236 Lít',      'SAMSUNG-236L', 'cái', 5, 6150000.00,  TRUE, 2, 4),
(5, 'Máy giặt Electrolux lồng ngang 9 Kg',   'ELEC-9KG',     'cái', 4, 10800000.00, TRUE, 3, 5),
(6, 'Máy giặt LG lồng ngang Inverter 10 Kg', 'LG-10KG',      'cái', 5, 8990000.00,  TRUE, 3, 3);

-- Specifications
INSERT INTO Product_Specifications (product_id, spec_key, spec_value) VALUES
(1, 'Công suất', '9000 BTU (1 HP)'),
(1, 'Tiêu thụ', '0.8 kW/h'),
(1, 'Công nghệ', 'Nanoe-G, Inverter'),
(2, 'Công suất', '12000 BTU (1.5 HP)'),
(2, 'Tiêu thụ', '1.1 kW/h'),
(2, 'Đặc điểm', 'Luồng gió Coanda'),
(3, 'Kiểu tủ', 'Side by Side'),
(3, 'Dung tích', '635 Lít'),
(3, 'Công nghệ', 'InstaView Door-in-Door, Hygiene Fresh+'),
(4, 'Kiểu tủ', 'Ngăn đá trên'),
(4, 'Dung tích', '236 Lít'),
(4, 'Công nghệ', 'Optimal Fresh Zone'),
(5, 'Kiểu máy', 'Lồng ngang'),
(5, 'Khối lượng giặt', '9 Kg'),
(5, 'Tốc độ vắt', '1200 v/p'),
(5, 'Công nghệ', 'UltraMix, Hygienic Care'),
(6, 'Kiểu máy', 'Lồng ngang'),
(6, 'Khối lượng giặt', '10 Kg'),
(6, 'Tốc độ vắt', '1400 v/p'),
(6, 'Công nghệ', 'AI DD cảm biến vải');

-- Tồn cuối kỳ của bộ seed; phải khớp tuyệt đối với Product_Items bên dưới.
INSERT INTO Inventories (warehouse_id, product_id, quantity, quarantine_quantity) VALUES
(1,1,13,0),(1,2,8,0),(1,3,23,0),(1,4,2,1),(1,5,10,0),(1,6,3,0),
(2,1,0,0),(2,2,0,0),(2,3,0,0),(2,4,0,0),(2,5,2,0),(2,6,0,0);

-- ========================================================
-- SEED: WORKFLOW NGHIỆP VỤ NHẬP / XUẤT / CHUYỂN KHO
-- Mỗi trạng thái đều có dữ liệu vật lý, movement và ledger tương ứng.
-- ========================================================

-- Nhập tồn đầu kỳ: được ghi nhận trước toàn bộ nghiệp vụ mẫu năm 2026.
INSERT INTO Requests (id, request_code, type, reason, warehouse_id, partner_type, partner_id, staff_id, status, created_at, expected_date, approved_by, approved_at) VALUES
(2, 'REQ-IN-2026-0002', 'IN', 'PURCHASE', 1, 'SUPPLIER', 1, 5, 'COMPLETED', '2025-12-15 08:00:00', '2025-12-16', 2, '2025-12-15 09:00:00');
INSERT INTO Request_Details (request_id, product_id, quantity, unit_price) VALUES
(2,1,15,8500000.00),(2,2,10,11200000.00),(2,3,4,22490000.00),
(2,4,2,6150000.00),(2,5,12,10800000.00),(2,6,3,8990000.00);
INSERT INTO Tickets (id, ticket_code, type, request_id, warehouse_id, keeper_id, status, created_at, confirmed_by, confirmed_at) VALUES
(2, 'TKT-IN-2026-0002', 'IN', 2, 1, 4, 'CONFIRMED', '2025-12-16 09:30:00', 4, '2025-12-16 10:00:00');
INSERT INTO Ticket_Details (ticket_id, product_id, quantity, unit_cost) VALUES
(2,1,15,8500000.00),(2,2,10,11200000.00),(2,3,4,22490000.00),
(2,4,2,6150000.00),(2,5,12,10800000.00),(2,6,3,8990000.00);

-- Nhập mua 50, đã nhận 20: phải là PARTIALLY_COMPLETED, không phải APPROVED.
INSERT INTO Requests (id, request_code, type, reason, warehouse_id, partner_type, partner_id, staff_id, status, expected_date, approved_by, approved_at) VALUES
(1, 'REQ-IN-2026-0001', 'IN', 'PURCHASE', 1, 'SUPPLIER', 3, 5, 'PARTIALLY_COMPLETED', '2026-02-15', 2, '2026-02-01 09:00:00');
INSERT INTO Request_Details (request_id, product_id, quantity, unit_price) VALUES (1,3,50,20000000.00);
INSERT INTO Tickets (id, ticket_code, type, request_id, warehouse_id, keeper_id, status, confirmed_by, confirmed_at) VALUES
(1, 'TKT-IN-2026-0001', 'IN', 1, 1, 4, 'CONFIRMED', 4, '2026-02-05 14:30:00');
INSERT INTO Ticket_Details (ticket_id, product_id, quantity, unit_cost) VALUES (1,3,20,20000000.00);

-- Các trạng thái cơ bản của yêu cầu nhập chưa phát sinh hoặc đã dừng xử lý.
INSERT INTO Requests (id, request_code, type, reason, warehouse_id, partner_type, partner_id, staff_id, status, expected_date, approved_by, approved_at, cancelled_by, cancelled_at, cancel_reason) VALUES
(3, 'REQ-IN-2026-0003', 'IN','PURCHASE',1,'SUPPLIER',2,5,'PENDING',   '2026-08-01',NULL,NULL,NULL,NULL,NULL),
(4, 'REQ-IN-2026-0004', 'IN','PURCHASE',1,'SUPPLIER',2,5,'REVOKED',   '2026-03-10',NULL,NULL,5,'2026-03-02 08:30:00','Người tạo thu hồi trước khi duyệt'),
(5, 'REQ-IN-2026-0005', 'IN','PURCHASE',1,'SUPPLIER',2,5,'REJECTED',  '2026-03-12',2,'2026-03-03 09:00:00',NULL,NULL,NULL),
(6, 'REQ-IN-2026-0006', 'IN','PURCHASE',1,'SUPPLIER',2,5,'CANCELLED', '2026-03-15',2,'2026-03-04 09:00:00',2,'2026-03-05 10:00:00','Hủy sau duyệt, chưa nhận hàng');
INSERT INTO Request_Details (request_id, product_id, quantity, unit_price) VALUES
(3,2,5,10800000.00),(4,2,2,10800000.00),(5,5,3,10400000.00),(6,6,2,8600000.00);

-- Nhập một phần rồi đóng phần còn lại.
INSERT INTO Requests (id, request_code, type, reason, warehouse_id, partner_type, partner_id, staff_id, requested_condition, status, expected_date, approved_by, approved_at, cancel_requested_by, cancel_requested_at, cancel_reason, cancelled_by, cancelled_at) VALUES
(7,'REQ-IN-2026-0007','IN','PURCHASE',1,'SUPPLIER',1,5,'NEW','PARTIALLY_CLOSED','2026-03-20',2,'2026-03-10 09:00:00',5,'2026-03-22 08:00:00','Nhà cung cấp chỉ giao được một phần',2,'2026-03-22 09:00:00');
INSERT INTO Request_Details VALUES (7,6,3,8500000.00);
INSERT INTO Tickets (id,ticket_code,type,request_id,warehouse_id,keeper_id,status,confirmed_by,confirmed_at) VALUES
(7,'TKT-IN-2026-0003','IN',7,1,4,'CONFIRMED',4,'2026-03-20 14:00:00');
INSERT INTO Ticket_Details VALUES (7,6,1,8500000.00);

-- Một sản phẩm nhận vào ở tình trạng hỏng, đưa thẳng vào khu cách ly.
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,staff_id,requested_condition,status,expected_date,approved_by,approved_at) VALUES
(8,'REQ-IN-2026-0008','IN','PURCHASE',1,'SUPPLIER',1,5,'DAMAGED','COMPLETED','2026-03-25',2,'2026-03-18 09:00:00');
INSERT INTO Request_Details VALUES (8,4,1,5900000.00);
INSERT INTO Tickets (id,ticket_code,type,request_id,warehouse_id,keeper_id,status,confirmed_by,confirmed_at) VALUES
(8,'TKT-IN-2026-0004','IN',8,1,4,'CONFIRMED',4,'2026-03-25 15:00:00');
INSERT INTO Ticket_Details VALUES (8,4,1,5900000.00);

-- Xuất bán hoàn thành và xuất bán một phần rồi đóng phần còn lại.
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,shipping_address,staff_id,status,expected_date,approved_by,approved_at) VALUES
(10,'REQ-OUT-2026-0001','OUT','CUSTOMER_SALE',1,'CUSTOMER',1,'12 Nguyễn Trãi, Thanh Xuân, Hà Nội',5,'COMPLETED','2026-04-05',2,'2026-04-01 09:00:00');
INSERT INTO Request_Details VALUES (10,1,2,NULL);
INSERT INTO Tickets (id,ticket_code,type,request_id,warehouse_id,keeper_id,status,confirmed_by,confirmed_at) VALUES
(10,'TKT-OUT-2026-0001','OUT',10,1,4,'CONFIRMED',4,'2026-04-05 10:00:00');
INSERT INTO Ticket_Details VALUES (10,1,2,8500000.00);

INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,shipping_address,staff_id,status,expected_date,approved_by,approved_at,cancel_requested_by,cancel_requested_at,cancel_reason,cancelled_by,cancelled_at) VALUES
(11,'REQ-OUT-2026-0002','OUT','CUSTOMER_SALE',1,'CUSTOMER',2,'45 Lê Lợi, Quận 1, TP.HCM',5,'PARTIALLY_CLOSED','2026-04-10',2,'2026-04-02 09:00:00',5,'2026-04-11 08:00:00','Khách giảm số lượng sau khi đã giao một phần',2,'2026-04-11 09:00:00');
INSERT INTO Request_Details VALUES (11,1,3,NULL);
INSERT INTO Tickets (id,ticket_code,type,request_id,warehouse_id,keeper_id,status,confirmed_by,confirmed_at) VALUES
(11,'TKT-OUT-2026-0002','OUT',11,1,4,'CONFIRMED',4,'2026-04-10 10:00:00');
INSERT INTO Ticket_Details VALUES (11,1,1,8500000.00);

-- Trả lại một serial từ phiếu bán đã hoàn thành; hàng quay về ở tình trạng USED.
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,ref_ticket_id,return_reason,staff_id,requested_condition,status,expected_date,approved_by,approved_at) VALUES
(18,'REQ-IN-2026-0009','IN','RETURN',1,'CUSTOMER',1,10,'CUSTOMER_REJECTION',5,'USED','COMPLETED','2026-04-08',2,'2026-04-07 09:00:00');
INSERT INTO Request_Details VALUES (18,1,1,NULL);
INSERT INTO Tickets (id,ticket_code,type,request_id,warehouse_id,keeper_id,status,confirmed_by,confirmed_at) VALUES
(18,'TKT-IN-2026-0005','IN',18,1,4,'CONFIRMED',4,'2026-04-08 14:00:00');
INSERT INTO Ticket_Details VALUES (18,1,1,8500000.00);

-- Các trạng thái cơ bản của yêu cầu xuất chưa phát sinh chuyển động hàng.
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,shipping_address,staff_id,status,expected_date,approved_by,approved_at,cancelled_by,cancelled_at,cancel_reason) VALUES
(12,'REQ-OUT-2026-0003','OUT','CUSTOMER_SALE',1,'CUSTOMER',3,'78 Trần Phú, Đà Nẵng',5,'PENDING',  '2026-08-05',NULL,NULL,NULL,NULL,NULL),
(13,'REQ-OUT-2026-0004','OUT','CUSTOMER_SALE',1,'CUSTOMER',3,'78 Trần Phú, Đà Nẵng',5,'APPROVED', '2026-08-07',2,'2026-07-15 09:00:00',NULL,NULL,NULL),
(14,'REQ-OUT-2026-0005','OUT','CUSTOMER_SALE',1,'CUSTOMER',3,'78 Trần Phú, Đà Nẵng',5,'REVOKED',  '2026-05-05',NULL,NULL,5,'2026-05-01 08:00:00','Người tạo thu hồi trước duyệt'),
(15,'REQ-OUT-2026-0006','OUT','CUSTOMER_SALE',1,'CUSTOMER',3,'78 Trần Phú, Đà Nẵng',5,'REJECTED', '2026-05-06',2,'2026-05-02 09:00:00',NULL,NULL,NULL),
(16,'REQ-OUT-2026-0007','OUT','CUSTOMER_SALE',1,'CUSTOMER',3,'78 Trần Phú, Đà Nẵng',5,'CANCELLED','2026-05-07',2,'2026-05-03 09:00:00',2,'2026-05-04 09:00:00','Hủy sau duyệt, chưa xuất hàng');
INSERT INTO Request_Details (request_id,product_id,quantity,unit_price) VALUES
(12,2,1,NULL),(13,2,1,NULL),(14,2,1,NULL),(15,2,1,NULL),(16,2,1,NULL);

-- Chuyển kho đang đi: nguồn IN_TRANSIT, yêu cầu nhập đích auto-approved.
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,staff_id,status,expected_date,approved_by,approved_at) VALUES
(20,'REQ-OUT-2026-0008','OUT','TRANSFER',1,'WAREHOUSE',2,5,'IN_TRANSIT','2026-05-15',2,'2026-05-10 09:00:00');
INSERT INTO Request_Details VALUES (20,2,2,NULL);
INSERT INTO Tickets (id,ticket_code,type,request_id,warehouse_id,keeper_id,status,confirmed_by,confirmed_at) VALUES
(20,'TKT-OUT-2026-0003','OUT',20,1,4,'IN_TRANSIT',4,'2026-05-12 10:00:00');
INSERT INTO Ticket_Details VALUES (20,2,2,11200000.00);
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,ref_ticket_id,staff_id,status,expected_date,approved_by,approved_at,auto_approved) VALUES
(21,'REQ-IN-2026-0010','IN','TRANSFER',2,'WAREHOUSE',1,20,5,'APPROVED','2026-05-15',2,'2026-05-12 10:00:00',TRUE);
INSERT INTO Request_Details VALUES (21,2,2,NULL);

-- Chuyển kho đã được kho đích nhận đủ.
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,staff_id,status,expected_date,approved_by,approved_at) VALUES
(22,'REQ-OUT-2026-0009','OUT','TRANSFER',1,'WAREHOUSE',2,5,'COMPLETED','2026-05-20',2,'2026-05-15 09:00:00');
INSERT INTO Request_Details VALUES (22,5,2,NULL);
INSERT INTO Tickets (id,ticket_code,type,request_id,warehouse_id,keeper_id,status,confirmed_by,confirmed_at) VALUES
(22,'TKT-OUT-2026-0004','OUT',22,1,4,'COMPLETED',4,'2026-05-18 09:00:00');
INSERT INTO Ticket_Details VALUES (22,5,2,10800000.00);
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,ref_ticket_id,staff_id,status,expected_date,approved_by,approved_at,auto_approved) VALUES
(23,'REQ-IN-2026-0011','IN','TRANSFER',2,'WAREHOUSE',1,22,5,'COMPLETED','2026-05-20',2,'2026-05-18 09:00:00',TRUE);
INSERT INTO Request_Details VALUES (23,5,2,NULL);
INSERT INTO Tickets (id,ticket_code,type,request_id,warehouse_id,keeper_id,status,confirmed_by,confirmed_at) VALUES
(23,'TKT-IN-2026-0006','IN',23,2,7,'CONFIRMED',7,'2026-05-20 15:00:00');
INSERT INTO Ticket_Details VALUES (23,5,2,10800000.00);

-- Yêu cầu xuất chuyển kho 2 chiếc, thực xuất 1 rồi đóng phần còn lại.
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,staff_id,status,expected_date,approved_by,approved_at,cancel_requested_by,cancel_requested_at,cancel_reason,cancelled_by,cancelled_at) VALUES
(24,'REQ-OUT-2026-0010','OUT','TRANSFER',1,'WAREHOUSE',2,5,'PARTIALLY_CLOSED_IN_TRANSIT','2026-06-05',2,'2026-06-01 09:00:00',5,'2026-06-03 08:00:00','Kho đích chỉ còn nhu cầu một chiếc',2,'2026-06-03 09:00:00');
INSERT INTO Request_Details VALUES (24,6,2,NULL);
INSERT INTO Tickets (id,ticket_code,type,request_id,warehouse_id,keeper_id,status,confirmed_by,confirmed_at) VALUES
(24,'TKT-OUT-2026-0005','OUT',24,1,4,'IN_TRANSIT',4,'2026-06-02 10:00:00');
INSERT INTO Ticket_Details VALUES (24,6,1,8990000.00);
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,ref_ticket_id,staff_id,status,expected_date,approved_by,approved_at,auto_approved) VALUES
(25,'REQ-IN-2026-0012','IN','TRANSFER',2,'WAREHOUSE',1,24,5,'APPROVED','2026-06-05',2,'2026-06-02 10:00:00',TRUE);
INSERT INTO Request_Details VALUES (25,6,1,NULL);

-- Kho đích hủy nhận: cả hai yêu cầu gốc RETURNING và nguồn có yêu cầu nhập trả tự sinh.
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,staff_id,status,expected_date,approved_by,approved_at) VALUES
(26,'REQ-OUT-2026-0011','OUT','TRANSFER',1,'WAREHOUSE',2,5,'RETURNING','2026-06-15',2,'2026-06-10 09:00:00');
INSERT INTO Request_Details VALUES (26,3,1,NULL);
INSERT INTO Tickets (id,ticket_code,type,request_id,warehouse_id,keeper_id,status,return_status,confirmed_by,confirmed_at) VALUES
(26,'TKT-OUT-2026-0006','OUT',26,1,4,'IN_TRANSIT','NONE',4,'2026-06-12 10:00:00');
INSERT INTO Ticket_Details VALUES (26,3,1,20415000.00);
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,ref_ticket_id,staff_id,status,expected_date,approved_by,approved_at,auto_approved,cancel_requested_by,cancel_requested_at,cancel_reason,cancelled_by,cancelled_at) VALUES
(27,'REQ-IN-2026-0013','IN','TRANSFER',2,'WAREHOUSE',1,26,5,'RETURNING','2026-06-15',2,'2026-06-12 10:00:00',TRUE,8,'2026-06-13 08:00:00','Kho đích không thể tiếp nhận lô hàng',2,'2026-06-13 09:00:00');
INSERT INTO Request_Details VALUES (27,3,1,NULL);
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,ref_ticket_id,expected_serials,staff_id,status,approved_by,approved_at,auto_approved) VALUES
(28,'REQ-IN-2026-0014','IN','TRANSFER',1,'WAREHOUSE',2,26,'LG-635L-001',2,'APPROVED',2,'2026-06-13 09:00:00',TRUE);
INSERT INTO Request_Details VALUES (28,3,1,NULL);

-- Hoàn trả hoàn tất: kho nguồn đã quét nhận lại serial.
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,staff_id,status,expected_date,approved_by,approved_at) VALUES
(29,'REQ-OUT-2026-0012','OUT','TRANSFER',1,'WAREHOUSE',2,5,'RETURNED','2026-07-05',2,'2026-07-01 09:00:00');
INSERT INTO Request_Details VALUES (29,4,1,NULL);
INSERT INTO Tickets (id,ticket_code,type,request_id,warehouse_id,keeper_id,status,return_status,confirmed_by,confirmed_at) VALUES
(29,'TKT-OUT-2026-0007','OUT',29,1,4,'COMPLETED','FULL',4,'2026-07-02 10:00:00');
INSERT INTO Ticket_Details VALUES (29,4,1,6150000.00);
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,ref_ticket_id,staff_id,status,expected_date,approved_by,approved_at,auto_approved,cancel_requested_by,cancel_requested_at,cancel_reason,cancelled_by,cancelled_at) VALUES
(30,'REQ-IN-2026-0015','IN','TRANSFER',2,'WAREHOUSE',1,29,5,'RETURNED','2026-07-05',2,'2026-07-02 10:00:00',TRUE,8,'2026-07-03 08:00:00','Kho đích từ chối nhận lô hàng',2,'2026-07-03 09:00:00');
INSERT INTO Request_Details VALUES (30,4,1,NULL);
INSERT INTO Requests (id,request_code,type,reason,warehouse_id,partner_type,partner_id,ref_ticket_id,expected_serials,staff_id,status,approved_by,approved_at,auto_approved) VALUES
(31,'REQ-IN-2026-0016','IN','TRANSFER',1,'WAREHOUSE',2,29,'SAMSUNG-236L-001',2,'COMPLETED',2,'2026-07-03 09:00:00',TRUE);
INSERT INTO Request_Details VALUES (31,4,1,NULL);
INSERT INTO Tickets (id,ticket_code,type,request_id,warehouse_id,keeper_id,status,confirmed_by,confirmed_at) VALUES
(31,'TKT-IN-2026-0007','IN',31,1,4,'CONFIRMED',4,'2026-07-04 10:00:00');
INSERT INTO Ticket_Details VALUES (31,4,1,6150000.00);

-- ========================================================
-- SEED: LEDGER ĐỒNG BỘ VỚI TỪNG PHIẾU ĐÃ XÁC NHẬN
-- ========================================================
INSERT INTO Product_Ledger
(product_id,transaction_type,reference_id,change_quantity,balance_quantity,
 change_new_quantity,change_used_quantity,change_damaged_quantity,
 balance_new_quantity,balance_used_quantity,balance_damaged_quantity,created_by,warehouse_id,created_at) VALUES
(1,'IMPORT',2,15,15,15,0,0,15,0,0,4,1,'2025-12-16 10:00:00'),
(2,'IMPORT',2,10,10,10,0,0,10,0,0,4,1,'2025-12-16 10:00:00'),
(3,'IMPORT',2,4,4,4,0,0,4,0,0,4,1,'2025-12-16 10:00:00'),
(4,'IMPORT',2,2,2,2,0,0,2,0,0,4,1,'2025-12-16 10:00:00'),
(5,'IMPORT',2,12,12,12,0,0,12,0,0,4,1,'2025-12-16 10:00:00'),
(6,'IMPORT',2,3,3,3,0,0,3,0,0,4,1,'2025-12-16 10:00:00'),
(3,'IMPORT',1,20,24,20,0,0,24,0,0,4,1,'2026-02-05 14:30:00'),
(6,'IMPORT',7,1,4,1,0,0,4,0,0,4,1,'2026-03-20 14:00:00'),
(4,'IMPORT',8,1,3,0,0,1,2,0,1,4,1,'2026-03-25 15:00:00'),
(1,'EXPORT',10,-2,13,-2,0,0,13,0,0,4,1,'2026-04-05 10:00:00'),
(1,'RETURN',18,1,14,0,1,0,13,1,0,4,1,'2026-04-08 14:00:00'),
(1,'EXPORT',11,-1,13,-1,0,0,12,1,0,4,1,'2026-04-10 10:00:00'),
(2,'TRANSFER_OUT',20,-2,8,-2,0,0,8,0,0,4,1,'2026-05-12 10:00:00'),
(5,'TRANSFER_OUT',22,-2,10,-2,0,0,10,0,0,4,1,'2026-05-18 09:00:00'),
(5,'TRANSFER_IN',23,2,2,2,0,0,2,0,0,7,2,'2026-05-20 15:00:00'),
(6,'TRANSFER_OUT',24,-1,3,-1,0,0,3,0,0,4,1,'2026-06-02 10:00:00'),
(3,'TRANSFER_OUT',26,-1,23,-1,0,0,23,0,0,4,1,'2026-06-12 10:00:00'),
(4,'TRANSFER_OUT',29,-1,2,-1,0,0,1,0,1,4,1,'2026-07-02 10:00:00'),
(4,'TRANSFER_RETURN',31,1,3,1,0,0,2,0,1,4,1,'2026-07-04 10:00:00'),
(4,'TRANSFER_RETURN_OUT',31,0,0,0,0,0,0,0,0,4,2,'2026-07-04 10:00:00');

-- ========================================================
-- SEED: Stocktake_Config
-- ========================================================
INSERT INTO Stocktake_Config (id, threshold_percent, threshold_value) VALUES (1,5.00,10000000);

-- ========================================================
-- SEED: SERIAL CUỐI KỲ
-- ========================================================
INSERT INTO Product_Items (product_id,serial_number,status,item_condition,warehouse_id) VALUES
(1,'PANA-9000-001','EXPORTED','NEW',1),(1,'PANA-9000-002','IN_STOCK','USED',1),(1,'PANA-9000-003','EXPORTED','NEW',1),
(1,'PANA-9000-004','IN_STOCK','NEW',1),(1,'PANA-9000-005','IN_STOCK','NEW',1),(1,'PANA-9000-006','IN_STOCK','NEW',1),
(1,'PANA-9000-007','IN_STOCK','NEW',1),(1,'PANA-9000-008','IN_STOCK','NEW',1),(1,'PANA-9000-009','IN_STOCK','NEW',1),
(1,'PANA-9000-010','IN_STOCK','NEW',1),(1,'PANA-9000-011','IN_STOCK','NEW',1),(1,'PANA-9000-012','IN_STOCK','NEW',1),
(1,'PANA-9000-013','IN_STOCK','NEW',1),(1,'PANA-9000-014','IN_STOCK','NEW',1),(1,'PANA-9000-015','IN_STOCK','NEW',1);
INSERT INTO Product_Items (product_id,serial_number,status,item_condition,warehouse_id) VALUES
(2,'DAIKIN-12000-001','IN_TRANSIT','NEW',1),(2,'DAIKIN-12000-002','IN_TRANSIT','NEW',1),(2,'DAIKIN-12000-003','IN_STOCK','NEW',1),
(2,'DAIKIN-12000-004','IN_STOCK','NEW',1),(2,'DAIKIN-12000-005','IN_STOCK','NEW',1),(2,'DAIKIN-12000-006','IN_STOCK','NEW',1),
(2,'DAIKIN-12000-007','IN_STOCK','NEW',1),(2,'DAIKIN-12000-008','IN_STOCK','NEW',1),(2,'DAIKIN-12000-009','IN_STOCK','NEW',1),(2,'DAIKIN-12000-010','IN_STOCK','NEW',1);
INSERT INTO Product_Items (product_id,serial_number,status,item_condition,warehouse_id) VALUES
(3,'LG-635L-001','IN_TRANSIT','NEW',1),(3,'LG-635L-002','IN_STOCK','NEW',1),(3,'LG-635L-003','IN_STOCK','NEW',1),(3,'LG-635L-004','IN_STOCK','NEW',1),
(3,'LG-635L-005','IN_STOCK','NEW',1),(3,'LG-635L-006','IN_STOCK','NEW',1),(3,'LG-635L-007','IN_STOCK','NEW',1),(3,'LG-635L-008','IN_STOCK','NEW',1),
(3,'LG-635L-009','IN_STOCK','NEW',1),(3,'LG-635L-010','IN_STOCK','NEW',1),(3,'LG-635L-011','IN_STOCK','NEW',1),(3,'LG-635L-012','IN_STOCK','NEW',1),
(3,'LG-635L-013','IN_STOCK','NEW',1),(3,'LG-635L-014','IN_STOCK','NEW',1),(3,'LG-635L-015','IN_STOCK','NEW',1),(3,'LG-635L-016','IN_STOCK','NEW',1),
(3,'LG-635L-017','IN_STOCK','NEW',1),(3,'LG-635L-018','IN_STOCK','NEW',1),(3,'LG-635L-019','IN_STOCK','NEW',1),(3,'LG-635L-020','IN_STOCK','NEW',1);
INSERT INTO Product_Items (product_id,serial_number,status,item_condition,warehouse_id) VALUES
(3,'LG-635L-021','IN_STOCK','NEW',1),(3,'LG-635L-022','IN_STOCK','NEW',1),(3,'LG-635L-023','IN_STOCK','NEW',1),(3,'LG-635L-024','IN_STOCK','NEW',1);
INSERT INTO Product_Items (product_id,serial_number,status,item_condition,warehouse_id) VALUES
(4,'SAMSUNG-236L-001','IN_STOCK','NEW',1),(4,'SAMSUNG-236L-002','IN_STOCK','NEW',1);
INSERT INTO Product_Items (product_id,serial_number,status,item_condition,warehouse_id) VALUES
(5,'ELEC-9KG-001','IN_STOCK','NEW',2),(5,'ELEC-9KG-002','IN_STOCK','NEW',2),(5,'ELEC-9KG-003','IN_STOCK','NEW',1),
(5,'ELEC-9KG-004','IN_STOCK','NEW',1),(5,'ELEC-9KG-005','IN_STOCK','NEW',1),(5,'ELEC-9KG-006','IN_STOCK','NEW',1),
(5,'ELEC-9KG-007','IN_STOCK','NEW',1),(5,'ELEC-9KG-008','IN_STOCK','NEW',1),(5,'ELEC-9KG-009','IN_STOCK','NEW',1),
(5,'ELEC-9KG-010','IN_STOCK','NEW',1),(5,'ELEC-9KG-011','IN_STOCK','NEW',1),(5,'ELEC-9KG-012','IN_STOCK','NEW',1);
INSERT INTO Product_Items (product_id,serial_number,status,item_condition,warehouse_id) VALUES
(6,'LG-10KG-001','IN_TRANSIT','NEW',1),(6,'LG-10KG-002','IN_STOCK','NEW',1),(6,'LG-10KG-003','IN_STOCK','NEW',1),
(6,'LG-10KG-004','IN_STOCK','NEW',1),
(4,'SAMSUNG-236L-003','QUARANTINE','DAMAGED',1);

-- Serial nhà sản xuất giả lập: dễ đọc, theo SKU và duy nhất trong từng sản phẩm.
-- Ví dụ: MFG-PANA9000-00001, MFG-LG635L-00026.
UPDATE Product_Items pi
JOIN Products p ON p.id = pi.product_id
SET pi.manufacturer_serial = CONCAT('MFG-', REPLACE(p.sku, '-', ''), '-', LPAD(pi.id, 5, '0'))
WHERE pi.manufacturer_serial IS NULL;

-- ========================================================
-- SEED: LỊCH SỬ MOVEMENT CỦA TỪNG SERIAL
-- ========================================================
-- Tồn đầu kỳ: ids 1-25 và 46-66; lô mua bổ sung: ids 26-45.
INSERT INTO Product_Item_Movements (product_item_id,ticket_id,action,from_warehouse_id,to_warehouse_id,condition_at_time,created_at,created_by)
SELECT id,2,'IMPORT_IN',NULL,1,'NEW','2025-12-16 10:00:00',4 FROM Product_Items WHERE id BETWEEN 1 AND 25 OR id BETWEEN 46 AND 66;
UPDATE Product_Items
SET created_at = '2025-12-16 09:45:00'
WHERE id BETWEEN 1 AND 25 OR id BETWEEN 46 AND 66;
INSERT INTO Product_Item_Movements (product_item_id,ticket_id,action,from_warehouse_id,to_warehouse_id,condition_at_time,created_at,created_by)
SELECT id,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4 FROM Product_Items WHERE id BETWEEN 26 AND 45;

INSERT INTO Product_Item_Movements (product_item_id,ticket_id,action,from_warehouse_id,to_warehouse_id,condition_at_time,created_at,created_by) VALUES
(67,7,'IMPORT_IN',NULL,1,'NEW','2026-03-20 14:00:00',4),
(68,8,'IMPORT_IN',NULL,1,'DAMAGED','2026-03-25 15:00:00',4),
(1,10,'EXPORT_OUT',1,1,'NEW','2026-04-05 10:00:00',4),
(2,10,'EXPORT_OUT',1,1,'NEW','2026-04-05 10:00:00',4),
(2,18,'RETURN_IN',NULL,1,'USED','2026-04-08 14:00:00',4),
(3,11,'EXPORT_OUT',1,1,'NEW','2026-04-10 10:00:00',4),
(16,20,'TRANSFER_OUT',1,2,'NEW','2026-05-12 10:00:00',4),
(17,20,'TRANSFER_OUT',1,2,'NEW','2026-05-12 10:00:00',4),
(52,22,'TRANSFER_OUT',1,2,'NEW','2026-05-18 09:00:00',4),
(53,22,'TRANSFER_OUT',1,2,'NEW','2026-05-18 09:00:00',4),
(52,23,'TRANSFER_IN',1,2,'NEW','2026-05-20 15:00:00',7),
(53,23,'TRANSFER_IN',1,2,'NEW','2026-05-20 15:00:00',7),
(64,24,'TRANSFER_OUT',1,2,'NEW','2026-06-02 10:00:00',4),
(26,26,'TRANSFER_OUT',1,2,'NEW','2026-06-12 10:00:00',4),
(50,29,'TRANSFER_OUT',1,2,'NEW','2026-07-02 10:00:00',4),
(50,31,'RETURN_IN',2,1,'NEW','2026-07-04 10:00:00',4);

-- ========================================================
-- VIEW: Inventory_Available
-- Tính tồn kho "có thể bán" (available) theo từng (kho, sản phẩm).
-- Tự cập nhật theo dữ liệu thật, không cần code maintain.
--
-- Các cột:
--   in_stock_qty       : số hàng mới và hàng cũ còn trong kho (status=IN_STOCK)
--   quarantine_qty     : số hàng hỏng cách ly (status=QUARANTINE) — không bán được
--   in_transit_qty     : số hàng đang vận chuyển đi (status=IN_TRANSIT)
--   reserved_qty       : tổng đặt giữ (Ticket OUT DRAFT + Request OUT chưa xong)
--   available_qty      : có thể cam kết bán = in_stock_qty - reserved_qty
-- ========================================================

CREATE OR REPLACE VIEW Inventory_Available AS
SELECT
    p.id   AS product_id,
    w.id   AS warehouse_id,
    p.product_name,
    p.sku,
    w.warehouse_name,
    COALESCE(s.in_stock_qty,   0) AS in_stock_qty,
    COALESCE(s.quarantine_qty, 0) AS quarantine_qty,
    COALESCE(s.in_transit_qty, 0) AS in_transit_qty,
    COALESCE(s.in_stock_qty, 0) + COALESCE(s.quarantine_qty, 0) AS physical_total_qty,
    
    COALESCE(s.in_stock_new_qty, 0) AS in_stock_new_qty,
    COALESCE(s.in_stock_used_qty, 0) AS in_stock_used_qty,

    COALESCE(d.reserved_new_qty, 0) + COALESCE(a.reserved_new_qty, 0) AS reserved_new_qty,
    COALESCE(d.reserved_used_qty, 0) + COALESCE(a.reserved_used_qty, 0) AS reserved_used_qty,
    COALESCE(d.reserved_damaged_qty, 0) + COALESCE(a.reserved_damaged_qty, 0) AS reserved_damaged_qty,

    (COALESCE(d.reserved_new_qty, 0) + COALESCE(a.reserved_new_qty, 0)
     + COALESCE(d.reserved_used_qty, 0) + COALESCE(a.reserved_used_qty, 0)
     + COALESCE(d.reserved_damaged_qty, 0) + COALESCE(a.reserved_damaged_qty, 0)) AS reserved_qty,

    GREATEST(COALESCE(s.in_stock_new_qty, 0) - (COALESCE(d.reserved_new_qty, 0) + COALESCE(a.reserved_new_qty, 0)), 0) AS available_new_qty,
    GREATEST(COALESCE(s.in_stock_used_qty, 0) - (COALESCE(d.reserved_used_qty, 0) + COALESCE(a.reserved_used_qty, 0)), 0) AS available_used_qty,
    GREATEST(COALESCE(s.quarantine_qty, 0) - (COALESCE(d.reserved_damaged_qty, 0) + COALESCE(a.reserved_damaged_qty, 0)), 0) AS available_damaged_qty,
    
    GREATEST(COALESCE(s.in_stock_new_qty, 0) - (COALESCE(d.reserved_new_qty, 0) + COALESCE(a.reserved_new_qty, 0)), 0) +
    GREATEST(COALESCE(s.in_stock_used_qty, 0) - (COALESCE(d.reserved_used_qty, 0) + COALESCE(a.reserved_used_qty, 0)), 0) AS available_qty

FROM Products p
CROSS JOIN Warehouses w
LEFT JOIN (
    SELECT
        product_id, warehouse_id,
        COUNT(CASE WHEN status = 'IN_STOCK'   THEN 1 END) AS in_stock_qty,
        COUNT(CASE WHEN status = 'QUARANTINE' THEN 1 END) AS quarantine_qty,
        COUNT(CASE WHEN status = 'IN_TRANSIT' THEN 1 END) AS in_transit_qty,
        COUNT(CASE WHEN status = 'IN_STOCK' AND item_condition = 'NEW' THEN 1 END) AS in_stock_new_qty,
        COUNT(CASE WHEN status = 'IN_STOCK' AND item_condition = 'USED' THEN 1 END) AS in_stock_used_qty
    FROM Product_Items
    GROUP BY product_id, warehouse_id
) s ON s.product_id = p.id AND s.warehouse_id = w.id
LEFT JOIN (
    -- Đặt giữ bởi Ticket OUT đang DRAFT
    SELECT t.warehouse_id, td.product_id, 
           SUM(CASE WHEN r.requested_condition = 'NEW' THEN td.quantity ELSE 0 END) AS reserved_new_qty,
           SUM(CASE WHEN r.requested_condition = 'USED' THEN td.quantity ELSE 0 END) AS reserved_used_qty,
           SUM(CASE WHEN r.requested_condition = 'DAMAGED' THEN td.quantity ELSE 0 END) AS reserved_damaged_qty
    FROM Tickets t
    JOIN Ticket_Details td ON td.ticket_id = t.id
    JOIN Requests r ON t.request_id = r.id
    WHERE t.type = 'OUT' AND t.status = 'DRAFT'
      AND r.status IN ('APPROVED','PARTIALLY_COMPLETED')
    GROUP BY t.warehouse_id, td.product_id
) d ON d.warehouse_id = w.id AND d.product_id = p.id
LEFT JOIN (
    -- Đặt giữ bởi Request OUT (PENDING/APPROVED/PARTIALLY_COMPLETED) - phần chưa làm phiếu xuất
    SELECT r.warehouse_id, rd.product_id,
           SUM(CASE WHEN r.requested_condition = 'NEW' THEN GREATEST(rd.quantity - COALESCE(proc.processed_qty, 0), 0) ELSE 0 END) AS reserved_new_qty,
           SUM(CASE WHEN r.requested_condition = 'USED' THEN GREATEST(rd.quantity - COALESCE(proc.processed_qty, 0), 0) ELSE 0 END) AS reserved_used_qty,
           SUM(CASE WHEN r.requested_condition = 'DAMAGED' THEN GREATEST(rd.quantity - COALESCE(proc.processed_qty, 0), 0) ELSE 0 END) AS reserved_damaged_qty
    FROM Requests r
    JOIN Request_Details rd ON rd.request_id = r.id
    LEFT JOIN (
        SELECT t.request_id, td.product_id, SUM(td.quantity) AS processed_qty
        FROM Tickets t JOIN Ticket_Details td ON td.ticket_id = t.id
        WHERE t.status IN ('DRAFT','CONFIRMED','IN_TRANSIT','COMPLETED')
        GROUP BY t.request_id, td.product_id
    ) proc ON proc.request_id = r.id AND proc.product_id = rd.product_id
    WHERE r.type = 'OUT'
      AND r.status IN ('PENDING','APPROVED','PARTIALLY_COMPLETED')
    GROUP BY r.warehouse_id, rd.product_id
) a ON a.warehouse_id = w.id AND a.product_id = p.id;

-- ========================================================
-- KẾT THÚC SCRIPT v3
-- ========================================================
