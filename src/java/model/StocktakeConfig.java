package model;

import java.math.BigDecimal;
import java.sql.Timestamp;

/**
 * Ngưỡng duyệt 2 cấp kiểm kê — chỉ Business Admin sửa được.
 *
 * Quy tắc: phiếu cần duyệt L2 khi
 *   variancePercent >= thresholdPercent  HOẶC
 *   varianceValue   >= thresholdValue
 */
public class StocktakeConfig {

    private int id;
    private BigDecimal thresholdPercent;
    private BigDecimal thresholdValue;
    private Integer updatedBy;
    private Timestamp updatedAt;

    public StocktakeConfig() {}

    public int getId() { return id; }
    public void setId(int v) { this.id = v; }

    public BigDecimal getThresholdPercent() { return thresholdPercent; }
    public void setThresholdPercent(BigDecimal v) { this.thresholdPercent = v; }

    public BigDecimal getThresholdValue() { return thresholdValue; }
    public void setThresholdValue(BigDecimal v) { this.thresholdValue = v; }

    public Integer getUpdatedBy() { return updatedBy; }
    public void setUpdatedBy(Integer v) { this.updatedBy = v; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp v) { this.updatedAt = v; }
}
