package model;

import java.sql.Timestamp;
import java.util.List;

/**
 * Bảng Tickets gộp — type IN/OUT (denormalize từ Requests).
 * warehouse_id vai trò suy từ type giống Request.
 */
public class Ticket {

    public static final String TYPE_IN  = "IN";
    public static final String TYPE_OUT = "OUT";

    public static final String STATUS_DRAFT      = "DRAFT";
    public static final String STATUS_CONFIRMED  = "CONFIRMED";
    public static final String STATUS_IN_TRANSIT = "IN_TRANSIT";   // chỉ dùng cho OUT-TRANSFER
    public static final String STATUS_COMPLETED  = "COMPLETED";
    public static final String STATUS_CANCELLED  = "CANCELLED";

    public static final String RETURN_NONE    = "NONE";
    public static final String RETURN_PARTIAL = "PARTIAL";
    public static final String RETURN_FULL    = "FULL";

    private int id;
    private String ticketCode;
    private String type;
    private int requestId;
    private int warehouseId;
    private int keeperId;
    private String status;
    private String returnStatus;     // NONE | PARTIAL | FULL — chỉ OUT
    private Timestamp createdAt;
    private Integer confirmedBy;
    private Timestamp confirmedAt;

    // Join fields
    private String warehouseName;
    private String keeperFullName;
    private String confirmedByFullName;
    private String requestCode;               // từ JOIN Requests
    private String requestReason;             // từ JOIN Requests (PURCHASE/RETURN/TRANSFER/...)
    private String requestedCondition;        // từ JOIN Requests
    private String partnerName;               // từ JOIN partner (SUPPLIER/CUSTOMER/...)
    private Request request;                  // request gốc nếu cần
    private Integer linkedInRequestId;
    private String linkedInRequestCode;
    private String linkedInRequestStatus;
    private List<TicketDetail> details;

    public Ticket() {}

    public boolean isIn()  { return TYPE_IN.equals(type); }
    public boolean isOut() { return TYPE_OUT.equals(type); }

    public boolean isTransferReturning() {
        return Request.STATUS_RETURNING.equals(linkedInRequestStatus)
                || Request.STATUS_RETURNED.equals(linkedInRequestStatus)
                || Request.STATUS_CANCELLED.equals(linkedInRequestStatus);
    }


    public boolean isPartiallyReturned() {
        return RETURN_PARTIAL.equals(returnStatus);
    }

    public boolean isFullyReturned() {
        return RETURN_FULL.equals(returnStatus);
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getTicketCode() { return ticketCode; }
    public void setTicketCode(String v) { this.ticketCode = v; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public int getRequestId() { return requestId; }
    public void setRequestId(int requestId) { this.requestId = requestId; }

    public int getWarehouseId() { return warehouseId; }
    public void setWarehouseId(int warehouseId) { this.warehouseId = warehouseId; }

    public int getKeeperId() { return keeperId; }
    public void setKeeperId(int keeperId) { this.keeperId = keeperId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getReturnStatus() { return returnStatus; }
    public void setReturnStatus(String returnStatus) { this.returnStatus = returnStatus; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp v) { this.createdAt = v; }

    public Integer getConfirmedBy() { return confirmedBy; }
    public void setConfirmedBy(Integer v) { this.confirmedBy = v; }

    public Timestamp getConfirmedAt() { return confirmedAt; }
    public void setConfirmedAt(Timestamp v) { this.confirmedAt = v; }

    public String getWarehouseName() { return warehouseName; }
    public void setWarehouseName(String v) { this.warehouseName = v; }

    public String getKeeperFullName() { return keeperFullName; }
    public void setKeeperFullName(String v) { this.keeperFullName = v; }

    public String getConfirmedByFullName() { return confirmedByFullName; }
    public void setConfirmedByFullName(String v) { this.confirmedByFullName = v; }

    public String getRequestCode() { return requestCode; }
    public void setRequestCode(String v) { this.requestCode = v; }

    public String getRequestReason() { return requestReason; }
    public void setRequestReason(String v) { this.requestReason = v; }

    public String getRequestedCondition() { return requestedCondition; }
    public void setRequestedCondition(String v) { this.requestedCondition = v; }

    public String getPartnerName() { return partnerName; }
    public void setPartnerName(String v) { this.partnerName = v; }

    public Integer getLinkedInRequestId() { return linkedInRequestId; }
    public void setLinkedInRequestId(Integer v) { this.linkedInRequestId = v; }

    public String getLinkedInRequestCode() { return linkedInRequestCode; }
    public void setLinkedInRequestCode(String v) { this.linkedInRequestCode = v; }

    public String getLinkedInRequestStatus() { return linkedInRequestStatus; }
    public void setLinkedInRequestStatus(String v) { this.linkedInRequestStatus = v; }


    public Request getRequest() { return request; }
    public void setRequest(Request request) { this.request = request; }

    public List<TicketDetail> getDetails() { return details; }
    public void setDetails(List<TicketDetail> details) { this.details = details; }
}
