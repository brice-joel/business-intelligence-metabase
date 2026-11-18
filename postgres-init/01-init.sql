-- Création de l'utilisateur et de la base interne pour Metabase
CREATE USER admin WITH PASSWORD 'admin';
CREATE DATABASE metabase_app OWNER admin;

-- Création d'une base dédiée au Data Warehouse pour l'entraînement BI
CREATE DATABASE dwh OWNER admin;
