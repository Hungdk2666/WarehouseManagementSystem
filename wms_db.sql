-- ========================================================
-- WAREHOUSE MANAGEMENT SYSTEM (WMS) - UNIFIED DATABASE v2
-- ========================================================
-- Đã chỉnh sửa theo phân tích nghiệp vụ:
--  + Thêm Internal_Destinations + export_reason cho phiếu xuất
--  + Thêm giá vốn bình quân (average_cost) + default_cost
--  + Thêm unit_price vào Import_Ticket_Details (giá thực nhập)
--  + Thêm trạng thái DRAFT + confirmed_by/confirmed_at cho phiếu
--  + Bỏ luồng Giám đốc duyệt phiếu xuất -> Warehouse Manager Confirm
--  + Làm lại Permissions chi tiết, map đúng 5 actor
--  + Sửa seed data: Inventories khớp Product_Ledger
-- Chạy script này trong MySQL Server.

DROP DATABASE IF EXISTS wms_db;
CREATE DATABASE IF NOT EXISTS wms_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE wms_db;

-- ========================================================
-- PART 1: CORE AUTHENTICATION & ROLE-BASED ACCESS CONTROL (RBAC)
-- ========================================================

-- 1. Roles
CREATE TABLE Roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    status BOOLEAN DEFAULT TRUE
);

-- 2. Permissions
CREATE TABLE Permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    permission_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- 3. Role_Permissions (bảng trung gian)
CREATE TABLE Role_Permissions (
    role_id INT,
    permission_id INT,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES Roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES Permissions(id) ON DELETE CASCADE
);

-- 4. Users
CREATE TABLE Users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,                 -- SHA-256 hashed
    email VARCHAR(100),
    full_name VARCHAR(100),
    status BOOLEAN DEFAULT TRUE,                     -- Active/Deactive
    role_id INT,
    reset_code VARCHAR(10) DEFAULT NULL,
    FOREIGN KEY (role_id) REFERENCES Roles(id) ON DELETE SET NULL
);


-- ========================================================
-- PART 2: MASTER DATA MANAGEMENT (DANH MỤC GỐC)
-- ========================================================

-- 5. Suppliers (Nhà cung cấp)
CREATE TABLE Suppliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    status BOOLEAN DEFAULT TRUE
);

-- 6. Categories (Danh mục sản phẩm)
CREATE TABLE Categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    status BOOLEAN DEFAULT TRUE
);

-- 7. Brands (Thương hiệu)
CREATE TABLE Brands (
    id INT AUTO_INCREMENT PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    status BOOLEAN DEFAULT TRUE
);

-- 8. Internal_Destinations (Nơi nhận nội bộ - Req 23)
-- Dùng làm đích đến cho phiếu xuất nội bộ (cửa hàng, TT bảo hành...).
CREATE TABLE Internal_Destinations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    destination_name VARCHAR(150) NOT NULL,
    destination_type VARCHAR(50),                   -- STORE, WARRANTY_CENTER, OTHER
    address TEXT,
    status BOOLEAN DEFAULT TRUE
);

-- 10. Products (Hàng hóa)
CREATE TABLE Products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    sku VARCHAR(50) NOT NULL UNIQUE,
    unit VARCHAR(20) NOT NULL DEFAULT 'cái',        -- Đơn vị tính (Req 26)
    min_stock INT NOT NULL DEFAULT 5,               -- Mức tồn tối thiểu (Req 48)
    default_cost DECIMAL(12, 2) NOT NULL DEFAULT 0.00, -- Giá vốn mặc định ban đầu (Req 26, đổi tên từ 'price')
    average_cost DECIMAL(12, 2) NOT NULL DEFAULT 0.00, -- Giá vốn bình quân động (Req 35, 49)
    status BOOLEAN DEFAULT TRUE,                     -- Active/Deactive (Req 27)
    category_id INT DEFAULT NULL,
    brand_id INT DEFAULT NULL,
    technical_specifications TEXT DEFAULT NULL,      -- BTU, Dung tích, Tốc độ vắt...
    FOREIGN KEY (category_id) REFERENCES Categories(id) ON DELETE SET NULL,
    FOREIGN KEY (brand_id) REFERENCES Brands(id) ON DELETE SET NULL
);

-- 11. Inventories (Tồn kho vật lý hiện tại - cache để query nhanh)
CREATE TABLE Inventories (
    product_id INT PRIMARY KEY,
    quantity INT NOT NULL DEFAULT 0,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE
);


-- ========================================================
-- PART 3: INBOUND OPERATIONS (NGHIỆP VỤ NHẬP KHO - PO & GRN)
-- ========================================================

