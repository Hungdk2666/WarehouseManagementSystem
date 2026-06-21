package service;

import dao.InternalDestinationDAO;
import java.util.List;
import model.*;

public class InternalDestinationService {
    private InternalDestinationDAO dao;

    public InternalDestinationService() {
        this.dao = new InternalDestinationDAO();
    }

    public boolean toggleDestinationStatus(int arg0) {
        return dao.toggleDestinationStatus(arg0);
    }

    public InternalDestination getDestinationById(int arg0) {
        return dao.getDestinationById(arg0);
    }

    public boolean updateDestination(InternalDestination arg0) {
        return dao.updateDestination(arg0);
    }

    public boolean addDestination(InternalDestination arg0) {
        return dao.addDestination(arg0);
    }

    public List<InternalDestination> getAllDestinations() {
        return dao.getAllDestinations();
    }

}
