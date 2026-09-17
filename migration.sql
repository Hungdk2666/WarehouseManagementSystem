-- =============================================================
-- WMS EXISTING DATABASE UPGRADE (ALL-IN-ONE)
-- Run this file by itself only when upgrading an existing wms_db.
-- Fresh installs/resets must run wms_db_v3.sql instead.
-- Do not run this file after wms_db_v3.sql.
-- Idempotent — safe to run again.
-- =============================================================

USE wms_db;

-- =============================================================
-- PHẦN 1: SECURITY
-- =============================================================

-- 1.1 Add OTP expiry column
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Users' AND COLUMN_NAME = 'reset_code_expires_at');
SET @sql1 = IF(@col_exists = 0,
    'ALTER TABLE Users ADD COLUMN reset_code_expires_at DATETIME NULL AFTER reset_code',
    'SELECT 1');
PREPARE stmt FROM @sql1; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1.2 Add OTP attempt tracking column
SET @col_exists2 = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Users' AND COLUMN_NAME = 'reset_attempts');
SET @sql2 = IF(@col_exists2 = 0,
    'ALTER TABLE Users ADD COLUMN reset_attempts INT NOT NULL DEFAULT 0 AFTER reset_code_expires_at',
    'SELECT 1');
PREPARE stmt FROM @sql2; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1.3 Clear any existing reset codes (insecure under old system)
UPDATE Users SET reset_code = NULL, reset_code_expires_at = NULL, reset_attempts = 0 WHERE id > 0;

-- 1.4 Add UNIQUE constraint on username
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Users' AND INDEX_NAME = 'idx_users_username');
SET @sql3 = IF(@idx_exists = 0,
    'ALTER TABLE Users ADD UNIQUE INDEX idx_users_username (username)',
    'SELECT 1');
PREPARE stmt FROM @sql3; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1.5 Add UNIQUE constraint on email
SET @idx_exists2 = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Users' AND INDEX_NAME = 'idx_users_email');
SET @sql4 = IF(@idx_exists2 = 0,
    'ALTER TABLE Users ADD UNIQUE INDEX idx_users_email (email)',
    'SELECT 1');
PREPARE stmt FROM @sql4; EXECUTE stmt; DEALLOCATE PREPARE stmt;


-- =============================================================
-- PHẦN 2: DATA INTEGRITY (Soft Delete Customers)
-- =============================================================

-- 2.1 Thêm cột status vào Customers
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Customers' AND COLUMN_NAME = 'status');
SET @sql1 = IF(@col_exists = 0,
    'ALTER TABLE Customers ADD COLUMN status BOOLEAN NOT NULL DEFAULT TRUE',
    'SELECT 1');
PREPARE stmt FROM @sql1; EXECUTE stmt; DEALLOCATE PREPARE stmt;


-- =============================================================
-- PHẦN 3: ROLLBACK MODULE DISPOSAL (dọn dẹp nếu đã chạy part4)
-- =============================================================

-- 3.1 Xóa Role_Permissions cho disposal (permission_id 75-82)
DELETE FROM Role_Permissions WHERE role_id > 0 AND permission_id BETWEEN 75 AND 82;

-- 3.2 Xóa Permissions disposal
DELETE FROM Permissions WHERE id BETWEEN 75 AND 82;

-- 3.3 Xóa Disposal_Config data
DROP TABLE IF EXISTS Disposal_Config;

-- 3.4 Xóa Disposal_Details
DROP TABLE IF EXISTS Disposal_Details;

-- 3.5 Xóa Disposals
DROP TABLE IF EXISTS Disposals;

-- 3.6 Thu hồi ENUM Product_Items.status (bỏ DISPOSED)
ALTER TABLE Product_Items
  MODIFY status ENUM('IN_STOCK','EXPORTED','IN_TRANSIT','QUARANTINE','LOST')
         NOT NULL DEFAULT 'IN_STOCK';