-- 12. Import_Requests (Đơn mua hàng - PO)
CREATE TABLE Import_Requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_code VARCHAR(50) NOT NULL UNIQUE,
    supplier_id INT NOT NULL,
    staff_id INT NOT NULL,                           -- Tạo bởi Sales Staff (Req 29)
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',   -- PENDING, APPROVED, REJECTED, COMPLETED, CANCELLED
    expected_date DATE DEFAULT NULL,                 -- Ngày dự kiến (Req 29)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_by INT DEFAULT NULL,                    -- Duyệt bởi Business Admin (Req 31)
    approved_at DATETIME DEFAULT NULL,
    cancel_requested_by INT DEFAULT NULL,
    cancel_requested_at DATETIME DEFAULT NULL,
    cancel_reason TEXT DEFAULT NULL,
    cancelled_by INT DEFAULT NULL,
    cancelled_at DATETIME DEFAULT NULL,
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(id) ON DELETE RESTRICT,
    FOREIGN KEY (staff_id) REFERENCES Users(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES Users(id) ON DELETE SET NULL,
    FOREIGN KEY (cancel_requested_by) REFERENCES Users(id) ON DELETE SET NULL,
    FOREIGN KEY (cancelled_by) REFERENCES Users(id) ON DELETE SET NULL
);

-- 13. Import_Request_Details (Chi tiết đơn mua - giá dự kiến)
CREATE TABLE Import_Request_Details (
    request_id INT,
    product_id INT,
    quantity INT NOT NULL,                           -- Số lượng đặt mua
    unit_price DECIMAL(12, 2) NOT NULL,              -- Đơn giá DỰ KIẾN (Req 30)
    PRIMARY KEY (request_id, product_id),
    FOREIGN KEY (request_id) REFERENCES Import_Requests(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE RESTRICT
);

-- 14. Import_Tickets (Phiếu nhập kho thực tế - GRN, theo đợt)
CREATE TABLE Import_Tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_code VARCHAR(50) NOT NULL UNIQUE,
    request_id INT NOT NULL,                         -- Kế thừa từ PO đã duyệt (Req 34)
    keeper_id INT NOT NULL,                          -- Người tạo phiếu nhập (Warehouse Staff)
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',     -- DRAFT (chưa chốt), CONFIRMED (đã cộng tồn), CANCELLED
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    confirmed_by INT DEFAULT NULL,                   -- Confirm bởi Warehouse Manager (Req 35)
    confirmed_at DATETIME DEFAULT NULL,
    FOREIGN KEY (request_id) REFERENCES Import_Requests(id) ON DELETE RESTRICT,
    FOREIGN KEY (keeper_id) REFERENCES Users(id) ON DELETE RESTRICT,
    FOREIGN KEY (confirmed_by) REFERENCES Users(id) ON DELETE SET NULL
);

-- 15. Import_Ticket_Details (Chi tiết thực nhập - có giá thực nhập)
CREATE TABLE Import_Ticket_Details (
    ticket_id INT,
    product_id INT,
    quantity INT NOT NULL,                           -- Số lượng thực nhập đợt này
    unit_price DECIMAL(12, 2) NOT NULL,              -- Đơn giá THỰC NHẬP (phục vụ tính giá vốn bình quân - Req 35)
    PRIMARY KEY (ticket_id, product_id),
    FOREIGN KEY (ticket_id) REFERENCES Import_Tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE RESTRICT
);


-- ========================================================
-- PART 4: OUTBOUND OPERATIONS (NGHIỆP VỤ XUẤT KHO - GIN)
-- ========================================================

-- 15.5. Export_Requests (Yêu cầu xuất kho)
CREATE TABLE Export_Requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_code VARCHAR(50) NOT NULL UNIQUE,
    destination_id INT NOT NULL,                     -- Nơi nhận nội bộ (Req 37)
    export_reason VARCHAR(50) DEFAULT 'TRANSFER',    -- TRANSFER, DISPOSAL, DISPLAY, OTHER
    staff_id INT NOT NULL,                           -- Tạo bởi Sales Staff (Req 37)
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',   -- PENDING, APPROVED, REJECTED, COMPLETED, CANCELLED
    expected_date DATE DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_by INT DEFAULT NULL,                    -- Duyệt bởi Business Admin (Req 37)
    approved_at DATETIME DEFAULT NULL,
    cancel_requested_by INT DEFAULT NULL,
    cancel_requested_at DATETIME DEFAULT NULL,
    cancel_reason TEXT DEFAULT NULL,
    cancelled_by INT DEFAULT NULL,
    cancelled_at DATETIME DEFAULT NULL,
    FOREIGN KEY (destination_id) REFERENCES Internal_Destinations(id) ON DELETE RESTRICT,
    FOREIGN KEY (staff_id) REFERENCES Users(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES Users(id) ON DELETE SET NULL,
    FOREIGN KEY (cancel_requested_by) REFERENCES Users(id) ON DELETE SET NULL,
    FOREIGN KEY (cancelled_by) REFERENCES Users(id) ON DELETE SET NULL
);

