package service;

import dao.TicketDAO;
import java.util.List;
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

    public boolean confirm(int arg0, int arg1) {
        return dao.confirm(arg0, arg1);
    }

    public boolean confirm(int arg0, int arg1, List<String> arg2) {
        return dao.confirm(arg0, arg1, arg2);
    }

    public List<Ticket> getByRequestId(int arg0) {
        return dao.getByRequestId(arg0);
    }

    public boolean add(Ticket arg0, List<TicketDetail> arg1) {
        return dao.add(arg0, arg1);
    }

    public List<Ticket> getAll(String arg0) {
        return dao.getAll(arg0);
    }

    public boolean cancel(int arg0) {
        return dao.cancel(arg0);
    }

}