-- 3.7 Thu hồi ENUM Product_Item_Movements.action (bỏ DISPOSE)
ALTER TABLE Product_Item_Movements
  MODIFY action ENUM('IMPORT_IN','EXPORT_OUT','TRANSFER_OUT','TRANSFER_IN','RETURN_IN',
                     'QUARANTINE','STOCKTAKE_ADJUST') NOT NULL;

-- =============================================================
-- PHẦN 4: STOCKTAKE VERIFICATION (quét serial xác minh khi đếm số lượng bị lệch)
-- =============================================================

-- 4.1 Thêm cột verification_status vào Stocktakes
SET @col_exists_vs = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Stocktakes' AND COLUMN_NAME = 'verification_status');
SET @sql_vs = IF(@col_exists_vs = 0,
    'ALTER TABLE Stocktakes ADD COLUMN verification_status ENUM(''NONE'',''REQUIRED'',''COMPLETED'') NOT NULL DEFAULT ''NONE'' AFTER reject_reason',
    'SELECT 1');
PREPARE stmt FROM @sql_vs; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4.2 Thêm verified_by / verified_at vào Stocktakes
SET @col_exists_vb = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Stocktakes' AND COLUMN_NAME = 'verified_by');
SET @sql_vb = IF(@col_exists_vb = 0,
    'ALTER TABLE Stocktakes ADD COLUMN verified_by INT NULL AFTER verification_status, ADD COLUMN verified_at DATETIME NULL AFTER verified_by',
    'SELECT 1');
PREPARE stmt FROM @sql_vb; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4.3 Thêm cột phase vào Stocktake_Items để phân biệt quét lúc đếm (COUNT) vs quét xác minh (VERIFY)
SET @col_exists_ph = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Stocktake_Items' AND COLUMN_NAME = 'phase');
SET @sql_ph = IF(@col_exists_ph = 0,
    'ALTER TABLE Stocktake_Items ADD COLUMN phase ENUM(''COUNT'',''VERIFY'') NOT NULL DEFAULT ''COUNT'' AFTER note',
    'SELECT 1');
PREPARE stmt FROM @sql_ph; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 5. TÁCH NHẬT KÝ: System Admin (IT) chỉ xem nhật ký HỆ THỐNG,
--    KHÔNG xem nhật ký nghiệp vụ (AUDIT_LOG_VIEW của Business Admin).
-- ============================================================
-- 5.1 Thêm quyền SYSTEM_LOG_VIEW (idempotent)
INSERT INTO Permissions (permission_name, description)
SELECT 'SYSTEM_LOG_VIEW', 'Xem nhật ký hệ thống (người dùng, vai trò, phân quyền, mật khẩu) — System Admin'
WHERE NOT EXISTS (SELECT 1 FROM Permissions WHERE permission_name = 'SYSTEM_LOG_VIEW');

-- 5.2 Gán SYSTEM_LOG_VIEW cho System Admin (role 1)
INSERT IGNORE INTO Role_Permissions (role_id, permission_id)
SELECT 1, id FROM Permissions WHERE permission_name = 'SYSTEM_LOG_VIEW';

-- =============================================================
-- PHẦN 6: TRANSFER RETURN WORKFLOW
-- =============================================================
-- Xuất đủ chuyển kho chỉ là "đang chuyển"; chỉ hoàn thành sau khi
-- kho đích nhận đủ hoặc kho nguồn quét nhận trả đủ serial.
ALTER TABLE Requests
  MODIFY status ENUM('PENDING','APPROVED','PARTIALLY_COMPLETED','PARTIALLY_IN_TRANSIT','PARTIALLY_CLOSED_IN_TRANSIT','IN_TRANSIT',
                     'COMPLETED','PARTIALLY_CLOSED','RETURNING','RETURNED','REJECTED','REVOKED','CANCELLED')
  NOT NULL DEFAULT 'PENDING';

