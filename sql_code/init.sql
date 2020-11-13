CREATE USER anonymous WITH PASSWORD '1111';
CREATE USER client WITH PASSWORD 'client';
CREATE USER director WITH PASSWORD 'director';
CREATE USER manager WITH PASSWORD 'manager';
CREATE USER manager WITH PASSWORD 'seller';

GRANT ALL ON TABLE public.users TO anonymous;

CREATE DOMAIN OrderStatus VARCHAR CHECK
    (VALUE IN
     ('New', 'Conform', 'Ready'));
CREATE DOMAIN CarStatus VARCHAR CHECK
    (VALUE IN
     ('New', 'Booked'));

CREATE DOMAIN Roles VARCHAR CHECK
    (VALUE IN
     ('client', 'manager', 'director', 'seller', 'anonymous'));
CREATE DOMAIN Payment CHAR(8) CHECK
	(VALUE IN(
		'Наличные','Картой','Лизинг'));
CREATE DOMAIN Fuel CHAR(13) CHECK
	(VALUE IN(
		'Бензин', 'Дизель','Газ', 'Электрическая', 'Гибрид'));
CREATE DOMAIN Transmission CHAR(14) CHECK
	(VALUE IN(
		'Ручная','Автоматическая'));


-- USERS ##################################
CREATE DOMAIN OrderStatus VARCHAR CHECK
    (VALUE IN
     ('New', 'Conform', 'Ready'));
CREATE DOMAIN CarStatus VARCHAR CHECK
    (VALUE IN
     ('New', 'Booked'));

CREATE DOMAIN Roles VARCHAR CHECK
    (VALUE IN
     ('client', 'manager', 'director', 'seller', 'anonymous'));
CREATE DOMAIN Payment CHAR(8) CHECK
	(VALUE IN(
		'Наличные','Картой','Лизинг'));
CREATE DOMAIN Fuel CHAR(13) CHECK
	(VALUE IN(
		'Бензин', 'Дизель','Газ', 'Электрическая', 'Гибрид'));
CREATE DOMAIN Transmission CHAR(14) CHECK
	(VALUE IN(
		'Ручная','Автоматическая'));


-- USERS ##################################
CREATE TABLE Users
(
    userId   SERIAL PRIMARY KEY,
    login    VARCHAR NOT NULL,
    password VARCHAR NOT NULL,
    email    VARCHAR NOT NULL,
    role     Roles   NOT NULL DEFAULT 'client',
    UNIQUE (login),
    UNIQUE (email)
);

CREATE TABLE Client 
(
	clientId       serial   PRIMARY KEY,
	userId         integer  NOT NULL REFERENCES users (userId) ON DELETE CASCADE ON UPDATE CASCADE,
    firstName      VARCHAR  NOT NULL,
    lastName       VARCHAR  NOT NULL,
    phone          CHAR(13) NOT NULL,
    dateOfBirthday DATE     NOT NULL,
    UNIQUE (phone, userId)
);

CREATE TABLE Employees
(
	employeeId     serial   PRIMARY KEY,
    userId         integer  NOT NULL REFERENCES users (userId) ON DELETE CASCADE ON UPDATE CASCADE,
    FirstName      VARCHAR  NOT NULL,
    LastName       VARCHAR  NOT NULL,
    Phone          CHAR(13) NOT NULL,
    Passport       VARCHAR  NOT NULL,
    Address        VARCHAR  NOT NULL,
    DateOfBirthday DATE     NOT NULL,
    UNIQUE (Passport),
    UNIQUE (Phone)
);

CREATE TABLE Colour
(
	Id SERIAL NOT NULL PRIMARY KEY,
	Title VARCHAR NOT NULL,
	UNIQUE(Title)
);

CREATE TABLE AudioSystem
(
	Id SERIAL NOT NULL PRIMARY KEY,
	Title VARCHAR NOT NULL,
	UNIQUE(Title)
);

CREATE TABLE ClimatControl
(
	Id SERIAL NOT NULL PRIMARY KEY,
	Title VARCHAR NOT NULL,
	UNIQUE(Title)
);

CREATE TABLE FuelType
(
	Id SERIAL NOT NULL PRIMARY KEY,
	Title VARCHAR NOT NULL,
	UNIQUE(Title)
);

CREATE TABLE TransmissionType
(
	Id SERIAL NOT NULL PRIMARY KEY,
	Title VARCHAR NOT NULL,
	UNIQUE(Title) 
);

CREATE TABLE Specification
(
	Id SERIAL NOT NULL PRIMARY KEY,
	EngineVolume REAL NOT NULL,
	FuelConsumption VARCHAR,
	ReleasDate DATE NOT NULL,
	AudioSystem INT NOT NULL REFERENCES AudioSystem (Id),
	ClimatControl INT NOT NULL REFERENCES ClimatControl (Id),
	FuelType INT NOT NULL REFERENCES FuelType(Id),
	TransmissionType INT NOT NULL REFERENCES TransmissionType (Id)
);

CREATE TABLE Purchase
(
	Id SERIAL NOT NULL PRIMARY KEY,
	CareCaseNumber CHAR(17) NOT NULL,
	PaymentType Payment NOT NULL,
	PurchaseData DATE NOT NULL,
	PurchasePrice INT NOT NULL,
	Client INT NOT NULL REFERENCES Client (clientId),
	Employees INT REFERENCES Employees (employeeId) ON UPDATE SET NULL  ON DELETE SET NULL
);

CREATE TABLE Car
(
	CareCaseNumber CHAR(17) NOT NULL PRIMARY KEY,
	CarModel VARCHAR NOT NULL,
	ModelType VARCHAR NOT NULL,
	Price INT NOT NULL,
	Purchase INT REFERENCES Purchase (Id) ON UPDATE SET NULL ON DELETE SET NULL,
	Colour INT NOT NULL REFERENCES Colour (Id),
	Specification INT NOT NULL REFERENCES Specification (Id),
	CarStatus CarStatus NOT NULL
);

CREATE TABLE Order_
(
	Id SERIAL PRIMARY KEY,
	OrderStatus OrderStatus NOT NULL,
	CarModel VARCHAR NOT NULL,
	ModelType VARCHAR NOT NULL,
	Price INT,
	Colour INT NOT NULL REFERENCES Colour (Id),
	Purchase INT REFERENCES Purchase (Id) ON UPDATE SET NULL ON DELETE SET NULL,
	FuelType INT NOT NULL REFERENCES FuelType(Id),
	TransmissionType INT NOT NULL REFERENCES TransmissionType (Id),	
	Client INT NOT NULL REFERENCES Client (clientId),
	Employees INT REFERENCES Employees (employeeId) ON UPDATE SET NULL  ON DELETE SET NULL
);

