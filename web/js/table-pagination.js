(function (window) {
    "use strict";

    window.initSimpleTablePagination = function (tableId, containerId, selectId) {
        var table = document.getElementById(tableId);
        var container = document.getElementById(containerId);
        var select = document.getElementById(selectId);
        if (!table || !container || !select) return;

        var rows = Array.from(table.querySelectorAll("tbody tr")).filter(function (row) {
            return !row.querySelector(".empty-state");
        });
        var currentPage = 1;
        var pageSize = parseInt(select.value, 10) || 10;

        function render() {
            pageSize = parseInt(select.value, 10) || 10;
            var total = rows.length;
            var totalPages = Math.max(1, Math.ceil(total / pageSize));
            currentPage = Math.min(currentPage, totalPages);
            var start = (currentPage - 1) * pageSize;
            var end = Math.min(start + pageSize, total);

            rows.forEach(function (row, index) {
                row.style.display = index >= start && index < end ? "" : "none";
            });

            container.innerHTML = "";
            var summary = document.createElement("span");
            summary.className = "text-muted small me-auto";
            summary.textContent = total === 0 ? "0 dòng" : "Hiển thị " + (start + 1) + "–" + end + " / " + total;
            container.appendChild(summary);
            if (totalPages <= 1) return;

            var nav = document.createElement("ul");
            nav.className = "pagination pagination-sm m-0 gap-1";

            function addButton(label, disabled, active, callback, aria) {
                var li = document.createElement("li");
                li.className = "page-item" + (disabled ? " disabled" : "") + (active ? " active" : "");
                var button = document.createElement("button");
                button.type = "button";
                button.className = "page-link border-0 rounded-2 shadow-none px-3 py-1";
                button.innerHTML = label;
                if (aria) button.setAttribute("aria-label", aria);
                button.disabled = disabled;
                if (!disabled) button.addEventListener("click", callback);
                li.appendChild(button);
                nav.appendChild(li);
            }

            addButton("<i class='bi bi-chevron-left'></i>", currentPage === 1, false, function () {
                currentPage--; render();
            }, "Trang trước");

            var first = Math.max(1, currentPage - 2);
            var last = Math.min(totalPages, first + 4);
            first = Math.max(1, last - 4);
            for (var page = first; page <= last; page++) {
                (function (target) {
                    addButton(String(target), false, target === currentPage, function () {
                        currentPage = target; render();
                    });
                })(page);
            }

            addButton("<i class='bi bi-chevron-right'></i>", currentPage === totalPages, false, function () {
                currentPage++; render();
            }, "Trang sau");
            container.appendChild(nav);
        }

        select.addEventListener("change", function () { currentPage = 1; render(); });
        render();
    };
})(window);