-- Dữ liệu cũ dùng PARTIALLY_IN_TRANSIT được chuẩn hóa trước khi bỏ giá trị cũ khỏi ENUM.
UPDATE Requests
SET status = 'PARTIALLY_CLOSED_IN_TRANSIT'
WHERE id > 0 AND status = 'PARTIALLY_IN_TRANSIT';

ALTER TABLE Requests
  MODIFY status ENUM('PENDING','APPROVED','PARTIALLY_COMPLETED','PARTIALLY_CLOSED_IN_TRANSIT','IN_TRANSIT',
                     'COMPLETED','PARTIALLY_CLOSED','RETURNING','RETURNED','REJECTED','REVOKED','CANCELLED')
  NOT NULL DEFAULT 'PENDING';
SET @col_exists_expected_serials = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Requests' AND COLUMN_NAME = 'expected_serials');
SET @sql_expected_serials = IF(@col_exists_expected_serials = 0,
    'ALTER TABLE Requests ADD COLUMN expected_serials TEXT NULL AFTER ref_ticket_id', 'SELECT 1');
PREPARE stmt FROM @sql_expected_serials; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists_return_status = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Tickets' AND COLUMN_NAME = 'return_status');
SET @sql_return_status = IF(@col_exists_return_status = 0,
    'ALTER TABLE Tickets ADD COLUMN return_status ENUM(''NONE'',''PARTIAL'',''FULL'') NOT NULL DEFAULT ''NONE'' AFTER status',
    'SELECT 1');
PREPARE stmt FROM @sql_return_status; EXECUTE stmt; DEALLOCATE PREPARE stmt;


-- 5.3 Gỡ AUDIT_LOG_VIEW (nhật ký nghiệp vụ) khỏi System Admin
DELETE rp FROM Role_Permissions rp
JOIN Permissions p ON p.id = rp.permission_id
WHERE rp.role_id = 1 AND p.permission_name = 'AUDIT_LOG_VIEW';
-- ============================================================
-- 6. TỒN KHO THEO TÌNH TRẠNG + LEDGER V2
-- Hệ thống ngừng tạo lý do xuất OTHER/DISPOSAL. Giá trị cũ (nếu có) được giữ để bảo toàn lịch sử.
-- ============================================================
-- Chỉ thu gọn ENUM khi không còn dữ liệu lịch sử dùng hai lý do đã bỏ.
SET @legacy_out_reasons = (SELECT COUNT(*) FROM Requests WHERE reason IN ('OTHER','DISPOSAL'));

SET @has_chk_partner = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'Requests'
      AND CONSTRAINT_NAME = 'chk_req_partner' AND CONSTRAINT_TYPE = 'CHECK');
SET @sql_drop_partner = IF(@legacy_out_reasons = 0 AND @has_chk_partner > 0,
    'ALTER TABLE Requests DROP CHECK chk_req_partner', 'SELECT 1');
PREPARE stmt FROM @sql_drop_partner; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_chk_reason = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'Requests'
      AND CONSTRAINT_NAME = 'chk_req_type_reason' AND CONSTRAINT_TYPE = 'CHECK');
SET @sql_drop_reason = IF(@legacy_out_reasons = 0 AND @has_chk_reason > 0,
    'ALTER TABLE Requests DROP CHECK chk_req_type_reason', 'SELECT 1');
PREPARE stmt FROM @sql_drop_reason; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql_reason_enum = IF(@legacy_out_reasons = 0,
    'ALTER TABLE Requests MODIFY reason ENUM(''PURCHASE'',''RETURN'',''TRANSFER'',''DISPLAY'',''WARRANTY'',''CUSTOMER_SALE'') NOT NULL',
    'SELECT 1');
PREPARE stmt FROM @sql_reason_enum; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_chk_reason_after = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'Requests'
      AND CONSTRAINT_NAME = 'chk_req_type_reason' AND CONSTRAINT_TYPE = 'CHECK');
