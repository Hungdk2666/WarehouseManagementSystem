# Bài Tập Thực Hành Viết SQL (Chuẩn bị bảo vệ môn)

Phần thi viết SQL trực tiếp trên MySQL luôn là phần khiến nhiều sinh viên "rụng" nhất vì hay quên cú pháp. Dưới đây là các câu lệnh SQL bám cực sát vào phần việc của bạn (Quản lý Sản phẩm & Yêu cầu Nhập kho).

Hãy tự gõ lại những câu này vài lần trên MySQL Workbench (hoặc phpMyAdmin) để "nhớ tay" nhé!

---

## 1. Lệnh SELECT (Dùng để Xem / Hiển thị)

Thầy rất thích bắt bạn dùng `JOIN` để lấy tên thay vì chỉ hiển thị ID.

**Câu hỏi 1: Viết câu lệnh lấy danh sách Sản phẩm, kèm theo Tên Danh Mục (Category) và Tên Thương Hiệu (Brand).**
```sql
SELECT 
    p.id, 
    p.product_name, 
    p.sku, 
    c.category_name, 
    b.brand_name
FROM Products p
LEFT JOIN Categories c ON p.category_id = c.id
LEFT JOIN Brands b ON p.brand_id = b.id;
```
*(Tip: Dùng `LEFT JOIN` để lỡ sản phẩm nào chưa có Brand thì nó vẫn hiện ra, không bị mất tích).*

**Câu hỏi 2: Lấy danh sách các Phiếu Yêu Cầu Nhập Kho (Requests loại 'IN'), hiển thị kèm Tên người tạo (Staff) và Tên Kho (Warehouse).**
```sql
SELECT 
    r.request_code, 
    r.status, 
    w.warehouse_name, 
    u.full_name AS staff_name
FROM Requests r
JOIN Warehouses w ON r.warehouse_id = w.id
JOIN Users u ON r.staff_id = u.id
WHERE r.type = 'IN';
```

**Câu hỏi 3 (Khó hơn tí): Xem chi tiết các mặt hàng cần nhập trong Yêu cầu số 1.**
```sql
SELECT 
    rd.request_id, 
    p.product_name, 
    rd.quantity, 
    p.unit
FROM Request_Details rd
JOIN Products p ON rd.product_id = p.id
WHERE rd.request_id = 1;
```

---

## 2. Lệnh INSERT INTO (Dùng để Thêm Mới)

Thầy có thể bảo: "Bây giờ em code bằng tay câu SQL thêm một sản phẩm mới vào DB cho tôi xem".

**Câu hỏi 4: Thêm một Sản phẩm mới vào bảng `Products` (Tên: Bàn phím cơ, SKU: BP-001, Danh mục 1, Brand 2).**
```sql
INSERT INTO Products (product_name, sku, unit, min_stock, average_cost, status, category_id, brand_id) 
VALUES ('Bàn phím cơ', 'BP-001', 'Cái', 10, 0, 1, 1, 2);
```

**Câu hỏi 5: Tạo một Yêu cầu nhập kho mới (Nhập cho kho số 1, người tạo là nhân viên số 3).**
```sql
INSERT INTO Requests (request_code, type, reason, warehouse_id, partner_type, partner_id, staff_id, status)
VALUES ('REQ-IN-2023-009', 'IN', 'PURCHASE', 1, 'SUPPLIER', 2, 3, 'PENDING');
```

---

## 3. Lệnh UPDATE (Dùng để Sửa / Cập nhật / Đổi trạng thái)

**Câu hỏi 6: Sửa lại tên sản phẩm và số lượng tồn kho tối thiểu (min_stock) của sản phẩm có id = 5.**
```sql
UPDATE Products 
SET product_name = 'Chuột không dây', min_stock = 20 
WHERE id = 5;
```

**Câu hỏi 7: Thực hiện thao tác Duyệt Phiếu Nhập (Approve Request) có id = 10, người duyệt là Quản lý số 2.**
*(Lưu ý: Không chỉ đổi status, mà còn phải ghi nhận ai là người duyệt và thời gian duyệt).*
```sql
UPDATE Requests 
SET status = 'APPROVED', 
    approved_by = 2, 
    approved_at = NOW() 
WHERE id = 10;
```

**Câu hỏi 8: Tính năng Kích hoạt/Vô hiệu hóa sản phẩm (Active/Deactive). Hãy đổi trạng thái (status) ngược lại cho sản phẩm số 3.**
```sql
UPDATE Products 
SET status = NOT status 
WHERE id = 3;
```
*(Tip: `NOT status` là một mẹo cực hay, nếu đang True (1) sẽ thành False (0) và ngược lại).*

---

## 4. Lệnh DELETE (Dùng để Xóa)

Trong hệ thống thực tế, người ta ít khi xoá sản phẩm hay phiếu nhập (vì ảnh hưởng lịch sử), mà thường xoá các dữ liệu phụ.

**Câu hỏi 9: Khi người dùng bấm Update sản phẩm và muốn lưu thông số kỹ thuật mới, hệ thống phải xoá thông số cũ đi trước. Hãy xoá thông số kỹ thuật của sản phẩm số 5.**
```sql
DELETE FROM Product_Specifications 
WHERE product_id = 5;
```

**Câu hỏi 10: Xoá thử một Yêu cầu Nhập kho đang bị nháp/lỗi có ID = 15.**
*(Cảnh báo: Nếu phiếu này đã có chi tiết trong bảng `Request_Details` thì phải xoá chi tiết trước).*
```sql
-- Bước 1: Xóa danh sách đồ trong phiếu
DELETE FROM Request_Details WHERE request_id = 15;

-- Bước 2: Xóa cái vỏ phiếu
DELETE FROM Requests WHERE id = 15;
```

---
### 💡 Lời khuyên cuối trước khi lên thớt:
1. **Lệnh nào cũng phải có `WHERE`** (trừ INSERT). Đặc biệt là `UPDATE` và `DELETE`, quên chữ `WHERE` là đi tông cả cái database, thầy sẽ trừ điểm rất nặng.
2. Từ khoá `NOW()` dùng để lấy ngày giờ hiện tại của hệ thống, rất hay dùng khi lưu thời gian tạo/duyệt.
3. Khi JOIN bảng, nhớ dùng `p.tên_cột` hoặc `c.tên_cột` (có chữ cái viết tắt của tên bảng ở trước) để Database không bị bối rối nếu 2 bảng có cột trùng tên nhau.
