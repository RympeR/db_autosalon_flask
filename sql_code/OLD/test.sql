CREATE DOMAIN Fuel CHAR(13) CHECK(VALUE IN('Бензин', 'Дизель','Газ', 'Электрическая', 'Гибрид'));
CREATE DOMAIN Transmission CHAR(14) CHECK(VALUE IN('Ручная','Автоматическая'));
CREATE DOMAIN Payment CHAR(8) CHECK(VALUE IN('Наличные','Картой','Лизинг'));
CREATE DOMAIN ColorType CHAR(11) CHECK(VALUE IN('Белый', 'Черный', 'Красный', 'Серый', 'Серебристый','Синий', 'Шоколадный', 'Зеленый', 'Желтый'));
CREATE DOMAIN Climat CHAR(13) CHECK(VALUE IN ('Однозонные', 'Двухзонные', 'Трехзонные', 'Четырехзонные'));
CREATE DOMAIN Purchase_Type CHAR(14) CHECK(VALUE IN('По предзаказу', 'Без предзаказа'));

CREATE TABLE Client 
(
	Client_ID SERIAL NOT NULL PRIMARY KEY,
	FirstName VARCHAR NOT NULL,
	FatherName VARCHAR ,
	LastName VARCHAR NOT NULL,
	PhoneNumber CHAR(17) NOT NULL,
	CHECK(PhoneNumber SIMILAR TO '%\+38\((050|063|067|093)\)+[0-9]{3}\-[0-9]{2}\-[0-9]{2}%')
);
CREATE TABLE Sellers
(
	SellerID SERIAL NOT NULL PRIMARY KEY,
	First_Name VARCHAR NOT NULL,
	Father_Name VARCHAR,
	Last_Name VARCHAR NOT NULL,
	Phone_number CHAR(17) NOT NULL,
	Pasport_number CHAR(9) NOT NULL,
	INN CHAR(10) NOT NULL,
	CHECK(INN SIMILAR TO '%[1-9][0-9]{9}%'),
	CHECK(Phone_number SIMILAR TO '%\+38\((050|063|067|093)\)+[0-9]{3}\-[0-9]{2}\-[0-9]{2}%')
);
CREATE TABLE SellersSupplement
(
	Seller_ID INT REFERENCES Sellers ON UPDATE CASCADE ON DELETE CASCADE,
	Fine INT ,
	SupplementAmount INT ,
	SupplementDate DATE
);
CREATE TABLE Purchase
(
	Purchase_ID SERIAL NOT NULL PRIMARY KEY,
	PurchaseType Purchase_Type NOT NULL,
	CareCaseNumber CHAR(17),
	PaymentType Payment NOT NULL,
	PurchaseData DATE NOT NULL,
	PurchasePrice INT NOT NULL,
	Client_ID INT NOT NULL REFERENCES Client,
	SellerID INT REFERENCES Sellers ON UPDATE SET NULL  ON DELETE SET NULL
);
CREATE TABLE BOOKED
(
	BookedCar_ID SERIAL NOT NULL PRIMARY KEY,
	ModelType VARCHAR NOT NULL,
	Color VARCHAR,
	EngineVolume REAL,
	FuelConsumption VARCHAR,
	ReleasData DATE NOT NULL,
	AudioSystem VARCHAR,
	ClimatControl VARCHAR,
	FuelType VARCHAR,
	TransmissionType VARCHAR,
	Purchase_ID INT REFERENCES Purchase ON UPDATE SET NULL ON DELETE SET NULL
);
CREATE TABLE Color
(
	Color_ID SERIAL NOT NULL PRIMARY KEY,
	Colore ColorType NOT NULL
);
CREATE TABLE AudioSystem
(
	AudioSystem_ID SERIAL NOT NULL PRIMARY KEY,
	AudioSystemType VARCHAR NOT NULL 
);
CREATE TABLE ClimatControl
(
	ClimatControl_ID SERIAL NOT NULL PRIMARY KEY,
	ClimatControlType Climat NOT NULL
);
CREATE TABLE FuelType
(
	FuelType_ID SERIAL NOT NULL PRIMARY KEY,
	Fuel_Type Fuel NOT NULL
);
CREATE TABLE TransmissionType
(
	TransmissionType_ID SERIAL NOT NULL PRIMARY KEY,
	Transmission_Type Transmission NOT NULL 
);
CREATE TABLE Specification
(
	Specification_id SERIAL NOT NULL PRIMARY KEY,
	EngineVolume REAL NOT NULL,
	FuelConsumption VARCHAR,
	ReleasData DATE NOT NULL,
	AudioSystem_ID INT NOT NULL REFERENCES AudioSystem,
	ClimatControl_ID INT NOT NULL REFERENCES ClimatControl,
	FuelType_ID INT NOT NULL REFERENCES FuelType,
	TransmissionType_ID INT NOT NULL REFERENCES TransmissionType
);
CREATE TABLE Car
(
	CareCaseNumber CHAR(17) NOT NULL PRIMARY KEY,
	ModelType VARCHAR NOT NULL,
	Price INT NOT NULL,
	Purchase_ID INT REFERENCES Purchase ON UPDATE SET NULL ON DELETE SET NULL,
	Color_ID INT NOT NULL REFERENCES Color,
	Specification_id INT NOT NULL REFERENCES Specification
);