SET @sql_add_reason = IF(@legacy_out_reasons = 0 AND @has_chk_reason_after = 0,
    'ALTER TABLE Requests ADD CONSTRAINT chk_req_type_reason CHECK (
       (type=''IN'' AND reason IN (''PURCHASE'',''RETURN'',''TRANSFER'')) OR
       (type=''OUT'' AND reason IN (''TRANSFER'',''DISPLAY'',''WARRANTY'',''CUSTOMER_SALE'')))',
    'SELECT 1');
PREPARE stmt FROM @sql_add_reason; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_chk_partner_after = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'Requests'
      AND CONSTRAINT_NAME = 'chk_req_partner' AND CONSTRAINT_TYPE = 'CHECK');
SET @sql_add_partner = IF(@legacy_out_reasons = 0 AND @has_chk_partner_after = 0,
    'ALTER TABLE Requests ADD CONSTRAINT chk_req_partner CHECK (
       (reason=''PURCHASE'' AND partner_type=''SUPPLIER'' AND partner_id IS NOT NULL) OR
       (reason=''RETURN'' AND partner_type IN (''CUSTOMER'',''INTERNAL_DEST'',''NONE'')) OR
       (type=''IN'' AND reason=''TRANSFER'' AND partner_type=''WAREHOUSE'' AND partner_id IS NOT NULL AND partner_id <> warehouse_id AND ref_ticket_id IS NOT NULL) OR
       (type=''OUT'' AND reason=''TRANSFER'' AND partner_type=''WAREHOUSE'' AND partner_id IS NOT NULL AND partner_id <> warehouse_id) OR
       (reason=''CUSTOMER_SALE'' AND partner_type=''CUSTOMER'' AND partner_id IS NOT NULL) OR
       (reason IN (''DISPLAY'',''WARRANTY'') AND partner_type=''INTERNAL_DEST'' AND partner_id IS NOT NULL))',
    'SELECT 1');
PREPARE stmt FROM @sql_add_partner; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ledger_cols = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Product_Ledger' AND COLUMN_NAME = 'balance_new_quantity');
SET @sql_ledger = IF(@ledger_cols = 0,
    'ALTER TABLE Product_Ledger
       ADD COLUMN change_new_quantity INT NULL AFTER balance_quantity,
       ADD COLUMN change_used_quantity INT NULL AFTER change_new_quantity,
       ADD COLUMN change_damaged_quantity INT NULL AFTER change_used_quantity,
       ADD COLUMN balance_new_quantity INT NULL AFTER change_damaged_quantity,
       ADD COLUMN balance_used_quantity INT NULL AFTER balance_new_quantity,
       ADD COLUMN balance_damaged_quantity INT NULL AFTER balance_used_quantity',
    'SELECT 1');
PREPARE stmt FROM @sql_ledger; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- View khả dụng có thêm tồn/đặt giữ hàng hỏng và tổng tồn vật lý.
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

-- Mốc mở đầu cho báo cáo chi tiết theo tình trạng. Chỉ tạo một lần cho mỗi kho/SKU.
INSERT INTO Product_Ledger
(product_id, transaction_type, reference_id, change_quantity, balance_quantity,
 change_new_quantity, change_used_quantity, change_damaged_quantity,
 balance_new_quantity, balance_used_quantity, balance_damaged_quantity,
 warehouse_id, created_by, created_at)
SELECT i.product_id, 'OPENING_BALANCE', 0,
       COALESCE(s.new_qty,0) + COALESCE(s.used_qty,0) + COALESCE(s.damaged_qty,0),
       COALESCE(s.new_qty,0) + COALESCE(s.used_qty,0) + COALESCE(s.damaged_qty,0),
       COALESCE(s.new_qty,0), COALESCE(s.used_qty,0), COALESCE(s.damaged_qty,0),
       COALESCE(s.new_qty,0), COALESCE(s.used_qty,0), COALESCE(s.damaged_qty,0),
       i.warehouse_id, NULL, NOW()
