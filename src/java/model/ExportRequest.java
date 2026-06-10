package model;

import java.sql.Date;
import java.sql.Timestamp;
import java.util.List;

public class ExportRequest {
    private int id;
    private String requestCode;
    private int destinationId;
    private String exportReason;
    private int creatorId;
    private String status;
    private Date expectedDate;
    private Timestamp createdAt;
    private Integer approvedBy;
    private Timestamp approvedAt;
    
    private Integer cancelRequestedBy;
    private Timestamp cancelRequestedAt;
    private String cancelReason;
    private Integer cancelledBy;
    private Timestamp cancelledAt;

    // Join fields
    private String destinationName;
    private String creatorFullName;
    private String approvedByFullName;
    private String cancelRequestedByFullName;
    private String cancelledByFullName;

    public ExportRequest() {
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getRequestCode() {
        return requestCode;
    }

    public void setRequestCode(String requestCode) {
        this.requestCode = requestCode;
    }

    public int getDestinationId() {
        return destinationId;
    }

    public void setDestinationId(int destinationId) {
        this.destinationId = destinationId;
    }

    public String getExportReason() {
        return exportReason;
    }

    public void setExportReason(String exportReason) {
        this.exportReason = exportReason;
    }

    public int getCreatorId() {
        return creatorId;
    }

    public void setCreatorId(int creatorId) {
        this.creatorId = creatorId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Date getExpectedDate() {
        return expectedDate;
    }

    public void setExpectedDate(Date expectedDate) {
        this.expectedDate = expectedDate;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public Integer getApprovedBy() {
        return approvedBy;
    }

    public void setApprovedBy(Integer approvedBy) {
        this.approvedBy = approvedBy;
    }

    public Timestamp getApprovedAt() {
        return approvedAt;
    }

    public void setApprovedAt(Timestamp approvedAt) {
        this.approvedAt = approvedAt;
    }

    public Integer getCancelRequestedBy() {
        return cancelRequestedBy;
    }

    public void setCancelRequestedBy(Integer cancelRequestedBy) {
        this.cancelRequestedBy = cancelRequestedBy;
    }

    public Timestamp getCancelRequestedAt() {
        return cancelRequestedAt;
    }

    public void setCancelRequestedAt(Timestamp cancelRequestedAt) {
        this.cancelRequestedAt = cancelRequestedAt;
    }

    public String getCancelReason() {
        return cancelReason;
    }

    public void setCancelReason(String cancelReason) {
        this.cancelReason = cancelReason;
    }

    public Integer getCancelledBy() {
        return cancelledBy;
    }

    public void setCancelledBy(Integer cancelledBy) {
        this.cancelledBy = cancelledBy;
    }

    public Timestamp getCancelledAt() {
        return cancelledAt;
    }

    public void setCancelledAt(Timestamp cancelledAt) {
        this.cancelledAt = cancelledAt;
    }

    public String getDestinationName() {
        return destinationName;
    }

    public void setDestinationName(String destinationName) {
        this.destinationName = destinationName;
    }

    public String getCreatorFullName() {
        return creatorFullName;
    }

    public void setCreatorFullName(String creatorFullName) {
        this.creatorFullName = creatorFullName;
    }

    public String getApprovedByFullName() {
        return approvedByFullName;
    }

    public void setApprovedByFullName(String approvedByFullName) {
        this.approvedByFullName = approvedByFullName;
    }

    public String getCancelRequestedByFullName() {
        return cancelRequestedByFullName;
    }

    public void setCancelRequestedByFullName(String cancelRequestedByFullName) {
        this.cancelRequestedByFullName = cancelRequestedByFullName;
    }

    public String getCancelledByFullName() {
        return cancelledByFullName;
    }

    public void setCancelledByFullName(String cancelledByFullName) {
        this.cancelledByFullName = cancelledByFullName;
    }
}
