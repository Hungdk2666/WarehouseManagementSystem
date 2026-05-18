package model;

public class Role {
    private int id;
    private String roleName;
    private boolean status;

    public Role() {
    }

    public Role(int id, String roleName, boolean status) {
        this.id = id;
        this.roleName = roleName;
        this.status = status;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getRoleName() { return roleName; }
    public void setRoleName(String roleName) { this.roleName = roleName; }

    public boolean isStatus() { return status; }
    public void setStatus(boolean status) { this.status = status; }
}
