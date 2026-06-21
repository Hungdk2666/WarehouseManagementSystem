package service;

import dao.NotificationDAO;
import java.util.List;
import java.sql.Connection;
import model.*;

public class NotificationService {
    private NotificationDAO dao;

    public NotificationService() {
        this.dao = new NotificationDAO();
    }

    public void createNotificationForWarehouse(int arg0, String arg1, String arg2, String arg3, Connection arg4) throws Exception {
        dao.createNotificationForWarehouse(arg0, arg1, arg2, arg3, arg4);
    }

    public int getNotificationsCount(int arg0) {
        return dao.getNotificationsCount(arg0);
    }

    public void createNotificationForRole(int arg0, String arg1, String arg2, String arg3, Connection arg4) throws Exception {
        dao.createNotificationForRole(arg0, arg1, arg2, arg3, arg4);
    }

    public List<Notification> getRecentNotifications(int arg0, int arg1) {
        return dao.getRecentNotifications(arg0, arg1);
    }

    public void createNotification(int arg0, String arg1, String arg2, String arg3, Connection arg4) throws Exception {
        dao.createNotification(arg0, arg1, arg2, arg3, arg4);
    }

    public List<Notification> getNotifications(int arg0, int arg1, int arg2) {
        return dao.getNotifications(arg0, arg1, arg2);
    }

    public int getUnreadCount(int arg0) {
        return dao.getUnreadCount(arg0);
    }

    public boolean markAsRead(int arg0, int arg1) {
        return dao.markAsRead(arg0, arg1);
    }

    public boolean markAllAsRead(int arg0) {
        return dao.markAllAsRead(arg0);
    }

}
