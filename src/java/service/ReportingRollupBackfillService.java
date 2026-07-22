package service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import utils.DBUtils;

/**
 * Builds reporting rollups from Product_Ledger in bounded date batches.
 * This class is deliberately not called by a servlet listener: a five-year
 * history must be backfilled in a controlled maintenance operation.
 */
public class ReportingRollupBackfillService {

    private static final String SNAPSHOT_UPSERT =
        "INSERT INTO Inventory_Daily_Snapshots (snapshot_date, warehouse_id, product_id, last_ledger_id, "
      + "new_quantity, used_quantity, damaged_quantity, total_quantity) "
      + "SELECT DATE(pl.created_at), pl.warehouse_id, pl.product_id, pl.id, "
      + "COALESCE(pl.balance_new_quantity, pl.balance_quantity, 0), "
      + "COALESCE(pl.balance_used_quantity, 0), COALESCE(pl.balance_damaged_quantity, 0), "
      + "COALESCE(pl.balance_quantity, COALESCE(pl.balance_new_quantity,0) + COALESCE(pl.balance_used_quantity,0) + COALESCE(pl.balance_damaged_quantity,0)) "
      + "FROM Product_Ledger pl JOIN ( "
      + "  SELECT DATE(created_at) AS snapshot_date, warehouse_id, product_id, MAX(id) AS max_id "
      + "  FROM Product_Ledger WHERE created_at >= ? AND created_at < ? "
      + "  GROUP BY DATE(created_at), warehouse_id, product_id "
      + ") latest ON latest.max_id = pl.id "
      + "ON DUPLICATE KEY UPDATE last_ledger_id=VALUES(last_ledger_id), new_quantity=VALUES(new_quantity), "
      + "used_quantity=VALUES(used_quantity), damaged_quantity=VALUES(damaged_quantity), total_quantity=VALUES(total_quantity)";

    private static final String MOVEMENT_UPSERT =
        "INSERT INTO Inventory_Daily_Movements (movement_date, warehouse_id, product_id, "
      + "import_new, export_new, import_used, export_used, import_damaged, export_damaged, "
      + "adjustment_new, adjustment_used, adjustment_damaged) "
      + "SELECT DATE(created_at), warehouse_id, product_id, "
      + "SUM(CASE WHEN transaction_type IN ('IMPORT','RETURN','TRANSFER_IN','TRANSFER_RETURN') THEN GREATEST(COALESCE(change_new_quantity, change_quantity, 0),0) ELSE 0 END), "
      + "SUM(CASE WHEN transaction_type IN ('EXPORT','TRANSFER_OUT','TRANSFER_RETURN_OUT') THEN GREATEST(-COALESCE(change_new_quantity, change_quantity, 0),0) ELSE 0 END), "
      + "SUM(CASE WHEN transaction_type IN ('IMPORT','RETURN','TRANSFER_IN','TRANSFER_RETURN') THEN GREATEST(COALESCE(change_used_quantity,0),0) ELSE 0 END), "
      + "SUM(CASE WHEN transaction_type IN ('EXPORT','TRANSFER_OUT','TRANSFER_RETURN_OUT') THEN GREATEST(-COALESCE(change_used_quantity,0),0) ELSE 0 END), "
      + "SUM(CASE WHEN transaction_type IN ('IMPORT','RETURN','TRANSFER_IN','TRANSFER_RETURN') THEN GREATEST(COALESCE(change_damaged_quantity,0),0) ELSE 0 END), "
      + "SUM(CASE WHEN transaction_type IN ('EXPORT','TRANSFER_OUT','TRANSFER_RETURN_OUT') THEN GREATEST(-COALESCE(change_damaged_quantity,0),0) ELSE 0 END), "
      + "SUM(CASE WHEN transaction_type='STOCKTAKE' THEN COALESCE(change_new_quantity, change_quantity, 0) ELSE 0 END), "
      + "SUM(CASE WHEN transaction_type='STOCKTAKE' THEN COALESCE(change_used_quantity,0) ELSE 0 END), "
      + "SUM(CASE WHEN transaction_type='STOCKTAKE' THEN COALESCE(change_damaged_quantity,0) ELSE 0 END) "
      + "FROM Product_Ledger WHERE transaction_type <> 'OPENING_BALANCE' AND created_at >= ? AND created_at < ? "
      + "GROUP BY DATE(created_at), warehouse_id, product_id "
      + "ON DUPLICATE KEY UPDATE import_new=VALUES(import_new), export_new=VALUES(export_new), "
      + "import_used=VALUES(import_used), export_used=VALUES(export_used), "
      + "import_damaged=VALUES(import_damaged), export_damaged=VALUES(export_damaged), "
      + "adjustment_new=VALUES(adjustment_new), adjustment_used=VALUES(adjustment_used), adjustment_damaged=VALUES(adjustment_damaged)";

