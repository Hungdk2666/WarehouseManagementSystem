package controller.warehouse;

import service.SupplierService;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Supplier;
import model.User;

@WebServlet(name = "SupplierServlet", urlPatterns = {"/warehouse/supplier"})
public class SupplierServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        // RBAC check: Read actions require SUPPLIER_VIEW
        if (!loggedInUser.hasPermission("SUPPLIER_VIEW")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền xem nhà cung cấp.");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        SupplierService dao = new SupplierService();

        switch (action) {
            case "list":
                List<Supplier> list = dao.getAllSuppliers();
                request.setAttribute("supplierList", list);
                request.getRequestDispatcher("/suppliers/supplier-list.jsp").forward(request, response);
                break;
            case "add":
                if (!loggedInUser.hasPermission("SUPPLIER_ADD")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền thêm nhà cung cấp.");
                    return;
                }
                request.getRequestDispatcher("/suppliers/supplier-add.jsp").forward(request, response);
                break;
            case "update":
                if (!loggedInUser.hasPermission("SUPPLIER_EDIT")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền sửa nhà cung cấp.");
                    return;
                }
                int updateId = Integer.parseInt(request.getParameter("id"));
                Supplier supplier = dao.getSupplierById(updateId);
                if (supplier == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/supplier?action=list");
                    return;
                }
                request.setAttribute("supplier", supplier);
                request.getRequestDispatcher("/suppliers/supplier-update.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/supplier?action=list");
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            response.sendRedirect(request.getContextPath() + "/warehouse/supplier?action=list");
            return;
        }

        // RBAC check: Action-based permissions
        if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("SUPPLIER_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền thêm nhà cung cấp.");
                return;
            }
        } else if ("update".equals(action)) {
            if (!loggedInUser.hasPermission("SUPPLIER_EDIT")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền sửa nhà cung cấp.");
                return;
            }
        } else if ("toggle".equals(action)) {
            if (!loggedInUser.hasPermission("SUPPLIER_TOGGLE")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền bật/tắt nhà cung cấp.");
                return;
            }
        }

        SupplierService dao = new SupplierService();

        try {
            switch (action) {
                case "add":
                    String name = request.getParameter("supplier_name");
                    String contactName = request.getParameter("contact_name");
                    String phone = request.getParameter("phone");
                    String email = request.getParameter("email");
                    String address = request.getParameter("address");
                    boolean status = Boolean.parseBoolean(request.getParameter("status"));
                    
                    Supplier newSupplier = new Supplier();
                    newSupplier.setSupplierName(name);
                    newSupplier.setContactName(contactName);
                    newSupplier.setPhone(phone);
                    newSupplier.setEmail(email);
                    newSupplier.setAddress(address);
                    newSupplier.setStatus(status);
                    
                    dao.addSupplier(newSupplier);
                    break;
                case "update":
                    int id = Integer.parseInt(request.getParameter("id"));
                    String updateName = request.getParameter("supplier_name");
                    String updateContact = request.getParameter("contact_name");
                    String updatePhone = request.getParameter("phone");
                    String updateEmail = request.getParameter("email");
                    String updateAddress = request.getParameter("address");
                    
                    Supplier updateSupplier = new Supplier();
                    updateSupplier.setId(id);
                    updateSupplier.setSupplierName(updateName);
                    updateSupplier.setContactName(updateContact);
                    updateSupplier.setPhone(updatePhone);
                    updateSupplier.setEmail(updateEmail);
                    updateSupplier.setAddress(updateAddress);
                    
                    dao.updateSupplier(updateSupplier);
                    break;
                case "toggle":
                    int toggleId = Integer.parseInt(request.getParameter("id"));
                    dao.toggleSupplierStatus(toggleId);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(request.getContextPath() + "/warehouse/supplier?action=list");
    }
}
