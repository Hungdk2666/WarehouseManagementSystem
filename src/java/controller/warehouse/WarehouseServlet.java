package controller.warehouse;

import service.WarehouseService;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;
import model.Warehouse;

@WebServlet(name = "WarehouseServlet", urlPatterns = {"/warehouse/warehouse"})
public class WarehouseServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        if (!loggedInUser.hasPermission("WAREHOUSE_VIEW")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        String action = request.getParameter("action");
        if (action == null) action = "list";

        WarehouseService dao = new WarehouseService();

        switch (action) {
            case "list":
                request.setAttribute("warehouseList", dao.getAllWarehouses());
                request.getRequestDispatcher("/warehouse_mgmt/warehouse-list.jsp").forward(request, response);
                break;
            case "add":
                if (!loggedInUser.hasPermission("WAREHOUSE_ADD")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN); return;
                }
                request.getRequestDispatcher("/warehouse_mgmt/warehouse-form.jsp").forward(request, response);
                break;
            case "edit":
                if (!loggedInUser.hasPermission("WAREHOUSE_EDIT")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN); return;
                }
                int editId = Integer.parseInt(request.getParameter("id"));
                Warehouse w = dao.getById(editId);
                if (w == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/warehouse?action=list"); return;
                }
                request.setAttribute("warehouse", w);
                request.setAttribute("staffCount", dao.countStaff(editId));
                request.getRequestDispatcher("/warehouse_mgmt/warehouse-form.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/warehouse?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login"); return;
        }

        String action = request.getParameter("action");
        if (action == null) action = "";

        WarehouseService dao = new WarehouseService();

        switch (action) {
            case "add":
                if (!loggedInUser.hasPermission("WAREHOUSE_ADD")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN); return;
                }
                String name = request.getParameter("warehouse_name");
                String address = request.getParameter("address");
                if (name == null || name.trim().isEmpty()) {
                    request.setAttribute("error", "Tên kho không được để trống.");
                    request.getRequestDispatcher("/warehouse_mgmt/warehouse-form.jsp").forward(request, response);
                    return;
                }
                Warehouse newW = new Warehouse();
                newW.setWarehouseName(name);
                newW.setAddress(address);
                if (!dao.add(newW)) {
                    request.setAttribute("error", "Tên kho đã tồn tại hoặc có lỗi xảy ra.");
                    request.getRequestDispatcher("/warehouse_mgmt/warehouse-form.jsp").forward(request, response);
                    return;
                }
                response.sendRedirect(request.getContextPath() + "/warehouse/warehouse?action=list&success=added");
                break;
            case "edit":
                if (!loggedInUser.hasPermission("WAREHOUSE_EDIT")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN); return;
                }
                int editId = Integer.parseInt(request.getParameter("id"));
                String eName = request.getParameter("warehouse_name");
                String eAddr = request.getParameter("address");
                if (eName == null || eName.trim().isEmpty()) {
                    request.setAttribute("error", "Tên kho không được để trống.");
                    request.setAttribute("warehouse", dao.getById(editId));
                    request.getRequestDispatcher("/warehouse_mgmt/warehouse-form.jsp").forward(request, response);
                    return;
                }
                Warehouse editW = new Warehouse();
                editW.setId(editId);
                editW.setWarehouseName(eName);
                editW.setAddress(eAddr);
                dao.update(editW);
                response.sendRedirect(request.getContextPath() + "/warehouse/warehouse?action=list&success=updated");
                break;
            case "toggle":
                if (!loggedInUser.hasPermission("WAREHOUSE_EDIT")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN); return;
                }
                int toggleId = Integer.parseInt(request.getParameter("id"));
                dao.toggleStatus(toggleId);
                response.sendRedirect(request.getContextPath() + "/warehouse/warehouse?action=list");
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/warehouse?action=list");
        }
    }
}
