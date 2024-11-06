CREATE DATABASE store;
USE store;

CREATE TABLE products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50),
    Price INT NOT NULL,
    StockQuantity INT
);

INSERT INTO products VALUES (101, 'Laptop', 50000, 20);
INSERT INTO products VALUES (102, 'SmartPhone', 10000, 50);

CREATE TABLE customers (
  CustomerID INT PRIMARY KEY,
  FirstName VARCHAR(60),
  LastName VARCHAR(60),
  Email VARCHAR(60) UNIQUE,
  Address VARCHAR(100)
);

INSERT INTO customers VALUES (1011, 'Asif', 'Hassan', 'asif@gmail.com', 'Tilagorh, Sylhet');
INSERT INTO customers VALUES (1012, 'Arifur', 'Rahman', 'arif@gmail.com', 'Kumargaon, Sylhet');

CREATE TABLE orders (
  OrderID INT PRIMARY KEY,
  CustomerID INT,
  ProductID INT,
  OrderDate DATE,
  TotalAmount INT,
  FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID),
  FOREIGN KEY (ProductID) REFERENCES products(ProductID)
);

INSERT INTO orders VALUES (10001, 1011, 101, '2024-2-17', 80000);
INSERT INTO orders VALUES (10002, 1012, 102, '2020-3-10', 70000);