    /**
     * Rebuilds a closed date range. Re-running a batch is idempotent.
     * @return number of successful batches.
     */
    public int backfill(String fromDate, String toDate, int batchDays) throws Exception {
        LocalDate from = LocalDate.parse(fromDate);
        LocalDate to = LocalDate.parse(toDate);
        if (to.isBefore(from)) throw new IllegalArgumentException("toDate must not precede fromDate");
        if (batchDays < 1 || batchDays > 366) throw new IllegalArgumentException("batchDays must be between 1 and 366");

        int batches = 0;
        LocalDate cursor = from;
        while (!cursor.isAfter(to)) {
            LocalDate batchEnd = cursor.plusDays(batchDays - 1L);
            if (batchEnd.isAfter(to)) batchEnd = to;
            backfillBatch(cursor, batchEnd);
            batches++;
            cursor = batchEnd.plusDays(1);
        }
        return batches;
    }

    private void backfillBatch(LocalDate from, LocalDate to) throws Exception {
        LocalDate exclusiveEnd = to.plusDays(1);
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement snapshots = conn.prepareStatement(SNAPSHOT_UPSERT);
                 PreparedStatement movements = conn.prepareStatement(MOVEMENT_UPSERT)) {
                String start = from.toString() + " 00:00:00";
                String end = exclusiveEnd.toString() + " 00:00:00";
                snapshots.setString(1, start);
                snapshots.setString(2, end);
                snapshots.executeUpdate();
                movements.setString(1, start);
                movements.setString(2, end);
                movements.executeUpdate();
            }
            int maxLedgerId = getMaxLedgerId(conn);
            try (PreparedStatement state = conn.prepareStatement(
                    "INSERT INTO Reporting_Rollup_State (rollup_name, coverage_start, last_processed_ledger_id) "
                    + "VALUES ('LEDGER_DAILY', ?, ?) ON DUPLICATE KEY UPDATE "
                    + "coverage_start=LEAST(coverage_start, VALUES(coverage_start)), "
                    + "last_processed_ledger_id=GREATEST(last_processed_ledger_id, VALUES(last_processed_ledger_id))")) {
                state.setString(1, from.toString());
                state.setInt(2, maxLedgerId);
                state.executeUpdate();
            }
            conn.commit();
        }
    }

    /** Command-line entry point: fromDate toDate [batchDays]. */
    public static void main(String[] args) throws Exception {
        if (args.length < 2 || args.length > 3) {
            System.err.println("Usage: ReportingRollupBackfillService yyyy-MM-dd yyyy-MM-dd [batchDays]");
            System.exit(2);
        }
        int batchDays = args.length == 3 ? Integer.parseInt(args[2]) : 31;
        int batches = new ReportingRollupBackfillService().backfill(args[0], args[1], batchDays);
        System.out.println("Reporting rollup backfill completed in " + batches + " batch(es).");
    }

    private int getMaxLedgerId(Connection conn) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement("SELECT COALESCE(MAX(id),0) FROM Product_Ledger");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }
}
