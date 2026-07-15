package model;

import java.sql.Date;
import java.sql.Timestamp;
import java.util.List;

/**
 * Bảng Requests gộp — type IN/OUT.
 * warehouse_id vai trò suy từ type:
 *   IN  → kho nhận hàng | partner = nguồn
 *   OUT → kho xuất hàng | partner = đích
 */
public class Request {

    // Type constants
    public static final String TYPE_IN  = "IN";
    public static final String TYPE_OUT = "OUT";

    // Reason constants
    public static final String REASON_PURCHASE       = "PURCHASE";
    public static final String REASON_RETURN         = "RETURN";
    public static final String REASON_TRANSFER       = "TRANSFER";
    public static final String REASON_DISPLAY        = "DISPLAY";
    public static final String REASON_WARRANTY       = "WARRANTY";
    public static final String REASON_CUSTOMER_SALE  = "CUSTOMER_SALE";

    // PartnerType constants
    public static final String PARTNER_SUPPLIER      = "SUPPLIER";
    public static final String PARTNER_CUSTOMER      = "CUSTOMER";
    public static final String PARTNER_WAREHOUSE     = "WAREHOUSE";
    public static final String PARTNER_INTERNAL_DEST = "INTERNAL_DEST";
    public static final String PARTNER_NONE          = "NONE";

    // Status constants
    public static final String STATUS_PENDING              = "PENDING";
    public static final String STATUS_APPROVED             = "APPROVED";
    public static final String STATUS_PARTIALLY_COMPLETED  = "PARTIALLY_COMPLETED";
    /** Đã xuất một phần chuyển kho, đóng phần còn lại, hàng đã xuất vẫn đang đi. */
    public static final String STATUS_PARTIALLY_IN_TRANSIT = "PARTIALLY_IN_TRANSIT";
    /** Hàng chuyển kho đã xuất đủ ở kho nguồn, chờ kho đích nhận hoặc trả về. */
    public static final String STATUS_IN_TRANSIT           = "IN_TRANSIT";
    public static final String STATUS_COMPLETED            = "COMPLETED";
    /** Đã xử lý một phần và đóng vĩnh viễn phần còn lại. */
    public static final String STATUS_PARTIALLY_CLOSED     = "PARTIALLY_CLOSED";
    /** Hủy nhận/chuyển kho sau khi hàng rời nguồn; hàng đang được trả về. */
    public static final String STATUS_RETURNING            = "RETURNING";
    /** Toàn bộ số hàng thực xuất đã được kho nguồn nhận trả. */
    public static final String STATUS_RETURNED             = "RETURNED";
    public static final String STATUS_REJECTED             = "REJECTED";
    /** Người tạo thu hồi yêu cầu khi yêu cầu vẫn đang chờ duyệt. */
    public static final String STATUS_REVOKED              = "REVOKED";
    public static final String STATUS_CANCELLED            = "CANCELLED";

    private int id;
    private String requestCode;
    private String type;             // IN | OUT
    private String reason;           // PURCHASE | RETURN | TRANSFER | DISPLAY | WARRANTY | CUSTOMER_SALE
    private int warehouseId;
    private String partnerType;      // SUPPLIER | CUSTOMER | WAREHOUSE | INTERNAL_DEST | NONE
    private Integer partnerId;       // NULL khi partnerType = NONE
    private Integer refTicketId;     // RETURN: trỏ Ticket OUT gốc | IN-TRANSFER: trỏ Ticket OUT đối ứng
    private String refTicketCode;    // mã hiển thị của phiếu xuất tham chiếu
    private String returnReason;
    private String shippingAddress;
    private String expectedSerials;
    private Date expectedDate;
    private int staffId;
    private String requestedCondition;
    private String status;
    private Timestamp createdAt;
    private Integer approvedBy;
    private Timestamp approvedAt;

    private Integer cancelRequestedBy;
    private Timestamp cancelRequestedAt;
    private String cancelReason;
    private Integer cancelledBy;
    private Timestamp cancelledAt;