FROM Inventories i
LEFT JOIN (
    SELECT warehouse_id, product_id,
           COUNT(CASE WHEN status='IN_STOCK' AND item_condition='NEW' THEN 1 END) AS new_qty,
           COUNT(CASE WHEN status='IN_STOCK' AND item_condition='USED' THEN 1 END) AS used_qty,
           COUNT(CASE WHEN status='QUARANTINE' AND item_condition='DAMAGED' THEN 1 END) AS damaged_qty
    FROM Product_Items
    GROUP BY warehouse_id, product_id
) s ON s.warehouse_id=i.warehouse_id AND s.product_id=i.product_id
WHERE NOT EXISTS (
    SELECT 1 FROM Product_Ledger l
    WHERE l.warehouse_id=i.warehouse_id AND l.product_id=i.product_id
      AND l.transaction_type='OPENING_BALANCE'
);

-- ============================================================
-- 7. QUAN LY HAI MA SERIAL SONG SONG
-- Ma WMS (serial_number) van duy nhat tren toan he thong.
-- Serial nha san xuat chi duy nhat trong cung mot san pham.
-- ============================================================

-- Bo UNIQUE cu neu manufacturer_serial dang bi bat duy nhat toan he thong.
SET @old_mfr_unique_index = (
    SELECT INDEX_NAME
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Product_Items'
      AND NON_UNIQUE = 0
    GROUP BY INDEX_NAME
    HAVING COUNT(*) = 1 AND MAX(COLUMN_NAME = 'manufacturer_serial') = 1
    LIMIT 1
);
SET @sql_drop_old_mfr_unique = IF(
    @old_mfr_unique_index IS NULL,
    'SELECT 1',
    CONCAT('ALTER TABLE Product_Items DROP INDEX `',
           REPLACE(@old_mfr_unique_index, '`', '``'), '`')
);
PREPARE stmt FROM @sql_drop_old_mfr_unique;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Cho phep hai san pham khac nhau co cung serial nha san xuat,
-- nhung chan hai mon cung san pham dung chung mot serial.
SET @has_product_mfr_unique = (
    SELECT COUNT(*) FROM (
        SELECT INDEX_NAME
        FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'Product_Items'
          AND NON_UNIQUE = 0
        GROUP BY INDEX_NAME
        HAVING GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX)
               = 'product_id,manufacturer_serial'
    ) product_mfr_indexes
);
SET @sql_add_product_mfr_unique = IF(
    @has_product_mfr_unique = 0,
    'ALTER TABLE Product_Items ADD UNIQUE INDEX uk_product_manufacturer_serial (product_id, manufacturer_serial)',
    'SELECT 1'
);
PREPARE stmt FROM @sql_add_product_mfr_unique;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================
-- REMOVE LEGACY PRODUCT SCAN CODE
-- The receiving flow now prints and scans WMS serials before capturing the
-- manufacturer serial, so the product-level UPC/EAN/model code is obsolete.
-- ============================================================
SET @has_products_scan_code_idx = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Products'
      AND INDEX_NAME = 'idx_products_scan_code'
);
SET @sql_drop_products_scan_code_idx = IF(
    @has_products_scan_code_idx > 0,
    'ALTER TABLE Products DROP INDEX idx_products_scan_code',
    'SELECT 1'
);
PREPARE stmt FROM @sql_drop_products_scan_code_idx;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_products_scan_code_unique = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Products'
      AND INDEX_NAME = 'uk_products_scan_code'
);
SET @sql_drop_products_scan_code_unique = IF(
    @has_products_scan_code_unique > 0,
    'ALTER TABLE Products DROP INDEX uk_products_scan_code',
    'SELECT 1'
);
PREPARE stmt FROM @sql_drop_products_scan_code_unique;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_products_scan_code = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Products'
      AND COLUMN_NAME = 'scan_code'
);
SET @sql_drop_products_scan_code = IF(
    @has_products_scan_code > 0,
    'ALTER TABLE Products DROP COLUMN scan_code',
    'SELECT 1'
);
PREPARE stmt FROM @sql_drop_products_scan_code;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Dua OPENING_BALANCE ve truoc giao dich dau tien cua cung kho/SKU.
-- Khong thay doi so luong, chi sua moc thoi gian de bao cao tinh dung thu tu.
UPDATE Product_Ledger ob
LEFT JOIN (
    SELECT source.warehouse_id, source.product_id, MIN(source.created_at) AS first_tx
    FROM (
        SELECT warehouse_id, product_id, created_at
        FROM Product_Ledger
        WHERE transaction_type <> 'OPENING_BALANCE'
    ) source
    GROUP BY source.warehouse_id, source.product_id
) first_tx ON first_tx.warehouse_id = ob.warehouse_id
           AND first_tx.product_id = ob.product_id