INSERT INTO audiosystem(AudioSystemType) VALUES('JBL CS1214T');
INSERT INTO audiosystem(AudioSystemType) VALUES('MYSTERY MBV-301A');
INSERT INTO audiosystem(AudioSystemType) VALUES('MYSTERY MBB-302A');
INSERT INTO audiosystem(AudioSystemType) VALUES('XDXQ 5013');
INSERT INTO audiosystem(AudioSystemType) VALUES('ALPINE SWE-815');
INSERT INTO audiosystem(AudioSystemType) VALUES('GELONG 10');
INSERT INTO audiosystem(AudioSystemType) VALUES('ICON 10');
INSERT INTO audiosystem(AudioSystemType) VALUES('XDXQ 8013');
INSERT INTO audiosystem(AudioSystemType) VALUES('ALPINE SBE-1044BR');
INSERT INTO audiosystem(AudioSystemType) VALUES('ICON 12');
SELECT * FROM audiosystem;

INSERT INTO ClimatControl(ClimatControlType) VALUES('Однозонные');
INSERT INTO ClimatControl(ClimatControlType) VALUES('Двухзонные');
INSERT INTO ClimatControl(ClimatControlType) VALUES('Трехзонные');
INSERT INTO ClimatControl(ClimatControlType) VALUES('Четырехзонные');
SELECT * FROM ClimatControl;

INSERT INTO FuelType(Fuel_Type) VALUES('Бензин');
INSERT INTO FuelType(Fuel_Type) VALUES('Дизель');
INSERT INTO FuelType(Fuel_Type) VALUES('Газ');
INSERT INTO FuelType(Fuel_Type) VALUES('Электрическая');
INSERT INTO FuelType(Fuel_Type) VALUES('Гибрид');
SELECT * FROM FuelType;

INSERT INTO TransmissionType(Transmission_Type) VALUES('Ручная');
INSERT INTO TransmissionType(Transmission_Type) VALUES('Автоматическая');
SELECT * FROM TransmissionType;

INSERT INTO Color(Colore) VALUES('Белый');
INSERT INTO Color(Colore) VALUES('Черный');
INSERT INTO Color(Colore) VALUES('Красный');
INSERT INTO Color(Colore) VALUES('Серый');
INSERT INTO Color(Colore) VALUES('Серебристый');
INSERT INTO Color(Colore) VALUES('Синий');
INSERT INTO Color(Colore) VALUES('Шоколадный');
INSERT INTO Color(Colore) VALUES('Зеленый');
INSERT INTO Color(Colore) VALUES('Желтый');
SELECT * FROM Color;

