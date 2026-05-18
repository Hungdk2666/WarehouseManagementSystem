CREATE DATABASE IF NOT EXISTS wms_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE wms_db;

-- 1. Table Roles
CREATE TABLE Roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    status BOOLEAN DEFAULT TRUE
);

-- 2. Table Permissions
CREATE TABLE Permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    permission_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- 3. Table Role_Permissions (Intermediate table)
CREATE TABLE Role_Permissions (
    role_id INT,
    permission_id INT,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES Roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES Permissions(id) ON DELETE CASCADE
);

-- 4. Table Users
CREATE TABLE Users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- To store SHA-256 hashed password
    email VARCHAR(100),
    full_name VARCHAR(100),
    status BOOLEAN DEFAULT TRUE, -- Active/Deactive
    role_id INT,
    reset_code VARCHAR(10) DEFAULT NULL,
    FOREIGN KEY (role_id) REFERENCES Roles(id) ON DELETE SET NULL
);

-- ========================================================
-- DATA INITIALIZATION
-- ========================================================

-- Insert 2 basic Roles
INSERT INTO Roles (role_name, status) VALUES 
('Admin', TRUE),
('Staff', TRUE);

-- Insert 5 internal Users
-- Note: The original password for all users is '123456'
-- The SHA-256 hash for '123456' is: 8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92
INSERT INTO Users (username, password, email, full_name, status, role_id) VALUES 
('khachung', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'khachung@wms.local', 'Kha Chung', TRUE, (SELECT id FROM Roles WHERE role_name = 'Admin')),
('leduy', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'leduy@wms.local', 'Le Duy', TRUE, (SELECT id FROM Roles WHERE role_name = 'Staff')),
('phuonglinh', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'phuonglinh@wms.local', 'Phuong Linh', TRUE, (SELECT id FROM Roles WHERE role_name = 'Staff')),
('thanhhung', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'thanhhung@wms.local', 'Thanh Hung', TRUE, (SELECT id FROM Roles WHERE role_name = 'Staff')),
('vietanh', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'vietanh@wms.local', 'Viet Anh', TRUE, (SELECT id FROM Roles WHERE role_name = 'Staff'));
