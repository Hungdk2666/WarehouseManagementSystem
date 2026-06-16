package model;

import java.sql.Timestamp;
import java.util.List;

public class ExportTicket {
    private int id;
    private String ticketCode;
    private int requestId;
    private int keeperId;
    private String status;
    private Timestamp createdAt;
    private Integer confirmedBy;
    private Timestamp confirmedAt;

    // Join fields
    private String requestCode; // Export Request Code
    private String keeperFullName;
    private String confirmedByFullName;
    private String destinationName;
    private String exportReason;
    private List<ExportTicketDetail> details;

    public ExportTicket() {
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getTicketCode() {
        return ticketCode;
    }

    public void setTicketCode(String ticketCode) {
        this.ticketCode = ticketCode;
    }

    public int getRequestId() {
        return requestId;
    }

    public void setRequestId(int requestId) {
        this.requestId = requestId;
    }

    public int getKeeperId() {
        return keeperId;
    }

    public void setKeeperId(int keeperId) {
        this.keeperId = keeperId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public Integer getConfirmedBy() {
        return confirmedBy;
    }

    public void setConfirmedBy(Integer confirmedBy) {
        this.confirmedBy = confirmedBy;
    }

    public Timestamp getConfirmedAt() {
        return confirmedAt;
    }

    public void setConfirmedAt(Timestamp confirmedAt) {
        this.confirmedAt = confirmedAt;
    }

    public String getRequestCode() {
        return requestCode;
    }

    public void setRequestCode(String requestCode) {
        this.requestCode = requestCode;
    }

    public String getKeeperFullName() {
        return keeperFullName;
    }

    public void setKeeperFullName(String keeperFullName) {
        this.keeperFullName = keeperFullName;
    }

    public String getConfirmedByFullName() {
        return confirmedByFullName;
    }

    public void setConfirmedByFullName(String confirmedByFullName) {
        this.confirmedByFullName = confirmedByFullName;
    }

    public String getDestinationName() {
        return destinationName;
    }

    public void setDestinationName(String destinationName) {
        this.destinationName = destinationName;
    }

    public String getExportReason() {
        return exportReason;
    }

    public void setExportReason(String exportReason) {
        this.exportReason = exportReason;
    }

    public List<ExportTicketDetail> getDetails() {
        return details;
    }

    public void setDetails(List<ExportTicketDetail> details) {
        this.details = details;
    }
}
