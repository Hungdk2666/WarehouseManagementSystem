-- ========================================================
-- WAREHOUSE MANAGEMENT SYSTEM (WMS) - DATABASE v3
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
    username     VARCHAR(50)  NOT NULL UNIQUE,
    password     VARCHAR(255) NOT NULL,
    email        VARCHAR(100),
    full_name    VARCHAR(100),
    status       BOOLEAN DEFAULT TRUE,
    role_id      INT,
    reset_code   VARCHAR(10)  DEFAULT NULL,
    warehouse_id INT          DEFAULT NULL,
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
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
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
--   ('OUT', 'OTHER',         'INTERNAL_DEST') — mục đích nội bộ khác
--   ('OUT', 'DISPOSAL',      'NONE')          — tiêu hủy, partner_id NULL
-- ========================================================

CREATE TABLE Requests (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    request_code        VARCHAR(50) NOT NULL UNIQUE,
    type                ENUM('IN','OUT') NOT NULL,
    reason              ENUM(
        'PURCHASE','RETURN',                                        -- IN
        'TRANSFER',                                                 -- IN hoặc OUT
        'DISPLAY','WARRANTY','CUSTOMER_SALE','DISPOSAL','OTHER'     -- OUT
    ) NOT NULL,
    warehouse_id        INT NOT NULL,
    partner_type        ENUM('SUPPLIER','CUSTOMER','WAREHOUSE','INTERNAL_DEST','NONE') NOT NULL,
    partner_id          INT NULL,        -- NULL khi partner_type='NONE' (DISPOSAL)
    ref_ticket_id       INT NULL,        -- RETURN: trỏ Ticket OUT gốc | IN-TRANSFER: trỏ Ticket OUT đối ứng
    return_reason       ENUM('CUSTOMER_REJECTION','QUALITY_DEFECT','WRONG_ITEM','EXCESS_QUANTITY','OTHER') NULL,
    shipping_address    TEXT NULL,
    expected_serials    TEXT NULL,
    expected_date       DATE NULL,
    staff_id            INT NOT NULL,
    requested_condition ENUM('NEW','USED','DAMAGED') NOT NULL DEFAULT 'NEW',
    status              ENUM('PENDING','APPROVED','PARTIALLY_COMPLETED','COMPLETED','REJECTED','CANCELLED')
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
    FOREIGN KEY (warehouse_id)        REFERENCES Warehouses(id) ON DELETE RESTRICT,
    -- FK ref_ticket_id → Tickets được thêm bằng ALTER TABLE sau khi tạo Tickets (tránh circular)
    FOREIGN KEY (staff_id)            REFERENCES Users(id)      ON DELETE RESTRICT,
    FOREIGN KEY (approved_by)         REFERENCES Users(id)      ON DELETE SET NULL,
    FOREIGN KEY (cancel_requested_by) REFERENCES Users(id)      ON DELETE SET NULL,
    FOREIGN KEY (cancelled_by)        REFERENCES Users(id)      ON DELETE SET NULL,
    CONSTRAINT chk_req_type_reason CHECK (
        (type='IN'  AND reason IN ('PURCHASE','RETURN','TRANSFER')) OR
        (type='OUT' AND reason IN ('TRANSFER','DISPLAY','WARRANTY','CUSTOMER_SALE','DISPOSAL','OTHER'))
    ),
    CONSTRAINT chk_req_partner CHECK (
        (reason='PURCHASE'      AND partner_type='SUPPLIER'      AND partner_id IS NOT NULL) OR
        -- RETURN: chỉ cần ref_ticket_id, partner suy ra từ Ticket xuất gốc (có thể CUSTOMER/INTERNAL_DEST/NONE)
        (reason='RETURN'        AND partner_type IN ('CUSTOMER','INTERNAL_DEST','NONE')) OR
        (type='IN'  AND reason='TRANSFER' AND partner_type='WAREHOUSE' AND partner_id IS NOT NULL AND partner_id != warehouse_id AND ref_ticket_id IS NOT NULL) OR
        (type='OUT' AND reason='TRANSFER' AND partner_type='WAREHOUSE' AND partner_id IS NOT NULL AND partner_id != warehouse_id) OR
        (reason='CUSTOMER_SALE' AND partner_type='CUSTOMER'      AND partner_id IS NOT NULL) OR
        (reason IN ('DISPLAY','WARRANTY','OTHER') AND partner_type='INTERNAL_DEST' AND partner_id IS NOT NULL) OR
        (reason='DISPOSAL'      AND partner_type='NONE'          AND partner_id IS NULL)
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
    status         ENUM('IN_STOCK','EXPORTED','IN_TRANSIT','QUARANTINE','LOST') NOT NULL DEFAULT 'IN_STOCK',
    item_condition ENUM('NEW','USED','DAMAGED') NOT NULL DEFAULT 'NEW',
    warehouse_id   INT NOT NULL DEFAULT 1,
    created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id)   REFERENCES Products(id)   ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(id) ON DELETE RESTRICT
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
    FOREIGN KEY (l2_approved_by) REFERENCES Users(id)      ON DELETE SET NULL
);

