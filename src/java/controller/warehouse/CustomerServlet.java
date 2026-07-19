package controller.warehouse;

import service.CustomerService;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Customer;
import model.User;

@WebServlet(name = "CustomerServlet", urlPatterns = {"/warehouse/customer"})
public class CustomerServlet extends HttpServlet {

    private final CustomerService dao = new CustomerService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) action = "list";

        if (!loggedInUser.hasPermission("CUSTOMER_VIEW")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền truy cập.");
            return;
        }

        switch (action) {
            case "list":
                List<Customer> list = dao.getAllCustomers();
                request.setAttribute("customerList", list);
                request.getRequestDispatcher("/customer/customer-list.jsp").forward(request, response);
                break;
            case "detail":
                try {
                    int id = Integer.parseInt(request.getParameter("id"));
                    Customer c = dao.getCustomerById(id);
                    if (c == null) {
                        response.sendRedirect(request.getContextPath() + "/warehouse/customer?action=list");
                        return;
                    }
                    request.setAttribute("customer", c);
                    request.getRequestDispatcher("/customer/customer-detail.jsp").forward(request, response);
                } catch (NumberFormatException e) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/customer?action=list");
                }
                break;
            case "add":
                if (!loggedInUser.hasPermission("CUSTOMER_ADD")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền thêm khách hàng.");
                    return;
                }
                request.getRequestDispatcher("/customer/customer-add.jsp").forward(request, response);
                break;
            case "edit":
                if (!loggedInUser.hasPermission("CUSTOMER_EDIT")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền chỉnh sửa khách hàng.");
                    return;
                }
                try {
                    int id = Integer.parseInt(request.getParameter("id"));
                    Customer c = dao.getCustomerById(id);
                    if (c == null) {
                        response.sendRedirect(request.getContextPath() + "/warehouse/customer?action=list");
                        return;
                    }
                    request.setAttribute("customer", c);
                    request.getRequestDispatcher("/customer/customer-add.jsp").forward(request, response);
                } catch (NumberFormatException e) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/customer?action=list");
                }
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/customer?action=list");
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
        if (action == null) action = "";

        switch (action) {
            case "add":
                if (!loggedInUser.hasPermission("CUSTOMER_ADD")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN);
                    return;
                }
                try {
                    String name = request.getParameter("customer_name");
                    if (name == null || name.trim().isEmpty()) {
                        request.setAttribute("error", "Tên khách hàng không được để trống.");
                        request.getRequestDispatcher("/customer/customer-add.jsp").forward(request, response);
                        return;
                    }
                    Customer c = new Customer();
                    c.setCustomerName(name.trim());
                    c.setPhone(request.getParameter("phone"));
                    c.setEmail(request.getParameter("email"));
                    c.setAddress(request.getParameter("address"));
                    c.setExternalRef(request.getParameter("external_ref"));
                    dao.addCustomer(c);
                    response.sendRedirect(request.getContextPath() + "/warehouse/customer?action=list");
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("error", "Có lỗi xảy ra: " + e.getMessage());
                    request.getRequestDispatcher("/customer/customer-add.jsp").forward(request, response);
                }
                break;
            case "edit":
                if (!loggedInUser.hasPermission("CUSTOMER_EDIT")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN);
                    return;
                }
                try {
                    int id = Integer.parseInt(request.getParameter("id"));
                    String name = request.getParameter("customer_name");
                    if (name == null || name.trim().isEmpty()) {
                        request.setAttribute("error", "Tên khách hàng không được để trống.");
                        Customer existing = dao.getCustomerById(id);
                        request.setAttribute("customer", existing);
                        request.getRequestDispatcher("/customer/customer-add.jsp").forward(request, response);
                        return;
                    }
                    Customer c = new Customer();
                    c.setId(id);
                    c.setCustomerName(name.trim());
                    c.setPhone(request.getParameter("phone"));
                    c.setEmail(request.getParameter("email"));
                    c.setAddress(request.getParameter("address"));
                    c.setExternalRef(request.getParameter("external_ref"));
                    dao.updateCustomer(c);
                    response.sendRedirect(request.getContextPath() + "/warehouse/customer?action=detail&id=" + id);
                } catch (Exception e) {
                    e.printStackTrace();
                    response.sendRedirect(request.getContextPath() + "/warehouse/customer?action=list");
                }
                break;
            case "toggle":
                if (!loggedInUser.hasPermission("CUSTOMER_DELETE")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN);
                    return;
                }
                try {
                    int id = Integer.parseInt(request.getParameter("id"));
                    dao.toggleCustomerStatus(id);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                response.sendRedirect(request.getContextPath() + "/warehouse/customer?action=list");
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/customer?action=list");
        }
    }
}
