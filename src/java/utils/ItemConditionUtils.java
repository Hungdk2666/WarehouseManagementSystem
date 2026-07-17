package utils;

import model.Request;

/** Shared item-condition rules for inventory and outbound flows. */
public final class ItemConditionUtils {
    public static final String NEW = "NEW";
    public static final String USED = "USED";
    public static final String DAMAGED = "DAMAGED";

    private ItemConditionUtils() {
    }

    public static boolean isValid(String condition) {
        return NEW.equals(condition) || USED.equals(condition) || DAMAGED.equals(condition);
    }

    public static String label(String condition) {
        if (USED.equals(condition)) return "H\u00e0ng c\u0169";
        if (DAMAGED.equals(condition)) return "H\u00e0ng h\u1ecfng";
        if (NEW.equals(condition)) return "H\u00e0ng m\u1edbi";
        return condition == null ? "" : condition;
    }

    /**
     * Hàng hỏng chỉ được xuất cho bảo hành, chuyển kho nội bộ, hoặc bán cho khách
     * (thanh lý hàng hỏng thực chất cũng là một hình thức bán cho khách).
     */
    public static boolean isAllowedForExportReason(String reason, String condition) {
        if (!isValid(condition)) return false;
        if (Request.REASON_WARRANTY.equals(reason)) return DAMAGED.equals(condition);
        if (Request.REASON_TRANSFER.equals(reason)) return true;
        if (Request.REASON_CUSTOMER_SALE.equals(reason)) return true;
        if (Request.REASON_DISPLAY.equals(reason)) {
            return NEW.equals(condition) || USED.equals(condition);
        }
        return false;
    }
}