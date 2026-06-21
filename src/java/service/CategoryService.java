package service;

import dao.CategoryDAO;
import java.util.List;
import model.*;

public class CategoryService {
    private CategoryDAO dao;

    public CategoryService() {
        this.dao = new CategoryDAO();
    }

    public boolean toggleCategoryStatus(int arg0) {
        return dao.toggleCategoryStatus(arg0);
    }

    public List<Category> getAllCategories() {
        return dao.getAllCategories();
    }

    public Category getCategoryById(int arg0) {
        return dao.getCategoryById(arg0);
    }

    public boolean updateCategory(Category arg0) {
        return dao.updateCategory(arg0);
    }

    public boolean addCategory(Category arg0) {
        return dao.addCategory(arg0);
    }

}
