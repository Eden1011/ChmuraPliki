CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL
);

INSERT INTO users (name, email) VALUES
  ('Jan Kowalski', 'jan@example.com'),
  ('Anna Nowak', 'anna@example.com'),
  ('Piotr Wiśniewski', 'piotr@example.com');
