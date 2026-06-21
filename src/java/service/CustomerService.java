package service;

import dao.CustomerDAO;
import java.util.List;
import model.*;

public class CustomerService {
    private CustomerDAO dao;

    public CustomerService() {
        this.dao = new CustomerDAO();
    }

    public Customer getCustomerById(int arg0) {
        return dao.getCustomerById(arg0);
    }

    public boolean addCustomer(Customer arg0) {
        return dao.addCustomer(arg0);
    }

    public List<Customer> getAllCustomers() {
        return dao.getAllCustomers();
    }

    public boolean updateCustomer(Customer arg0) {
        return dao.updateCustomer(arg0);
    }

    public boolean deleteCustomer(int arg0) {
        return dao.deleteCustomer(arg0);
    }

}
