
package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.InternalDestination;
import utils.DBUtils;

public class InternalDestinationDAO {

    public List<InternalDestination> getAllDestinations() {
        List<InternalDestination> list = new ArrayList<>();
        String query = "SELECT * FROM Internal_Destinations";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new InternalDestination(
                    rs.getInt("id"),
                    rs.getString("destination_name"),
                    rs.getString("destination_type"),
                    rs.getString("address"),
                    rs.getBoolean("status")
                ));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public InternalDestination getDestinationById(int id) {
        String query = "SELECT * FROM Internal_Destinations WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new InternalDestination(
                        rs.getInt("id"),
                        rs.getString("destination_name"),
                        rs.getString("destination_type"),
                        rs.getString("address"),
                        rs.getBoolean("status")
                    );
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean addDestination(InternalDestination dest) {
        String query = "INSERT INTO Internal_Destinations (destination_name, destination_type, address, status) VALUES (?, ?, ?, ?)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, dest.getDestinationName());
            ps.setString(2, dest.getDestinationType());
            ps.setString(3, dest.getAddress());
            ps.setBoolean(4, dest.isStatus());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateDestination(InternalDestination dest) {
        String query = "UPDATE Internal_Destinations SET destination_name = ?, destination_type = ?, address = ? WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, dest.getDestinationName());
            ps.setString(2, dest.getDestinationType());
            ps.setString(3, dest.getAddress());
            ps.setInt(4, dest.getId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean toggleDestinationStatus(int id) {
        String query = "UPDATE Internal_Destinations SET status = NOT status WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
}
