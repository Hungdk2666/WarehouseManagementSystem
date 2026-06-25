<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%-- Hiển thị banner khi action bị chặn do kho đang kiểm kê.
     Include vào các trang list của Request/Ticket. --%>
<%
    String __err = request.getParameter("error");
    String __stk = request.getParameter("stk");
    if ("WarehouseFrozen".equals(__err)) {
%>
    <div class="alert alert-warning alert-dismissible fade show shadow-sm" role="alert">
        <i class="bi bi-exclamation-triangle-fill me-2"></i>
        <strong>Kho đang trong kỳ kiểm kê</strong> <%= __stk != null ? "(" + __stk + ")" : "" %> —
        không được tạo phiếu hoặc xác nhận phiếu nhập/xuất cho tới khi kiểm kê hoàn tất.
        <a href="<%= request.getContextPath() %>/warehouse/stocktake" class="alert-link">Xem phiếu kiểm kê</a>.
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
<%
    }
%>