-- 15.6. Export_Request_Details (Chi tiết đề xuất xuất kho)
CREATE TABLE Export_Request_Details (
    request_id INT,
    product_id INT,
    quantity INT NOT NULL,
    PRIMARY KEY (request_id, product_id),
    FOREIGN KEY (request_id) REFERENCES Export_Requests(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE RESTRICT
);

-- 16. Export_Tickets (Phiếu xuất kho thực tế - GIN)
CREATE TABLE Export_Tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_code VARCHAR(50) NOT NULL UNIQUE,
    request_id INT NOT NULL,                         -- Tham chiếu yêu cầu xuất kho gốc
    keeper_id INT NOT NULL,                           -- Người tạo phiếu xuất (Warehouse Staff - Req 37)
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',     -- DRAFT (chưa chốt), CONFIRMED (đã trừ tồn), CANCELLED
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    confirmed_by INT DEFAULT NULL,                   -- Confirm bởi Warehouse Manager (Req 39)
    confirmed_at DATETIME DEFAULT NULL,
    FOREIGN KEY (request_id) REFERENCES Export_Requests(id) ON DELETE RESTRICT,
    FOREIGN KEY (keeper_id) REFERENCES Users(id) ON DELETE RESTRICT,
    FOREIGN KEY (confirmed_by) REFERENCES Users(id) ON DELETE SET NULL
);

-- 17. Export_Ticket_Details (Chi tiết phiếu xuất)
CREATE TABLE Export_Ticket_Details (
    ticket_id INT,
    product_id INT,
    quantity INT NOT NULL,
    unit_cost DECIMAL(12, 2) NOT NULL DEFAULT 0.00,  -- Giá vốn tại thời điểm xuất (snapshot từ average_cost)
    PRIMARY KEY (ticket_id, product_id),
    FOREIGN KEY (ticket_id) REFERENCES Export_Tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE RESTRICT
);


-- 17.5. Product_Items (Danh sách sản phẩm vật lý chi tiết - Serial Numbers)
CREATE TABLE Product_Items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    serial_number VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(30) NOT NULL DEFAULT 'IN_STOCK',  -- IN_STOCK, EXPORTED, DAMAGED
    import_ticket_id INT NOT NULL,
    export_ticket_id INT DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE,
    FOREIGN KEY (import_ticket_id) REFERENCES Import_Tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (export_ticket_id) REFERENCES Export_Tickets(id) ON DELETE SET NULL
);



-- ========================================================
-- PART 5: INVENTORY CONTROL & AUDITING (KIỂM KÊ & THẺ KHO)
-- ========================================================

-- 18. Stocktakes (Phiếu kiểm kê)
CREATE TABLE Stocktakes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    stocktake_code VARCHAR(50) NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INT NOT NULL,                         -- Tạo bởi Warehouse Staff (Req 42)
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',     -- DRAFT, SUBMITTED, APPROVED, REJECTED
    submitted_at DATETIME DEFAULT NULL,              -- Nộp phiếu (Req 44)
    approved_by INT DEFAULT NULL,                    -- Duyệt bởi Business Admin (Req 45)
    approved_at DATETIME DEFAULT NULL,
    notes TEXT,
    FOREIGN KEY (created_by) REFERENCES Users(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES Users(id) ON DELETE SET NULL
);

-- 19. Stocktake_Details (Chi tiết kiểm kê)
CREATE TABLE Stocktake_Details (
    stocktake_id INT,
    product_id INT,
    theoretical_qty INT NOT NULL,                    -- Tồn lý thuyết lúc tạo phiếu (chốt cứng - Req 42)
    actual_qty INT NOT NULL,                         -- Tồn đếm thực tế (Req 43)
    discrepancy INT NOT NULL,                        -- Chênh lệch = actual - theoretical
    PRIMARY KEY (stocktake_id, product_id),
    FOREIGN KEY (stocktake_id) REFERENCES Stocktakes(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE RESTRICT
);

-- 20. Product_Ledger (Thẻ kho - audit trail + running balance - Req 46)
CREATE TABLE Product_Ledger (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,           -- IMPORT, EXPORT, STOCKTAKE
    reference_id INT NOT NULL,                        -- ID phiếu nguồn
    change_quantity INT NOT NULL,                     -- +nhập / -xuất / +/- kiểm kê
    balance_quantity INT NOT NULL,                    -- Tồn sau giao dịch (running balance)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES Users(id) ON DELETE SET NULL
);


-- ========================================================
-- PART 6: SYSTEM MONITORING (NHẬT KÝ HỆ THỐNG - Req 50)
-- ========================================================

-- 21. System_Logs
CREATE TABLE System_Logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(255) NOT NULL,                    -- LOGIN, CREATE_TICKET, CONFIRM_TICKET, APPROVE_PO, APPROVE_STOCKTAKE...
    ip_address VARCHAR(45),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    details TEXT,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE SET NULL
);


-- ========================================================
-- DATA SEEDING (KHỞI TẠO DỮ LIỆU BAN ĐẦU)
-- ========================================================

