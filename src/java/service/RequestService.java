package service;

import dao.RequestDAO;
import java.util.List;
import java.sql.Connection;
import model.*;

public class RequestService {
    private RequestDAO dao;

    public RequestService() {
        this.dao = new RequestDAO();
    }

    public boolean cancelRequest(int arg0, int arg1) {
        return dao.cancelRequest(arg0, arg1);
    }

    public void setStatus(int arg0, String arg1, Connection arg2) throws Exception {
        dao.setStatus(arg0, arg1, arg2);
    }

    public List<Request> getPendingOrApproved(String arg0, Integer arg1) {
        return dao.getPendingOrApproved(arg0, arg1);
    }

    public List<Request> getPendingOrApproved(String arg0) {
        return dao.getPendingOrApproved(arg0);
    }

    public int createTransferInRequest(Request arg0, int arg1, Connection arg2) throws Exception {
        return dao.createTransferInRequest(arg0, arg1, arg2);
    }

    public List<RequestDetail> getDetailsByRequestId(int arg0, Connection arg1) throws Exception {
        return dao.getDetailsByRequestId(arg0, arg1);
    }

    public String generateUniqueCode(String arg0) {
        return dao.generateUniqueCode(arg0);
    }

    public String generateUniqueCode(String arg0, Connection arg1) throws Exception {
        return dao.generateUniqueCode(arg0, arg1);
    }

    public Request getById(int arg0) {
        return dao.getById(arg0);
    }

    public boolean updateStatus(int arg0, String arg1, int arg2) {
        return dao.updateStatus(arg0, arg1, arg2);
    }

    public boolean requestCancel(int arg0, int arg1, String arg2) {
        return dao.requestCancel(arg0, arg1, arg2);
    }

    public boolean rejectCancel(int arg0) {
        return dao.rejectCancel(arg0);
    }

    public boolean approveCancel(int arg0, int arg1) {
        return dao.approveCancel(arg0, arg1);
    }

    public boolean add(Request arg0, List<RequestDetail> arg1) {
        return dao.add(arg0, arg1);
    }

    public List<Request> getAll(String arg0) {
        return dao.getAll(arg0);
    }

    public List<Request> getAll(String arg0, Integer arg1) {
        return dao.getAll(arg0, arg1);
    }

    public List<Request> getForList(String type, Integer warehouseId, Integer ownStaffId) {
        return dao.getForList(type, warehouseId, ownStaffId);
    }

}