SET ob.created_at = COALESCE(
    DATE_SUB(first_tx.first_tx, INTERVAL 1 SECOND),
    '2000-01-01 00:00:00'
)
WHERE ob.id > 0
  AND ob.transaction_type = 'OPENING_BALANCE';

-- ============================================================
-- STOCKTAKE: snapshot theo tình trạng hàng
-- Phiếu mới kiểm đủ hàng mới, hàng cũ và hàng hỏng/cách ly.
-- Các cột tổng cũ được giữ để tương thích báo cáo và lịch sử.
-- ============================================================
SET @has_stk_theoretical_new = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='Stocktake_Details' AND COLUMN_NAME='theoretical_new_qty');
SET @sql_stk_theoretical_new = IF(@has_stk_theoretical_new=0,
  'ALTER TABLE Stocktake_Details ADD COLUMN theoretical_new_qty INT NOT NULL DEFAULT 0 AFTER damaged_qty', 'SELECT 1');
PREPARE stmt FROM @sql_stk_theoretical_new; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_stk_theoretical_used = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='Stocktake_Details' AND COLUMN_NAME='theoretical_used_qty');
SET @sql_stk_theoretical_used = IF(@has_stk_theoretical_used=0,
  'ALTER TABLE Stocktake_Details ADD COLUMN theoretical_used_qty INT NOT NULL DEFAULT 0 AFTER theoretical_new_qty', 'SELECT 1');
PREPARE stmt FROM @sql_stk_theoretical_used; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_stk_theoretical_damaged = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='Stocktake_Details' AND COLUMN_NAME='theoretical_damaged_qty');
SET @sql_stk_theoretical_damaged = IF(@has_stk_theoretical_damaged=0,
  'ALTER TABLE Stocktake_Details ADD COLUMN theoretical_damaged_qty INT NOT NULL DEFAULT 0 AFTER theoretical_used_qty', 'SELECT 1');
PREPARE stmt FROM @sql_stk_theoretical_damaged; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_stk_actual_new = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='Stocktake_Details' AND COLUMN_NAME='actual_new_qty');
SET @sql_stk_actual_new = IF(@has_stk_actual_new=0,
  'ALTER TABLE Stocktake_Details ADD COLUMN actual_new_qty INT NOT NULL DEFAULT 0 AFTER theoretical_damaged_qty', 'SELECT 1');
PREPARE stmt FROM @sql_stk_actual_new; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_stk_actual_used = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='Stocktake_Details' AND COLUMN_NAME='actual_used_qty');
SET @sql_stk_actual_used = IF(@has_stk_actual_used=0,
  'ALTER TABLE Stocktake_Details ADD COLUMN actual_used_qty INT NOT NULL DEFAULT 0 AFTER actual_new_qty', 'SELECT 1');
PREPARE stmt FROM @sql_stk_actual_used; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_stk_actual_damaged = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='Stocktake_Details' AND COLUMN_NAME='actual_damaged_qty');
SET @sql_stk_actual_damaged = IF(@has_stk_actual_damaged=0,
  'ALTER TABLE Stocktake_Details ADD COLUMN actual_damaged_qty INT NOT NULL DEFAULT 0 AFTER actual_used_qty', 'SELECT 1');