INSERT INTO Specification(EngineVolume, FuelConsumption, ReleasData, AudioSystem_ID, ClimatControl_ID, FuelType_ID, TransmissionType_ID) VALUES(1.5, '9', '2019-03-02', 1,2, 1,2);
INSERT INTO Specification(EngineVolume, FuelConsumption, ReleasData, AudioSystem_ID, ClimatControl_ID, FuelType_ID, TransmissionType_ID) VALUES(2, '13', '2018-10-12', 10,1, 2,1);
INSERT INTO Specification(EngineVolume, FuelConsumption, ReleasData, AudioSystem_ID, ClimatControl_ID, FuelType_ID, TransmissionType_ID) VALUES(1.2, '6', '2018-03-05', 2,3, 3,1);
INSERT INTO Specification(EngineVolume, FuelConsumption, ReleasData, AudioSystem_ID, ClimatControl_ID, FuelType_ID, TransmissionType_ID) VALUES(0.5, '5', '2017-11-01', 3,4, 4,2);
INSERT INTO Specification(EngineVolume, FuelConsumption, ReleasData, AudioSystem_ID, ClimatControl_ID, FuelType_ID, TransmissionType_ID) VALUES(1, '7', '2018-04-09', 7,2, 5,1);
INSERT INTO Specification(EngineVolume, FuelConsumption, ReleasData, AudioSystem_ID, ClimatControl_ID, FuelType_ID, TransmissionType_ID) VALUES(1.4, '8', '2019-04-09', 8,4, 4,2);
INSERT INTO Specification(EngineVolume, FuelConsumption, ReleasData, AudioSystem_ID, ClimatControl_ID, FuelType_ID, TransmissionType_ID) VALUES(1.8, '12', '2018-09-08', 9,2, 3,2);
INSERT INTO Specification(EngineVolume, FuelConsumption, ReleasData, AudioSystem_ID, ClimatControl_ID, FuelType_ID, TransmissionType_ID) VALUES(2.3, '16', '2019-03-04', 5,3, 2,1);
INSERT INTO Specification(EngineVolume, FuelConsumption, ReleasData, AudioSystem_ID, ClimatControl_ID, FuelType_ID, TransmissionType_ID) VALUES(1.6, '9', '2018-05-07', 6,4, 1,2);
INSERT INTO Specification(EngineVolume, FuelConsumption, ReleasData, AudioSystem_ID, ClimatControl_ID, FuelType_ID, TransmissionType_ID) VALUES(1.5, '8', '2018-09-03', 4,1, 5,1);
SELECT * FROM Specification;

INSERT INTO Client(FirstName, FatherName, LastName, PhoneNumber) VALUES('Иван', 'Иванович', 'Иванов', '+38(063)152-96-30');
INSERT INTO Client(FirstName, FatherName, LastName, PhoneNumber) VALUES('Петр', 'Петрович', 'Петров', '+38(050)152-96-30');
INSERT INTO Client(FirstName, FatherName, LastName, PhoneNumber) VALUES('Дарья', 'Михайловна', 'Эзерович', '+38(067)152-96-30');
INSERT INTO Client(FirstName, FatherName, LastName, PhoneNumber) VALUES('Максим', 'Максимович', 'Максимов', '+38(093)152-96-30');
INSERT INTO Client(FirstName, FatherName, LastName, PhoneNumber) VALUES('Анна', 'Александровна', 'Цюк', '+38(063)152-90-00');
INSERT INTO Client(FirstName, FatherName, LastName, PhoneNumber) VALUES('Юлия', 'Олеговна', 'Швец', '+38(093)100-96-30');
INSERT INTO Client(FirstName, FatherName, LastName, PhoneNumber) VALUES('Моисей', 'Петрович', 'Иванов', '+38(050)002-16-30');
INSERT INTO Client(FirstName, FatherName, LastName, PhoneNumber) VALUES('Ким', 'Сергеевич', 'Молдавский', '+38(063)102-06-31');
INSERT INTO Client(FirstName, FatherName, LastName, PhoneNumber) VALUES('Виктория', 'Михайловна', 'Гель', '+38(050)052-90-90');
INSERT INTO Client(FirstName, FatherName, LastName, PhoneNumber) VALUES('Александр', 'Сергеевич', 'Штерн', '+38(067)552-86-40');
SELECT * FROM Client;