-- Seed 5 Roles
INSERT INTO Roles (id, role_name, description, status) VALUES
(1, 'System Admin', 'Phòng IT - quản trị hệ thống, người dùng, phân quyền', TRUE),
(2, 'Business Admin', 'Giám đốc - phê duyệt PO/kiểm kê, xem báo cáo tổng quan', TRUE),
(3, 'Warehouse Manager', 'Quản lý kho - quản lý master data, confirm phiếu nhập/xuất', TRUE),
(4, 'Warehouse Staff', 'Thủ kho - tạo phiếu nhập/xuất, đếm kiểm kê', TRUE),
(5, 'Sales Staff', 'Nhân viên KD - tạo đơn mua hàng, quản lý nhà cung cấp', TRUE);

-- Seed Permissions chi tiết, map đúng từng requirement
INSERT INTO Permissions (id, permission_name, description) VALUES
-- System Admin
(1,  'USER_VIEW',               'Xem danh sách và thông tin người dùng'),
(2,  'USER_ADD',                'Thêm mới người dùng'),
(3,  'USER_EDIT',               'Sửa thông tin người dùng'),
(4,  'USER_TOGGLE',             'Tắt/Bật trạng thái người dùng'),
(5,  'ROLE_VIEW',               'Xem danh sách vai trò hệ thống'),
(6,  'ROLE_ADD',                'Thêm mới vai trò'),
(7,  'ROLE_EDIT',               'Sửa tên vai trò'),
(8,  'ROLE_TOGGLE',             'Tắt/Bật trạng thái vai trò'),
(9,  'ROLE_ASSIGN',             'Phân quyền (Permissions) cho vai trò'),
(10, 'SYSTEM_LOG_VIEW',         'Xem nhật ký hoạt động hệ thống'),
-- Master Data
(11, 'SUPPLIER_VIEW',           'Xem danh sách nhà cung cấp'),
(12, 'SUPPLIER_ADD',            'Thêm mới nhà cung cấp'),
(13, 'SUPPLIER_EDIT',           'Sửa nhà cung cấp'),
(14, 'SUPPLIER_TOGGLE',         'Tắt/Bật trạng thái nhà cung cấp'),
(15, 'PRODUCT_VIEW',            'Xem danh sách và chi tiết sản phẩm'),
(16, 'PRODUCT_ADD',             'Thêm mới sản phẩm'),
(17, 'PRODUCT_EDIT',            'Sửa sản phẩm'),
(18, 'PRODUCT_TOGGLE',          'Tắt/Bật sản phẩm'),
(19, 'CATEGORY_VIEW',           'Xem danh sách ngành hàng'),
(20, 'CATEGORY_ADD',            'Thêm mới ngành hàng'),
(21, 'CATEGORY_EDIT',           'Sửa ngành hàng'),
(22, 'CATEGORY_TOGGLE',         'Tắt/Bật ngành hàng'),
(23, 'BRAND_VIEW',              'Xem danh sách thương hiệu'),
(24, 'BRAND_ADD',               'Thêm mới thương hiệu'),
(25, 'BRAND_EDIT',              'Sửa thương hiệu'),
(26, 'BRAND_TOGGLE',            'Tắt/Bật thương hiệu'),
(27, 'DESTINATION_VIEW',        'Xem danh sách điểm nhận nội bộ'),
(28, 'DESTINATION_ADD',         'Thêm điểm nhận nội bộ'),
(29, 'DESTINATION_EDIT',        'Sửa điểm nhận nội bộ'),
(30, 'DESTINATION_TOGGLE',      'Tắt/Bật điểm nhận nội bộ'),
-- Purchase Orders
(31, 'PO_VIEW',                 'Xem danh sách/chi tiết đơn mua hàng'),
(32, 'PO_ADD',                  'Tạo mới đơn mua hàng'),
(33, 'PO_EDIT',                 'Sửa đơn mua hàng'),
(34, 'PO_CANCEL',               'Hủy đơn mua hàng'),
(35, 'PO_APPROVE',              'Duyệt/từ chối đơn mua hàng'),
-- Import/Export GIN/GRN
(36, 'IMPORT_TICKET_VIEW',      'Xem danh sách phiếu nhập kho'),
(37, 'IMPORT_TICKET_ADD',       'Tạo phiếu nhập kho'),
(38, 'IMPORT_TICKET_CONFIRM',   'Confirm phiếu nhập, chốt tồn'),
(39, 'IMPORT_TICKET_CANCEL',    'Hủy phiếu nhập kho'),
(40, 'EXPORT_TICKET_VIEW',      'Xem danh sách phiếu xuất kho'),
(41, 'EXPORT_TICKET_ADD',       'Tạo phiếu xuất kho'),
(42, 'EXPORT_TICKET_CONFIRM',   'Confirm phiếu xuất, chốt tồn'),
(43, 'EXPORT_TICKET_CANCEL',    'Hủy phiếu xuất kho'),
-- Stocktake
(44, 'STOCKTAKE_VIEW',          'Xem danh sách phiếu kiểm kê'),
(45, 'STOCKTAKE_ADD',           'Tạo phiếu kiểm kê'),
(46, 'STOCKTAKE_EDIT',          'Sửa phiếu kiểm kê'),
(47, 'STOCKTAKE_SUBMIT',        'Nộp phiếu kiểm kê'),
(48, 'STOCKTAKE_APPROVE',       'Duyệt phiếu kiểm kê'),
(49, 'STOCKTAKE_REJECT',        'Từ chối phiếu kiểm kê'),
-- Analytics & Alerts
(50, 'STOCK_LEDGER_VIEW',       'Xem lịch sử thẻ kho'),
(51, 'LOW_STOCK_ALERT_VIEW',    'Xem cảnh báo tồn thấp'),
(52, 'DASHBOARD_VIEW',          'Xem dashboard tổng quan'),
(53, 'INVENTORY_VALUE_VIEW',    'Xem báo cáo giá trị kho'),
(54, 'EXPORT_REQ_VIEW',         'Xem danh sách/chi tiết yêu cầu xuất kho'),
(55, 'EXPORT_REQ_ADD',          'Tạo mới yêu cầu xuất kho'),
(56, 'EXPORT_REQ_EDIT',         'Sửa yêu cầu xuất kho'),
(57, 'EXPORT_REQ_CANCEL',       'Hủy yêu cầu xuất kho'),
(58, 'EXPORT_REQ_APPROVE',      'Duyệt/từ chối yêu cầu xuất kho'),
(59, 'PO_REQUESTCANCEL',       'Đề xuất hủy PO đã được duyệt'),
(60, 'PO_APPROVECANCEL',       'Duyệt yêu cầu hủy PO'),
(61, 'EXPORT_REQ_REQUESTCANCEL', 'Đề xuất hủy yêu cầu xuất kho đã được duyệt'),
(62, 'EXPORT_REQ_APPROVECANCEL', 'Duyệt yêu cầu hủy xuất kho');

