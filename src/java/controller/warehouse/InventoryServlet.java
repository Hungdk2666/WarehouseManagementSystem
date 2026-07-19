package controller.warehouse;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import model.User;
import service.InventoryService;
import service.WarehouseService;

@WebServlet(name = "InventoryServlet", urlPatterns = { "/warehouse/inventory" })
public class InventoryServlet extends HttpServlet {

    private final InventoryService service = new InventoryService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession();
        User user = (User) session.getAttribute("user");
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }

        if (!user.hasPermission("INVENTORY_VIEW")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xem tồn kho.");
            return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list":   handleList(req, resp, user); break;
            case "detail": handleDetail(req, resp, user); break;
            default:
                resp.sendRedirect(req.getContextPath() + "/warehouse/inventory");
        }
    }

    private void handleList(HttpServletRequest req, HttpServletResponse resp, User user)
            throws ServletException, IOException {
        Integer userWh = user.getWarehouseId();
        Integer filterWh = parseIntegerOrNull(req.getParameter("warehouse_id"));
        boolean canViewAll = user.hasPermission("INVENTORY_VIEW_ALL");
        if (userWh != null && !canViewAll) filterWh = userWh;  // chỉ ép kho nếu không có quyền xem tất cả

        Integer categoryId = parseIntegerOrNull(req.getParameter("category_id"));
        Integer brandId = parseIntegerOrNull(req.getParameter("brand_id"));
        boolean onlyLow = "1".equals(req.getParameter("low_stock"));
        boolean onlyDamaged = "1".equals(req.getParameter("has_damaged"));
        String keyword = req.getParameter("keyword");

        if (filterWh != null) {
            req.setAttribute("rows", service.list(filterWh, categoryId, brandId, onlyLow, onlyDamaged, keyword));
        } else {
            req.setAttribute("groupedRows", service.listGrouped(categoryId, brandId, onlyLow, onlyDamaged, keyword));
        }
        req.setAttribute("kpi", service.getKpi(filterWh));
        req.setAttribute("warehouseList", new WarehouseService().getAllActiveWarehouses());
        req.setAttribute("filterWarehouseId", filterWh);
        req.setAttribute("filterKeyword", keyword);
        req.setAttribute("filterLow", onlyLow);
        req.setAttribute("filterDamaged", onlyDamaged);
        req.setAttribute("userBoundToWarehouse", userWh != null && !canViewAll);

        req.getRequestDispatcher("/inventory/list.jsp").forward(req, resp);
    }

    private void handleDetail(HttpServletRequest req, HttpServletResponse resp, User user)
            throws ServletException, IOException {
        try {
            int warehouseId = Integer.parseInt(req.getParameter("warehouse_id"));
            int productId = Integer.parseInt(req.getParameter("product_id"));

            // Warehouse Staff chỉ xem được kho của mình, trừ khi có INVENTORY_VIEW_ALL
            if (user.getWarehouseId() != null && !user.hasPermission("INVENTORY_VIEW_ALL")
                    && warehouseId != user.getWarehouseId()) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xem tồn kho khác kho của bạn.");
                return;
            }

            req.setAttribute("row", service.getByKey(warehouseId, productId));
            req.setAttribute("serials", service.getSerials(warehouseId, productId));
            req.setAttribute("exportedOrLostSerials", service.getExportedOrLostSerials(warehouseId, productId));
            req.setAttribute("ledger", service.getRecentLedger(warehouseId, productId));

            req.getRequestDispatcher("/inventory/detail.jsp").forward(req, resp);
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/warehouse/inventory");
        }
    }

    private Integer parseIntegerOrNull(String v) {
        if (v == null || v.isEmpty()) return null;
        try { return Integer.parseInt(v); } catch (Exception e) { return null; }
    }
}