INSERT INTO Sellers(First_Name, Father_Name, Last_Name, Phone_number, Pasport_number, INN) VALUES('Павел', 'Петрович', 'Серебреник', '+38(063)152-06-00', '002154986', '1023658974');
INSERT INTO Sellers(First_Name, Father_Name, Last_Name, Phone_number, Pasport_number, INN) VALUES('Артур', 'Артурович', 'Король', '+38(067)002-00-00', '000008400', '3364509450');
INSERT INTO Sellers(First_Name, Father_Name, Last_Name, Phone_number, Pasport_number, INN) VALUES('Антон', 'Дмитриевич', 'Кула', '+38(050)952-96-45', '000490045', '3005549861');
INSERT INTO Sellers(First_Name, Father_Name, Last_Name, Phone_number, Pasport_number, INN) VALUES('Маргарита', 'Сергеевна', 'Иванова', '+38(063)984-66-66', '000005549', '2150900987');
INSERT INTO Sellers(First_Name, Father_Name, Last_Name, Phone_number, Pasport_number, INN) VALUES('Юрий', 'Юриевич',' Хан', '+38(063)666-66-66', '000054588', '1123085492');
INSERT INTO Sellers(First_Name, Father_Name, Last_Name, Phone_number, Pasport_number, INN) VALUES('Георгий', 'Александрович', 'Кауфман', '+38(067)777-00-70', 'ВК000011', '6005574684');
INSERT INTO Sellers(First_Name, Father_Name, Last_Name, Phone_number, Pasport_number, INN) VALUES('Олег', 'Олегович', 'Бонд', '+38(093)555-06-30', 'РП004004', '2055468789');
INSERT INTO Sellers(First_Name, Father_Name, Last_Name, Phone_number, Pasport_number, INN) VALUES('Иван', 'Натанович', 'Купитман', '+38(093)111-16-31', 'ПО500886', '7885005898');
INSERT INTO Sellers(First_Name, Father_Name, Last_Name, Phone_number, Pasport_number, INN) VALUES('Андрей', 'Евгеньевич', 'Быков', '+38(050)222-26-30', 'AB005481', '3057800597');
INSERT INTO Sellers(First_Name, Father_Name, Last_Name, Phone_number, Pasport_number, INN) VALUES('Глеб', 'Викторович', 'Романенко', '+38(063)000-00-00', 'PX500978', '2001115468');
SELECT *  FROM Sellers;


INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '01101230990259003', 'Картой', '2019-08-02', 36000, 1, 2);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('Без предзаказа', '01101230991569003', 'Картой', '2019-08-02', 35000, 2, 1);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '01101130991569003', 'Наличные', '2019-09-02', 45000, 3, 3);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('Без предзаказа', '01101231111569003', 'Лизинг', '2019-09-03', 25000, 4, 4);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('Без предзаказа', '01101230991566603', 'Наличные', '2019-10-04', 50000, 5, 8);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '01101230991569088', 'Лизинг', '2019-10-04', 65000, 6, 10);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('Без предзаказа', '01101230991565659', 'Картой', '2019-10-05', 25000, 7, 9);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('Без предзаказа', '01101230990259643', 'Картой', '2019-10-05', 35000, 1, 5);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '01101230991558943', 'Наличные', '2019-10-05', 35000, 8, 6);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '01101230998548543', 'Картой', '2019-11-05', 25000, 9, 5);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '01101230118008540', 'Наличные', '2019-11-05', 25000, 10, 1);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '02601230998008540', 'Лизинг', '2019-11-06', 25000, 2, 2);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '01100030991569003', 'Картой', '2019-11-09', 55000, 3, 3);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '09001230998008540', 'Лизинг', '2019-11-10', 25000, 4, 4);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '08901230998008540', 'Наличные', '2019-11-15', 25000, 10, 1);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '01101230996849040', 'Лизинг', '2019-11-20', 25000, 2, 6);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('Без предзаказа', '01101256111569003', 'Наличные', '2019-11-20', 25000, 3, 7);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('Без предзаказа', '01101230990000003', 'Наличные', '2019-11-20', 25000, 6, 8);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('Без предзаказа', '01101230123123003', 'Наличные', '2019-11-20', 25000, 9, 10);

SELECT * FROM Purchase;

INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230990259643', 'X5', 35000, NULL, 1, 1);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230990259003', 'X6', 36000, 1, 3, 2);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230991569003', 'X1', 35000, 2, 3, 2);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230990000003', 'X1', 35000, NULL, 6, 2);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230123123003', 'X1', 35000, NULL, 4, 2);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01100030991569003', 'GLE', 55000, NULL, 4, 5);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101130991569003', 'A', 45000, 3, 4, 4);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101231111569003', 'B', 25000, 4, 5, 3);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01109631111569003', 'B', 25000, NULL, 1, 3);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101256111569003', 'B', 25000, NULL, 2, 3);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230991566603', 'A7', 50000, 5, 3, 7);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230991569088', 'R8', 65000, 6, 6, 8);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230991565659', 'Octavia', 25000, 7, 9, 6);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230991558943', 'Superb', 35000, NULL, 1, 9);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230998548543', 'Fabia', 25000, NULL, 3, 10);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230998008543', 'Fabia', 26000, NULL, 5, 1);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230118008540', 'Fabia', 25000, NULL, 1, 3);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230968008540', 'Fabia', 25000, NULL, 2, 5);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230996548540', 'Fabia', 25000, NULL, 4, 2);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('01101230996849040', 'Fabia', 25000, NULL, 6, 2);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('02601230998008540', 'Fabia', 25000, NULL, 7, 1);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('08901230998008540', 'Fabia', 25000, NULL, 8, 2);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('09001230998008540', 'Fabia', 25000, NULL, 9, 2);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('21701230998008540', 'Q3', 55000, NULL, 2, 3);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('36001230998008540', 'Q7', 35000, NULL, 4, 5);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('10001230998008540', 'C', 65000, NULL, 5, 4);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('99001230998008540', 'C', 55000, NULL, 3, 4);
INSERT INTO Car(CareCaseNumber, ModelType, Price, Purchase_ID, Color_ID, Specification_id) VALUES('65801230998008540', 'A', 45000, NULL, 1, 2);
SELECT * FROM Car;

UPDATE Car SET Purchase_ID = 8 WHERE CareCaseNumber = '01101230990259643'; 
UPDATE Car SET Purchase_ID = 9 WHERE CareCaseNumber = '01101230991558943';
UPDATE Car SET Purchase_ID = 10 WHERE CareCaseNumber ='01101230998548543';
UPDATE Car SET Purchase_ID = 11 WHERE CareCaseNumber ='01101230118008540';
UPDATE Car SET Purchase_ID = 12 WHERE CareCaseNumber ='02601230998008540';
UPDATE Car SET Purchase_ID = 13 WHERE CareCaseNumber ='01100030991569003';
UPDATE Car SET Purchase_ID = 14 WHERE CareCaseNumber ='09001230998008540';
UPDATE Car SET Purchase_ID = 15 WHERE CareCaseNumber ='08901230998008540';
UPDATE Car SET Purchase_ID = 16 WHERE CareCaseNumber ='01101230996849040';
UPDATE Car SET Purchase_ID = 17 WHERE CareCaseNumber ='01101256111569003';
UPDATE Car SET Purchase_ID = 18 WHERE CareCaseNumber ='01101230990000003';
UPDATE Car SET Purchase_ID = 19 WHERE CareCaseNumber ='01101230123123003';

INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(2, 0, 1000, '2019-08-02');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(1, 0, 1000, '2019-08-02');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(3, 0, 2000, '2019-09-02');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(4, 200, 1000, '2019-09-03');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(8, 0, 3000, '2019-10-04');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(10, 0, 4000, '2019-10-04');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(9, 500, 1000, '2019-10-05');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(5, 0, 1000, '2019-10-05');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(6, 0, 1000, '2019-10-05');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(5, 0, 1500, '2019-11-05');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(1, 0, 1000, '2019-11-05');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(2, 0, 2000, '2019-11-06');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(3, 500, 1000, '2019-11-09');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(4, 0, 1000, '2019-11-10');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(10, 100, 1000, '2019-11-15');
INSERT INTO SellersSupplement(Seller_ID, Fine, SupplementAmount, SupplementDate) VALUES(2, 0, 1000, '2019-11-20');
SELECT * FROM SellersSupplement;