    // Join fields
    private String warehouseName;
    private String partnerName;          // resolved theo partnerType (supplier/customer/warehouse/dest)
    private String staffFullName;
    private String approvedByFullName;
    private String cancelRequestedByFullName;
    private String cancelledByFullName;
    private List<RequestDetail> details;

    public Request() {}

    // ===== Helpers =====
    public boolean isIn()  { return TYPE_IN.equals(type); }
    public boolean isOut() { return TYPE_OUT.equals(type); }

    // ===== Getters/Setters =====
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getRequestCode() { return requestCode; }
    public void setRequestCode(String requestCode) { this.requestCode = requestCode; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public int getWarehouseId() { return warehouseId; }
    public void setWarehouseId(int warehouseId) { this.warehouseId = warehouseId; }

    public String getPartnerType() { return partnerType; }
    public void setPartnerType(String partnerType) { this.partnerType = partnerType; }

    public Integer getPartnerId() { return partnerId; }
    public void setPartnerId(Integer partnerId) { this.partnerId = partnerId; }

    public Integer getRefTicketId() { return refTicketId; }
    public void setRefTicketId(Integer refTicketId) { this.refTicketId = refTicketId; }

    public String getRefTicketCode() { return refTicketCode; }
    public void setRefTicketCode(String refTicketCode) { this.refTicketCode = refTicketCode; }

    public String getReturnReason() { return returnReason; }
    public void setReturnReason(String returnReason) { this.returnReason = returnReason; }

    public String getShippingAddress() { return shippingAddress; }
    public void setShippingAddress(String shippingAddress) { this.shippingAddress = shippingAddress; }

    public String getExpectedSerials() { return expectedSerials; }
    public void setExpectedSerials(String expectedSerials) { this.expectedSerials = expectedSerials; }

    public Date getExpectedDate() { return expectedDate; }
    public void setExpectedDate(Date expectedDate) { this.expectedDate = expectedDate; }

    public int getStaffId() { return staffId; }
    public void setStaffId(int staffId) { this.staffId = staffId; }

    public String getRequestedCondition() { return requestedCondition; }
    public void setRequestedCondition(String v) { this.requestedCondition = v; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public Integer getApprovedBy() { return approvedBy; }
    public void setApprovedBy(Integer approvedBy) { this.approvedBy = approvedBy; }

    public Timestamp getApprovedAt() { return approvedAt; }
    public void setApprovedAt(Timestamp approvedAt) { this.approvedAt = approvedAt; }

    public Integer getCancelRequestedBy() { return cancelRequestedBy; }
    public void setCancelRequestedBy(Integer v) { this.cancelRequestedBy = v; }

    public Timestamp getCancelRequestedAt() { return cancelRequestedAt; }
    public void setCancelRequestedAt(Timestamp v) { this.cancelRequestedAt = v; }

    public String getCancelReason() { return cancelReason; }
    public void setCancelReason(String v) { this.cancelReason = v; }

    public Integer getCancelledBy() { return cancelledBy; }
    public void setCancelledBy(Integer v) { this.cancelledBy = v; }

    public Timestamp getCancelledAt() { return cancelledAt; }
    public void setCancelledAt(Timestamp v) { this.cancelledAt = v; }

    public String getWarehouseName() { return warehouseName; }
    public void setWarehouseName(String v) { this.warehouseName = v; }

    public String getPartnerName() { return partnerName; }
    public void setPartnerName(String v) { this.partnerName = v; }

    public String getStaffFullName() { return staffFullName; }
    public void setStaffFullName(String v) { this.staffFullName = v; }

    public String getApprovedByFullName() { return approvedByFullName; }
    public void setApprovedByFullName(String v) { this.approvedByFullName = v; }

    public String getCancelRequestedByFullName() { return cancelRequestedByFullName; }
    public void setCancelRequestedByFullName(String v) { this.cancelRequestedByFullName = v; }

    public String getCancelledByFullName() { return cancelledByFullName; }
    public void setCancelledByFullName(String v) { this.cancelledByFullName = v; }

    public List<RequestDetail> getDetails() { return details; }
    public void setDetails(List<RequestDetail> details) { this.details = details; }
}
