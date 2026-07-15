package service;

import dao.TicketDAO;
import java.util.List;
import java.util.Map;
import java.sql.Connection;
import model.*;

public class TicketService {
    private TicketDAO dao;

    public TicketService() {
        this.dao = new TicketDAO();
    }

    public List<TicketDetail> getDetailsByTicketId(int arg0) {
        return dao.getDetailsByTicketId(arg0);
    }

    public List<TicketDetail> getDetailsByTicketId(int arg0, Connection arg1) throws Exception {
        return dao.getDetailsByTicketId(arg0, arg1);
    }

    public List<Ticket> getIncomingTransfersForWarehouse(int arg0) {
        return dao.getIncomingTransfersForWarehouse(arg0);
    }

    public List<Ticket> getDispatchedOutTickets() {
        return dao.getDispatchedOutTickets();
    }

    public String generateUniqueCode(String arg0, Connection arg1) throws Exception {
        return dao.generateUniqueCode(arg0, arg1);
    }

    public Ticket getById(int arg0) {
        return dao.getById(arg0);
    }

    public List<Ticket> getByRequestId(int arg0) {
        return dao.getByRequestId(arg0);
    }

    /** Gộp 1 màn hình: tạo phiếu + xác nhận trong 1 giao dịch (không để lại phiếu nháp). */
    public boolean addAndConfirm(Ticket ticket, List<TicketDetail> details, List<String> serials,
            int confirmedBy, Map<Integer, List<String>> manufacturerSerialsByProductId) {
        return dao.addAndConfirm(ticket, details, serials, confirmedBy, manufacturerSerialsByProductId);
    }

    public String getLastErrorCode() {
        return dao.getLastErrorCode();
    }

    public List<Ticket> getAll(String arg0) {
        return dao.getAll(arg0);
    }

}