-- Map Permissions to Roles
-- 1. System Admin
INSERT INTO Role_Permissions (role_id, permission_id) VALUES 
(1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(1,7),(1,8),(1,9),(1,10);
-- 2. Business Admin (Giám đốc)
INSERT INTO Role_Permissions (role_id, permission_id) VALUES 
(2,35),(2,48),(2,52),(2,53),(2,11),(2,15),(2,19),(2,23),(2,27),(2,31),(2,36),(2,40),(2,44),(2,50),(2,51),(2,54),(2,58),(2,60),(2,62);
-- 3. Warehouse Manager
INSERT INTO Role_Permissions (role_id, permission_id) VALUES 
(3,11),(3,12),(3,13),(3,14),(3,15),(3,16),(3,17),(3,18),(3,19),(3,20),(3,21),(3,22),(3,23),(3,24),(3,25),(3,26),(3,27),(3,28),(3,29),(3,30),(3,38),(3,39),(3,42),(3,43),(3,49),(3,31),(3,36),(3,40),(3,44),(3,50),(3,51),(3,54);
-- 4. Warehouse Staff (Thủ kho)
INSERT INTO Role_Permissions (role_id, permission_id) VALUES 
(4,36),(4,37),(4,40),(4,41),(4,44),(4,45),(4,46),(4,47),(4,11),(4,15),(4,19),(4,23),(4,27),(4,50),(4,54);
-- 5. Sales Staff
INSERT INTO Role_Permissions (role_id, permission_id) VALUES 
(5,11),(5,12),(5,13),(5,14),(5,31),(5,32),(5,33),(5,34),(5,15),(5,19),(5,23),(5,36),(5,40),(5,54),(5,55),(5,56),(5,57),(5,59),(5,61);

-- Seed 5 Users (mật khẩu mặc định '123456' băm SHA-256)
INSERT INTO Users (id, username, password, email, full_name, status, role_id) VALUES
(1, 'khachung',   '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'khachung@wms.local',   'Kha Chung',   TRUE, 1),
(2, 'leduy',      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'leduy@wms.local',      'Le Duy',      TRUE, 2),
(3, 'phuonglinh', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'phuonglinh@wms.local', 'Phuong Linh', TRUE, 3),
(4, 'thanhhung',  '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'thanhhung@wms.local',  'Thanh Hung',  TRUE, 4),
(5, 'vietanh',    '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'vietanh@wms.local',    'Viet Anh',    TRUE, 5);

-- Seed Categories
INSERT INTO Categories (id, category_name, description, status) VALUES
(1, 'Điều hòa', 'Máy điều hòa không khí, máy lạnh treo tường, âm trần', TRUE),
(2, 'Tủ lạnh', 'Tủ lạnh gia đình, tủ mát, tủ cấp đông', TRUE),
(3, 'Máy giặt', 'Máy giặt lồng đứng, lồng ngang và máy sấy', TRUE);

-- Seed Brands (Thương hiệu)
INSERT INTO Brands (id, brand_name, description, status) VALUES
(1, 'Panasonic',  'Thương hiệu điện máy gia dụng Nhật Bản', TRUE),
(2, 'Daikin',     'Thương hiệu điều hòa hàng đầu từ Nhật Bản', TRUE),
(3, 'LG',         'Thương hiệu thiết bị gia dụng Hàn Quốc', TRUE),
(4, 'Samsung',    'Tập đoàn công nghệ & gia dụng Hàn Quốc', TRUE),
(5, 'Electrolux', 'Thương hiệu gia dụng Thụy Điển', TRUE);

-- Seed Internal Destinations (Nơi nhận nội bộ)
INSERT INTO Internal_Destinations (id, destination_name, destination_type, address, status) VALUES
(1, 'Cửa hàng Trung tâm Hà Nội',        'STORE',          '100 Đường Cầu Giấy, Cầu Giấy, Hà Nội', TRUE),
(2, 'Cửa hàng Chi nhánh TP. HCM',       'STORE',          '200 Đường Lê Lợi, Quận 1, TP. Hồ Chí Minh', TRUE),
(3, 'Trung tâm Bảo hành Miền Bắc',      'WARRANTY_CENTER','50 Đường Trường Chinh, Đống Đa, Hà Nội', TRUE);

-- Seed Suppliers
INSERT INTO Suppliers (id, supplier_name, contact_name, phone, email, address, status) VALUES
(1, 'Công ty Thiết bị Điện lạnh Hoà Phát', 'Nguyễn Văn Hoà', '0912345678', 'hoaphat@dienlanh.vn',        '123 Đường Giải Phóng, Hai Bà Trưng, Hà Nội', TRUE),
(2, 'Tổng kho Phân phối Daikin Việt Nam',  'Trần Thế Minh',  '0987654321', 'sales@daikindistributor.vn', '456 Đường Nguyễn Văn Linh, Long Biên, Hà Nội', TRUE),
(3, 'Nhà phân phối Điện máy Panasonic',    'Lê Thuỳ Trang',  '0901234567', 'contact@panasonic-dist.vn',  '789 Đường Cộng Hoà, Tân Bình, TP. Hồ Chí Minh', TRUE);

-- Seed Products (default_cost = giá vốn ban đầu; average_cost sẽ khởi tạo = default_cost)
INSERT INTO Products (id, product_name, sku, unit, min_stock, default_cost, average_cost, status, category_id, brand_id, technical_specifications) VALUES
(1, 'Điều hòa Panasonic Inverter 9000 BTU',  'PANA-9000',    'cái', 5, 8500000.00,  8500000.00,  TRUE, 1, 1, 'Công suất: 9000 BTU (1 HP). Tiêu thụ: 0.8 kW/h. Công nghệ Nanoe-G, Inverter.'),
(2, 'Điều hòa Daikin Inverter 12000 BTU',    'DAIKIN-12000', 'cái', 5, 11200000.00, 11200000.00, TRUE, 1, 2, 'Công suất: 12000 BTU (1.5 HP). Tiêu thụ: 1.1 kW/h. Luồng gió Coanda, Mắt thần thông minh.'),
(3, 'Tủ lạnh LG Inverter 635 Lít',           'LG-635L',      'cái', 3, 22490000.00, 22490000.00, TRUE, 2, 3, 'Side by Side. 635 Lít. InstaView Door-in-Door, Hygiene Fresh+.'),
(4, 'Tủ lạnh Samsung Inverter 236 Lít',      'SAMSUNG-236L', 'cái', 5, 6150000.00,  6150000.00,  TRUE, 2, 4, 'Ngăn đá trên. 236 Lít. Optimal Fresh Zone.'),
(5, 'Máy giặt Electrolux lồng ngang 9 Kg',   'ELEC-9KG',     'cái', 4, 10800000.00, 10800000.00, TRUE, 3, 5, 'Lồng ngang. 9 Kg. Vắt 1200 v/p. UltraMix, Hygienic Care.'),
(6, 'Máy giặt LG lồng ngang Inverter 10 Kg', 'LG-10KG',      'cái', 5, 8990000.00,  8990000.00,  TRUE, 3, 3, 'Lồng ngang. 10 Kg. Vắt 1400 v/p. AI DD cảm biến vải.');

-- Khởi tạo tồn kho ban đầu (bắt đầu bằng 0 để theo dõi nguồn gốc qua phiếu nhập)
INSERT INTO Inventories (product_id, quantity) VALUES
(1, 0),
(2, 0),
(3, 0),
(4, 0),
(5, 0),
(6, 0);

-- 1. Đợt nhập kho ban đầu: Khởi tạo số lượng tồn kho ban đầu qua Yêu cầu mua hàng và Phiếu nhập tương ứng
-- Seed Import_Request & Ticket cho tồn kho ban đầu (để liên kết mã Serial tồn kho cũ)
INSERT INTO Import_Requests (id, request_code, supplier_id, staff_id, status, expected_date, approved_by, approved_at) VALUES
(2, 'REQ-INITIAL', 1, 5, 'COMPLETED', '2026-01-01', 2, '2026-01-01 09:00:00');

INSERT INTO Import_Request_Details (request_id, product_id, quantity, unit_price) VALUES
(2, 1, 15, 8500000.00),
(2, 2, 10, 11200000.00),
(2, 3, 4, 22490000.00),
(2, 4, 2, 6150000.00),
(2, 5, 12, 10800000.00),
(2, 6, 3, 8990000.00);

INSERT INTO Import_Tickets (id, ticket_code, request_id, keeper_id, status, confirmed_by, confirmed_at) VALUES
(2, 'TKT-INITIAL-STOCK', 2, 4, 'CONFIRMED', 3, '2026-01-02 10:00:00');

INSERT INTO Import_Ticket_Details (ticket_id, product_id, quantity, unit_price) VALUES
(2, 1, 15, 8500000.00),
(2, 2, 10, 11200000.00),
(2, 3, 4, 22490000.00),
(2, 4, 2, 6150000.00),
(2, 5, 12, 10800000.00),
(2, 6, 3, 8990000.00);

-- Cập nhật số lượng vào bảng Inventories sau khi Confirm phiếu TKT-INITIAL-STOCK
UPDATE Inventories SET quantity = 15 WHERE product_id = 1;
UPDATE Inventories SET quantity = 10 WHERE product_id = 2;
UPDATE Inventories SET quantity = 4 WHERE product_id = 3;
UPDATE Inventories SET quantity = 2 WHERE product_id = 4;
UPDATE Inventories SET quantity = 12 WHERE product_id = 5;
UPDATE Inventories SET quantity = 3 WHERE product_id = 6;

-- Ghi nhận thẻ kho (Product_Ledger) cho đợt nhập ban đầu
INSERT INTO Product_Ledger (product_id, transaction_type, reference_id, change_quantity, balance_quantity, created_by) VALUES
(1, 'IMPORT', 2, 15, 15, 4),
(2, 'IMPORT', 2, 10, 10, 4),
(3, 'IMPORT', 2, 4, 4, 4),
(4, 'IMPORT', 2, 2, 2, 4),
(5, 'IMPORT', 2, 12, 12, 4),
(6, 'IMPORT', 2, 3, 3, 4);

-- 2. Đợt nhập thứ 2: Nhập mua thêm 20 chiếc tủ LG
-- Seed 1 Import_Request (Đơn mua 50 cái tủ lạnh LG)
INSERT INTO Import_Requests (id, request_code, supplier_id, staff_id, status, expected_date, approved_by, approved_at) VALUES
(1, 'REQ-2026-001', 3, 5, 'APPROVED', '2026-02-15', 2, '2026-02-01 09:00:00');

INSERT INTO Import_Request_Details (request_id, product_id, quantity, unit_price) VALUES
(1, 3, 50, 20000000.00);

-- Đợt 1: Nhập thực tế 20 cái tủ lạnh LG, giá thực nhập 20,000,000 (đã CONFIRMED)
INSERT INTO Import_Tickets (id, ticket_code, request_id, keeper_id, status, confirmed_by, confirmed_at) VALUES
(1, 'TKT-2026-001', 1, 4, 'CONFIRMED', 3, '2026-02-05 14:30:00');

INSERT INTO Import_Ticket_Details (ticket_id, product_id, quantity, unit_price) VALUES
(1, 3, 20, 20000000.00);

-- Cập nhật Inventories cho Tủ lạnh LG sau đợt nhập thứ 2: ban đầu 4 cái, nhập thêm 20 -> tồn 24
UPDATE Inventories SET quantity = 24 WHERE product_id = 3;

-- Tính lại giá vốn bình quân cho tủ LG sau khi nhập:
-- (4 cũ x 22,490,000 + 20 mới x 20,000,000) / 24 = 20,415,000
UPDATE Products SET average_cost = 20415000.00 WHERE id = 3;

-- Ghi nhận thẻ kho cho đợt nhập 2
INSERT INTO Product_Ledger (product_id, transaction_type, reference_id, change_quantity, balance_quantity, created_by) VALUES
(3, 'IMPORT', 1, 20, 24, 4);   -- ban đầu 4, +20 = 24

-- Khởi tạo mã Serial cho tồn kho ban đầu (Seed Product_Items)
-- Product 1: PANA-9000 (15 cái, liên kết với phiếu TKT-INITIAL-STOCK)
INSERT INTO Product_Items (product_id, serial_number, status, import_ticket_id) VALUES
(1, 'PANA-9000-001', 'IN_STOCK', 2), (1, 'PANA-9000-002', 'IN_STOCK', 2), (1, 'PANA-9000-003', 'IN_STOCK', 2),
(1, 'PANA-9000-004', 'IN_STOCK', 2), (1, 'PANA-9000-005', 'IN_STOCK', 2), (1, 'PANA-9000-006', 'IN_STOCK', 2),
(1, 'PANA-9000-007', 'IN_STOCK', 2), (1, 'PANA-9000-008', 'IN_STOCK', 2), (1, 'PANA-9000-009', 'IN_STOCK', 2),
(1, 'PANA-9000-010', 'IN_STOCK', 2), (1, 'PANA-9000-011', 'IN_STOCK', 2), (1, 'PANA-9000-012', 'IN_STOCK', 2),
(1, 'PANA-9000-013', 'IN_STOCK', 2), (1, 'PANA-9000-014', 'IN_STOCK', 2), (1, 'PANA-9000-015', 'IN_STOCK', 2);

-- Product 2: DAIKIN-12000 (10 cái, liên kết với phiếu TKT-INITIAL-STOCK)
INSERT INTO Product_Items (product_id, serial_number, status, import_ticket_id) VALUES
(2, 'DAIKIN-12000-001', 'IN_STOCK', 2), (2, 'DAIKIN-12000-002', 'IN_STOCK', 2), (2, 'DAIKIN-12000-003', 'IN_STOCK', 2),
(2, 'DAIKIN-12000-004', 'IN_STOCK', 2), (2, 'DAIKIN-12000-005', 'IN_STOCK', 2), (2, 'DAIKIN-12000-006', 'IN_STOCK', 2),
(2, 'DAIKIN-12000-007', 'IN_STOCK', 2), (2, 'DAIKIN-12000-008', 'IN_STOCK', 2), (2, 'DAIKIN-12000-009', 'IN_STOCK', 2),
(2, 'DAIKIN-12000-010', 'IN_STOCK', 2);

-- Product 3: LG-635L (24 cái)
-- 20 cái thực nhập mới từ phiếu TKT-2026-001 (import_ticket_id = 1)
INSERT INTO Product_Items (product_id, serial_number, status, import_ticket_id) VALUES
(3, 'LG-635L-001', 'IN_STOCK', 1), (3, 'LG-635L-002', 'IN_STOCK', 1), (3, 'LG-635L-003', 'IN_STOCK', 1), (3, 'LG-635L-004', 'IN_STOCK', 1),
(3, 'LG-635L-005', 'IN_STOCK', 1), (3, 'LG-635L-006', 'IN_STOCK', 1), (3, 'LG-635L-007', 'IN_STOCK', 1), (3, 'LG-635L-008', 'IN_STOCK', 1),
(3, 'LG-635L-009', 'IN_STOCK', 1), (3, 'LG-635L-010', 'IN_STOCK', 1), (3, 'LG-635L-011', 'IN_STOCK', 1), (3, 'LG-635L-012', 'IN_STOCK', 1),
(3, 'LG-635L-013', 'IN_STOCK', 1), (3, 'LG-635L-014', 'IN_STOCK', 1), (3, 'LG-635L-015', 'IN_STOCK', 1), (3, 'LG-635L-016', 'IN_STOCK', 1),
(3, 'LG-635L-017', 'IN_STOCK', 1), (3, 'LG-635L-018', 'IN_STOCK', 1), (3, 'LG-635L-019', 'IN_STOCK', 1), (3, 'LG-635L-020', 'IN_STOCK', 1);

-- 4 cái ban đầu của tủ LG (import_ticket_id = 2)
INSERT INTO Product_Items (product_id, serial_number, status, import_ticket_id) VALUES
(3, 'LG-635L-021', 'IN_STOCK', 2), (3, 'LG-635L-022', 'IN_STOCK', 2), (3, 'LG-635L-023', 'IN_STOCK', 2), (3, 'LG-635L-024', 'IN_STOCK', 2);

-- Product 4: SAMSUNG-236L (2 cái, liên kết với phiếu TKT-INITIAL-STOCK)
INSERT INTO Product_Items (product_id, serial_number, status, import_ticket_id) VALUES
(4, 'SAMSUNG-236L-001', 'IN_STOCK', 2), (4, 'SAMSUNG-236L-002', 'IN_STOCK', 2);

-- Product 5: ELEC-9KG (12 cái, liên kết với phiếu TKT-INITIAL-STOCK)
INSERT INTO Product_Items (product_id, serial_number, status, import_ticket_id) VALUES
(5, 'ELEC-9KG-001', 'IN_STOCK', 2), (5, 'ELEC-9KG-002', 'IN_STOCK', 2), (5, 'ELEC-9KG-003', 'IN_STOCK', 2),
(5, 'ELEC-9KG-004', 'IN_STOCK', 2), (5, 'ELEC-9KG-005', 'IN_STOCK', 2), (5, 'ELEC-9KG-006', 'IN_STOCK', 2),
(5, 'ELEC-9KG-007', 'IN_STOCK', 2), (5, 'ELEC-9KG-008', 'IN_STOCK', 2), (5, 'ELEC-9KG-009', 'IN_STOCK', 2),
(5, 'ELEC-9KG-010', 'IN_STOCK', 2), (5, 'ELEC-9KG-011', 'IN_STOCK', 2), (5, 'ELEC-9KG-012', 'IN_STOCK', 2);

-- Product 6: LG-10KG (3 cái, liên kết với phiếu TKT-INITIAL-STOCK)
INSERT INTO Product_Items (product_id, serial_number, status, import_ticket_id) VALUES
(6, 'LG-10KG-001', 'IN_STOCK', 2), (6, 'LG-10KG-002', 'IN_STOCK', 2), (6, 'LG-10KG-003', 'IN_STOCK', 2);

-- ========================================================
-- KẾT THÚC SCRIPT
-- ========================================================

