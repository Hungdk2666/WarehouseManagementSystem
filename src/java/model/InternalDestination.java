package model;

public class InternalDestination {

    private int id;
    private String destinationName;
    private String destinationType;
    private String address;
    private boolean status;

    public InternalDestination() {
    }

    public InternalDestination(int id, String destinationName, String destinationType, String address, boolean status) {
        this.id = id;
        this.destinationName = destinationName;
        this.destinationType = destinationType;
        this.address = address;
        this.status = status;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getDestinationName() {
        return destinationName;
    }

    public void setDestinationName(String destinationName) {
        this.destinationName = destinationName;
    }

    public String getDestinationType() {
        return destinationType;
    }

    public void setDestinationType(String destinationType) {
        this.destinationType = destinationType;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public boolean isStatus() {
        return status;
    }

    public void setStatus(boolean status) {
        this.status = status;
    }
}