PREPARE stmt FROM @sql_stk_actual_damaged; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Phiếu cũ vẫn giữ cách tính cũ: toàn bộ lý thuyết được xem là hàng mới,
-- số hỏng thực tế cũ được giữ nguyên. Không viết lại lịch sử đã điều chỉnh.
UPDATE Stocktake_Details
SET theoretical_new_qty = theoretical_qty,
    theoretical_used_qty = 0,
    theoretical_damaged_qty = 0,
    actual_new_qty = GREATEST(actual_qty - damaged_qty, 0),
    actual_used_qty = 0,
    actual_damaged_qty = damaged_qty
WHERE theoretical_new_qty = 0
  AND theoretical_used_qty = 0
  AND theoretical_damaged_qty = 0
  AND actual_new_qty = 0
  AND actual_used_qty = 0
  AND actual_damaged_qty = 0
  AND stocktake_id >= 0;

-- =============================================================
-- REPORTING ROLLUP TABLES, INDEXES AND TRIGGER
-- Consolidated from performance_rollup_migration.sql so an existing
-- database needs only this one upgrade script.
-- =============================================================

CREATE TABLE IF NOT EXISTS Inventory_Daily_Snapshots (
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

CREATE TABLE IF NOT EXISTS Inventory_Daily_Movements (
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

CREATE TABLE IF NOT EXISTS Reporting_Rollup_State (
    rollup_name VARCHAR(60) NOT NULL,
    coverage_start DATE NOT NULL,
    last_processed_ledger_id INT NOT NULL DEFAULT 0,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (rollup_name)
);

SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Product_Ledger'
      AND INDEX_NAME = 'idx_ledger_report_date_wh_product');
SET @idx_sql = IF(@idx_exists = 0,
    'ALTER TABLE Product_Ledger ADD INDEX idx_ledger_report_date_wh_product (created_at, warehouse_id, product_id, id)',
    'SELECT 1');
PREPARE stmt FROM @idx_sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Product_Ledger'
      AND INDEX_NAME = 'idx_ledger_snapshot_wh_product_date');
SET @idx_sql = IF(@idx_exists = 0,
    'ALTER TABLE Product_Ledger ADD INDEX idx_ledger_snapshot_wh_product_date (warehouse_id, product_id, created_at, id)',
    'SELECT 1');
PREPARE stmt FROM @idx_sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Product_Items'
      AND INDEX_NAME = 'idx_product_items_inventory_status');
SET @idx_sql = IF(@idx_exists = 0,
    'ALTER TABLE Product_Items ADD INDEX idx_product_items_inventory_status (warehouse_id, product_id, status, item_condition)',
    'SELECT 1');
PREPARE stmt FROM @idx_sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Tickets'
      AND INDEX_NAME = 'idx_tickets_report_type_status_date');
SET @idx_sql = IF(@idx_exists = 0,
    'ALTER TABLE Tickets ADD INDEX idx_tickets_report_type_status_date (type, status, confirmed_at, warehouse_id)',
    'SELECT 1');
PREPARE stmt FROM @idx_sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Requests'
      AND INDEX_NAME = 'idx_requests_warehouse_type_status_date');
SET @idx_sql = IF(@idx_exists = 0,
    'ALTER TABLE Requests ADD INDEX idx_requests_warehouse_type_status_date (warehouse_id, type, status, created_at)',
    'SELECT 1');
PREPARE stmt FROM @idx_sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Audit_Logs'
      AND INDEX_NAME = 'idx_audit_logs_created_at_id');
SET @idx_sql = IF(@idx_exists = 0,
    'ALTER TABLE Audit_Logs ADD INDEX idx_audit_logs_created_at_id (created_at, id)',
    'SELECT 1');
PREPARE stmt FROM @idx_sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Every new ledger row refreshes one daily closing balance and movement row.
DROP TRIGGER IF EXISTS trg_product_ledger_reporting_rollup;
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

-- Existing ledger history is not replayed automatically. Run
-- ReportingRollupBackfillService once in small date batches when historical
-- rollup coverage is required.