CREATE TABLE Stocktake_Details (
    stocktake_id    INT,
    product_id      INT,
    theoretical_qty INT NOT NULL,
    actual_qty      INT NOT NULL DEFAULT 0,
    damaged_qty     INT NOT NULL DEFAULT 0,
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

-- Thẻ kho — reference_id trỏ về Tickets.id (không còn phân biệt import/export ticket)
CREATE TABLE Product_Ledger (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    product_id       INT NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,  -- IMPORT, EXPORT, TRANSFER_IN, TRANSFER_OUT, RETURN, STOCKTAKE
    reference_id     INT NOT NULL,          -- ID Ticket
    change_quantity  INT NOT NULL,
    balance_quantity INT NOT NULL,
    warehouse_id     INT NOT NULL DEFAULT 1,
    created_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by       INT,
    FOREIGN KEY (product_id)   REFERENCES Products(id)   ON DELETE CASCADE,
    FOREIGN KEY (created_by)   REFERENCES Users(id)      ON DELETE SET NULL,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(id) ON DELETE CASCADE
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
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE SET NULL
);


-- ========================================================
-- DATA SEEDING
-- ========================================================

-- Roles
INSERT INTO Roles (id, role_name, description, status) VALUES
(1, 'System Admin',      'Phòng IT - quản trị hệ thống, người dùng, phân quyền',              TRUE),
(2, 'Business Admin',    'Giám đốc - phê duyệt phiếu, xem báo cáo tổng quan',                  TRUE),
(3, 'Warehouse Manager', 'Quản lý kho - quản lý master data, confirm phiếu nhập/xuất',         TRUE),
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
(73, 'INVENTORY_EXPORT',          'Xuất báo cáo tồn kho');

-- Role_Permissions
-- 1. System Admin
INSERT INTO Role_Permissions (role_id, permission_id) VALUES
(1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(1,7),(1,8),(1,9),(1,10);

-- 2. Business Admin (giám đốc duyệt) — bao gồm STOCKTAKE_APPROVE_L2 + STOCKTAKE_CONFIG
INSERT INTO Role_Permissions (role_id, permission_id) VALUES
(2,10),(2,11),(2,15),(2,19),(2,23),(2,27),
(2,31),(2,35),(2,37),(2,38),(2,42),(2,44),
(2,45),(2,49),(2,53),(2,58),(2,70),(2,71),(2,72),(2,73),
(2,59),(2,60),(2,61),(2,62),
(2,63),(2,64),(2,65),(2,66),(2,67);

-- 3. Warehouse Manager (confirm phiếu, master data, tạo+duyệt L1 kiểm kê)
INSERT INTO Role_Permissions (role_id, permission_id) VALUES
(3,11),(3,12),(3,13),(3,14),(3,15),(3,16),(3,17),(3,18),
(3,19),(3,20),(3,21),(3,22),(3,23),(3,24),(3,25),(3,26),
(3,27),(3,28),(3,29),(3,30),
(3,31),(3,38),
(3,45),(3,47),(3,48),(3,49),(3,51),(3,52),
(3,53),(3,54),(3,57),(3,58),(3,59),(3,60),
(3,63),(3,67),(3,69),(3,72),(3,73);

-- 4. Warehouse Staff (tạo phiếu nhập/xuất, đếm kiểm kê)
INSERT INTO Role_Permissions (role_id, permission_id) VALUES
(4,11),(4,15),(4,19),(4,23),(4,27),
(4,45),(4,46),(4,49),(4,50),
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
(5, 'vietanh',    '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'vietanh@wms.local',   'Viet Anh',    TRUE, 5, 1),
(6, 'quanlikhohcm','8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'qlkho.hcm@wms.local', 'Quan Ly Kho HCM', TRUE, 3, 2),
(7, 'thukhohcm',   '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'thukho.hcm@wms.local','Thu Kho HCM',     TRUE, 4, 2),
(8, 'salehcm',    '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'sales.hcm@wms.local', 'Sales HCM',       TRUE, 5, 2);

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

-- Inventories khởi tạo
INSERT INTO Inventories (warehouse_id, product_id, quantity, quarantine_quantity) VALUES
(1,1,0,0),(1,2,0,0),(1,3,0,0),(1,4,0,0),(1,5,0,0),(1,6,0,0),
(2,1,0,0),(2,2,0,0),(2,3,0,0),(2,4,0,0),(2,5,0,0),(2,6,0,0);

-- ========================================================
-- SEED: Requests & Tickets IN (tồn kho ban đầu)
-- ========================================================

-- Đợt nhập ban đầu (id=2 giữ nguyên)
INSERT INTO Requests (id, request_code, type, reason, warehouse_id, partner_type, partner_id, staff_id, status, expected_date, approved_by, approved_at) VALUES
(2, 'REQ-INITIAL', 'IN', 'PURCHASE', 1, 'SUPPLIER', 1, 5, 'COMPLETED', '2026-01-01', 2, '2026-01-01 09:00:00');

INSERT INTO Request_Details (request_id, product_id, quantity, unit_price) VALUES
(2,1,15,8500000.00),(2,2,10,11200000.00),(2,3,4,22490000.00),
(2,4,2,6150000.00),(2,5,12,10800000.00),(2,6,3,8990000.00);

INSERT INTO Tickets (id, ticket_code, type, request_id, warehouse_id, keeper_id, status, confirmed_by, confirmed_at) VALUES
(2, 'TKT-INITIAL-STOCK', 'IN', 2, 1, 4, 'CONFIRMED', 3, '2026-01-02 10:00:00');

INSERT INTO Ticket_Details (ticket_id, product_id, quantity, unit_cost) VALUES
(2,1,15,8500000.00),(2,2,10,11200000.00),(2,3,4,22490000.00),
(2,4,2,6150000.00),(2,5,12,10800000.00),(2,6,3,8990000.00);

-- Đợt nhập 2: mua thêm tủ lạnh LG (id=1)
INSERT INTO Requests (id, request_code, type, reason, warehouse_id, partner_type, partner_id, staff_id, status, expected_date, approved_by, approved_at) VALUES
(1, 'REQ-2026-001', 'IN', 'PURCHASE', 1, 'SUPPLIER', 3, 5, 'APPROVED', '2026-02-15', 2, '2026-02-01 09:00:00');

INSERT INTO Request_Details (request_id, product_id, quantity, unit_price) VALUES
(1, 3, 50, 20000000.00);

INSERT INTO Tickets (id, ticket_code, type, request_id, warehouse_id, keeper_id, status, confirmed_by, confirmed_at) VALUES
(1, 'TKT-2026-001', 'IN', 1, 1, 4, 'CONFIRMED', 3, '2026-02-05 14:30:00');

INSERT INTO Ticket_Details (ticket_id, product_id, quantity, unit_cost) VALUES
(1, 3, 20, 20000000.00);

-- Cập nhật tồn kho sau confirm
UPDATE Inventories SET quantity = 15 WHERE product_id = 1 AND warehouse_id = 1;
UPDATE Inventories SET quantity = 10 WHERE product_id = 2 AND warehouse_id = 1;
UPDATE Inventories SET quantity = 24 WHERE product_id = 3 AND warehouse_id = 1;
UPDATE Inventories SET quantity = 2  WHERE product_id = 4 AND warehouse_id = 1;
UPDATE Inventories SET quantity = 12 WHERE product_id = 5 AND warehouse_id = 1;
UPDATE Inventories SET quantity = 3  WHERE product_id = 6 AND warehouse_id = 1;

-- Average cost LG đã tính
UPDATE Products SET average_cost = 20415000.00 WHERE id = 3;

-- Product_Ledger
INSERT INTO Product_Ledger (product_id, transaction_type, reference_id, change_quantity, balance_quantity, created_by, warehouse_id) VALUES
(1,'IMPORT',2,15,15,4,1),
(2,'IMPORT',2,10,10,4,1),
(3,'IMPORT',2, 4, 4,4,1),
(4,'IMPORT',2, 2, 2,4,1),
(5,'IMPORT',2,12,12,4,1),
(6,'IMPORT',2, 3, 3,4,1),
(3,'IMPORT',1,20,24,4,1);

-- ========================================================
-- SEED: Stocktake_Config
-- ========================================================
INSERT INTO Stocktake_Config (id, threshold_percent, threshold_value) VALUES (1, 5.00, 10000000);

-- ========================================================
-- SEED: Product_Items
-- ========================================================

INSERT INTO Product_Items (product_id, serial_number, status, item_condition, warehouse_id) VALUES
(1,'PANA-9000-001','IN_STOCK','NEW',1),(1,'PANA-9000-002','IN_STOCK','NEW',1),(1,'PANA-9000-003','IN_STOCK','NEW',1),
(1,'PANA-9000-004','IN_STOCK','NEW',1),(1,'PANA-9000-005','IN_STOCK','NEW',1),(1,'PANA-9000-006','IN_STOCK','NEW',1),
(1,'PANA-9000-007','IN_STOCK','NEW',1),(1,'PANA-9000-008','IN_STOCK','NEW',1),(1,'PANA-9000-009','IN_STOCK','NEW',1),
(1,'PANA-9000-010','IN_STOCK','NEW',1),(1,'PANA-9000-011','IN_STOCK','NEW',1),(1,'PANA-9000-012','IN_STOCK','NEW',1),
(1,'PANA-9000-013','IN_STOCK','NEW',1),(1,'PANA-9000-014','IN_STOCK','NEW',1),(1,'PANA-9000-015','IN_STOCK','NEW',1);

INSERT INTO Product_Items (product_id, serial_number, status, item_condition, warehouse_id) VALUES
(2,'DAIKIN-12000-001','IN_STOCK','NEW',1),(2,'DAIKIN-12000-002','IN_STOCK','NEW',1),(2,'DAIKIN-12000-003','IN_STOCK','NEW',1),
(2,'DAIKIN-12000-004','IN_STOCK','NEW',1),(2,'DAIKIN-12000-005','IN_STOCK','NEW',1),(2,'DAIKIN-12000-006','IN_STOCK','NEW',1),
(2,'DAIKIN-12000-007','IN_STOCK','NEW',1),(2,'DAIKIN-12000-008','IN_STOCK','NEW',1),(2,'DAIKIN-12000-009','IN_STOCK','NEW',1),
(2,'DAIKIN-12000-010','IN_STOCK','NEW',1);

INSERT INTO Product_Items (product_id, serial_number, status, item_condition, warehouse_id) VALUES
(3,'LG-635L-001','IN_STOCK','NEW',1),(3,'LG-635L-002','IN_STOCK','NEW',1),(3,'LG-635L-003','IN_STOCK','NEW',1),(3,'LG-635L-004','IN_STOCK','NEW',1),
(3,'LG-635L-005','IN_STOCK','NEW',1),(3,'LG-635L-006','IN_STOCK','NEW',1),(3,'LG-635L-007','IN_STOCK','NEW',1),(3,'LG-635L-008','IN_STOCK','NEW',1),
(3,'LG-635L-009','IN_STOCK','NEW',1),(3,'LG-635L-010','IN_STOCK','NEW',1),(3,'LG-635L-011','IN_STOCK','NEW',1),(3,'LG-635L-012','IN_STOCK','NEW',1),
(3,'LG-635L-013','IN_STOCK','NEW',1),(3,'LG-635L-014','IN_STOCK','NEW',1),(3,'LG-635L-015','IN_STOCK','NEW',1),(3,'LG-635L-016','IN_STOCK','NEW',1),
(3,'LG-635L-017','IN_STOCK','NEW',1),(3,'LG-635L-018','IN_STOCK','NEW',1),(3,'LG-635L-019','IN_STOCK','NEW',1),(3,'LG-635L-020','IN_STOCK','NEW',1);

INSERT INTO Product_Items (product_id, serial_number, status, item_condition, warehouse_id) VALUES
(3,'LG-635L-021','IN_STOCK','NEW',1),(3,'LG-635L-022','IN_STOCK','NEW',1),
(3,'LG-635L-023','IN_STOCK','NEW',1),(3,'LG-635L-024','IN_STOCK','NEW',1);

INSERT INTO Product_Items (product_id, serial_number, status, item_condition, warehouse_id) VALUES
(4,'SAMSUNG-236L-001','IN_STOCK','NEW',1),(4,'SAMSUNG-236L-002','IN_STOCK','USED',1);

INSERT INTO Product_Items (product_id, serial_number, status, item_condition, warehouse_id) VALUES
(5,'ELEC-9KG-001','IN_STOCK','NEW',1),(5,'ELEC-9KG-002','IN_STOCK','NEW',1),(5,'ELEC-9KG-003','IN_STOCK','NEW',1),
(5,'ELEC-9KG-004','IN_STOCK','NEW',1),(5,'ELEC-9KG-005','IN_STOCK','NEW',1),(5,'ELEC-9KG-006','IN_STOCK','NEW',1),
(5,'ELEC-9KG-007','IN_STOCK','NEW',1),(5,'ELEC-9KG-008','IN_STOCK','NEW',1),(5,'ELEC-9KG-009','IN_STOCK','NEW',1),
(5,'ELEC-9KG-010','IN_STOCK','NEW',1),(5,'ELEC-9KG-011','IN_STOCK','NEW',1),(5,'ELEC-9KG-012','IN_STOCK','NEW',1);

INSERT INTO Product_Items (product_id, serial_number, status, item_condition, warehouse_id) VALUES
(6,'LG-10KG-001','IN_STOCK','NEW',1),(6,'LG-10KG-002','IN_STOCK','NEW',1),(6,'LG-10KG-003','IN_STOCK','NEW',1);

-- ========================================================
-- SEED: Product_Item_Movements
-- ticket_id thay vì import_ticket_id/export_ticket_id
-- ========================================================

-- IDs 1-25, 46-66: TKT-INITIAL-STOCK (ticket_id=2)
INSERT INTO Product_Item_Movements (product_item_id, ticket_id, action, from_warehouse_id, to_warehouse_id, condition_at_time, created_at, created_by) VALUES
( 1,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
( 2,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
( 3,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
( 4,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
( 5,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
( 6,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
( 7,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
( 8,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
( 9,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(10,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(11,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(12,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(13,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(14,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(15,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(16,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(17,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(18,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(19,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(20,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(21,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(22,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(23,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(24,2,'IMPORT_IN',NULL,1,'USED','2026-01-02 10:00:00',4),
(25,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(46,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(47,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(48,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(49,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(50,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(51,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(52,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(53,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(54,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(55,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(56,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(57,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(58,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(59,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(60,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(61,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(62,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(63,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(64,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(65,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4),
(66,2,'IMPORT_IN',NULL,1,'NEW','2026-01-02 10:00:00',4);

-- IDs 26-45: TKT-2026-001 (ticket_id=1)
INSERT INTO Product_Item_Movements (product_item_id, ticket_id, action, from_warehouse_id, to_warehouse_id, condition_at_time, created_at, created_by) VALUES
(26,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(27,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(28,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(29,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(30,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(31,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(32,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(33,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(34,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(35,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(36,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(37,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(38,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(39,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(40,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(41,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(42,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(43,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(44,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4),
(45,1,'IMPORT_IN',NULL,1,'NEW','2026-02-05 14:30:00',4);

-- ========================================================
-- VIEW: Inventory_Available
-- Tính tồn kho "có thể bán" (available) theo từng (kho, sản phẩm).
-- Tự cập nhật theo dữ liệu thật, không cần code maintain.
--
-- Các cột:
--   in_stock_qty       : số hàng tốt còn trong kho (status=IN_STOCK)
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
    
    COALESCE(s.in_stock_new_qty, 0) AS in_stock_new_qty,
    COALESCE(s.in_stock_used_qty, 0) AS in_stock_used_qty,

    COALESCE(d.reserved_new_qty, 0) + COALESCE(a.reserved_new_qty, 0) AS reserved_new_qty,
    COALESCE(d.reserved_used_qty, 0) + COALESCE(a.reserved_used_qty, 0) AS reserved_used_qty,

    (COALESCE(d.reserved_new_qty, 0) + COALESCE(a.reserved_new_qty, 0) + COALESCE(d.reserved_used_qty, 0) + COALESCE(a.reserved_used_qty, 0)) AS reserved_qty,

    COALESCE(s.in_stock_new_qty, 0) - (COALESCE(d.reserved_new_qty, 0) + COALESCE(a.reserved_new_qty, 0)) AS available_new_qty,
    COALESCE(s.in_stock_used_qty, 0) - (COALESCE(d.reserved_used_qty, 0) + COALESCE(a.reserved_used_qty, 0)) AS available_used_qty,
    
    (COALESCE(s.in_stock_new_qty, 0) - (COALESCE(d.reserved_new_qty, 0) + COALESCE(a.reserved_new_qty, 0))) +
    (COALESCE(s.in_stock_used_qty, 0) - (COALESCE(d.reserved_used_qty, 0) + COALESCE(a.reserved_used_qty, 0))) AS available_qty

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
           SUM(CASE WHEN r.requested_condition = 'USED' THEN td.quantity ELSE 0 END) AS reserved_used_qty
    FROM Tickets t 
    JOIN Ticket_Details td ON td.ticket_id = t.id
    JOIN Requests r ON t.request_id = r.id
    WHERE t.type = 'OUT' AND t.status = 'DRAFT'
    GROUP BY t.warehouse_id, td.product_id
) d ON d.warehouse_id = w.id AND d.product_id = p.id
LEFT JOIN (
    -- Đặt giữ bởi Request OUT (PENDING/APPROVED/PARTIALLY_COMPLETED) - phần chưa làm phiếu xuất
    SELECT r.warehouse_id, rd.product_id,
           SUM(CASE WHEN r.requested_condition = 'NEW' THEN GREATEST(rd.quantity - COALESCE(proc.processed_qty, 0), 0) ELSE 0 END) AS reserved_new_qty,
           SUM(CASE WHEN r.requested_condition = 'USED' THEN GREATEST(rd.quantity - COALESCE(proc.processed_qty, 0), 0) ELSE 0 END) AS reserved_used_qty
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
