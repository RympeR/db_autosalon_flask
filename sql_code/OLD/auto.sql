/*л/р № 4 (подзапросы, представления и оконные функции)*/
/*представление - виртуальная поименованная производная таблица
(Функция DENSE_RANK() возвращает позицию каждой строки в секции результирующего набора без промежутков в ранжировании, которая вычисляется как количество разных значений рангов, 
предшествующих строке, увеличенное на единицу, при этом ранг увеличивается при каждом изменении значений выражений, входящих в конструкцию ORDER BY, а строки с одинаковыми значениями получают тот же ранг. )
(USING — сокращённая нотация ON: она содержит список разделённых запятыми имён столбцов, которые в соединяемых таблицах должны быть одинаковыми, 
и формирует условие соединения путём сравнения каждой из этих пар столбцов. Кроме того, результатом JOIN USING будет один столбец для каждой из сравниваемых пар входных столбцов плюс все остальные столбцы каждой таблицы)
Аналитические функции имеют следующий синтаксис: имя_функции (аргумент, аргумент, …) OVER (описание_среза_данных) 
(Аналитические функции имеют следующий синтаксис: имя_функции (аргумент, аргумент, …) OVER (описание_среза_данных) )
Оператор WITH позволяет более эффективно использовать в подзапросах оконные функции
CREATE OR REPLACE VIEW чтобы не надо было постоянно удалять функцию
*/

--Получить список моделей автомобилей с наименьшей ценой среди моделей с таким же типом топлива.
/*Создаем локальное представление (что позволяет разбить сложный запрос на множество подзапросов в удобной для восприятия человеком форме)
в котором в проекции на таблицу авто выполняем ранжирование в разбиении по типам топлива и с сортировкой по цене авто 
для получения данных о типе топлива, хранящихся в спецификации, проводим их соединение 
и в конце проводим выборку из локального предстваления марки авто и типа топлива с первым рангом 

*/
WITH Car_fuel_rank AS
(
  SELECT DISTINCT c.carModel, c.price, sc.fuelType_id, DENSE_RANK() OVER(PARTITION BY sc.fuelType_id ORDER BY c.price ) "rank"
  FROM Car c
  INNER JOIN Specification sc USING (specification_id)
  ORDER BY 4 
)


SELECT fuelType_id, carModel
FROM Car_fuel_rank
WHERE "rank" = 1 
ORDER BY 1 


SELECT CarModel FROM Car C
WHERE  EXISTS (
SELECT DISTINCT c.carModel, c.price, sc.fuelType_id, DENSE_RANK() OVER(PARTITION BY sc.fuelType_id ORDER BY c.price ) "rank"
  FROM Car c
  INNER JOIN Specification sc USING (specification_id)
  ORDER BY 4 
)
ормации сотрудниках с указанием их ранга (мест) по: 
--– количеству продаж; – сумме продаж за прошедшее относительно даты запроса полугодие.
--зачем ""
/*
Создаем представление, в котором создаем 2 локальных представления. 
1 представление проводит соединение таблиц продавцов и покупок с подсчетом количества продаж у продавцов
2 представление проводит соединение таблиц продавцов и покупок с выборкой по дате продажи (за последние пол года) с подсчетом суммы продаж каждого продавца в этот период
далее проводим их декартово произведение и выборку по одинаковы продавцам сортируя их по продажам и проведя ранжирование  и сортируя их по суммам продаж и проведя ранжирование 
*/
CREATE OR REPLACE VIEW Sellers_info AS
(
  WITH PurchCount AS
  (
    SELECT s.sellerId, COUNT(pn.purchase_id) "количество продаж"
    FROM Sellers s
    INNER JOIN Purchase pn USING (sellerid)
    GROUP BY 1 
    ORDER BY 2 DESC
  ),
  PurchSum AS
  (
    SELECT s.sellerId, SUM(pn1.purchaseprice) "сумма продаж"
    FROM Sellers s
    INNER JOIN Purchase pn1 USING (sellerid)
    WHERE pn1.purchasedata BETWEEN CURRENT_DATE -interval '6 month' AND CURRENT_DATE
    GROUP BY 1
    ORDER BY 2 DESC
  )
  
  SELECT pc.sellerId, DENSE_RANK() OVER(ORDER BY "количество продаж" desc) "количество продаж",
            DENSE_RANK() OVER(ORDER BY "сумма продаж" desc) "сумма продаж"
  FROM PurchCount pc, PurchSum ps
  WHERE pc.sellerId = ps.sellerId
);

SELECT *
FROM Sellers_info

--Снизить цену на самые старые автомобили каждой модели на 10%.
/*
Создаем локальное представление старых авто (производим соединение авто и спецификации), в котором выбираем машины с датой выпуска меньше текущего года с ранжирование по дате выпуска
разбиения по моделям авто; представление, в котором проводим выборку авто с рангом 1 (то есть самых старых)
Выполняем обновление цены в таблице авто среди тех авто, номера которых есть в представлении самых старых авто
*/

WITH OldestCar AS
(  
  SELECT c.carecasenumber,c.price, sc.releasdata, DENSE_RANK() OVER(PARTITION BY c.modelType ORDER BY sc.releasdata) "rank"
  FROM Car c
  INNER JOIN Specification sc USING(specification_id)
  WHERE date_part('year',sc.releasdata) < date_part('year', CURRENT_DATE) AND c.purchase_id IS NULL
  
),
  topCar AS(
  SELECT carecasenumber,price "carPrice", "rank"
  FROM OldestCar
  WHERE "rank" =1
)
 select *
 FROM topCar

UPDATE Car c
  SET
    price = price - price*0.1
  FROM topCar tc
  WHERE tc.carecasenumber = c.carecasenumber

/*л/р № 5 (триггеры, хранимые процедуры и агрегатные функции)*/
/*хранимая тоже что фукция в постгрес ибо раньше не было хранимок, а только функции. Обязательно возвращает значения указать тип или войд, если таблицу пишем квери селект
Хранимой процедурой называется программа произвольной длины, написанная на языке SQL и его расширениях, которая хранится в БД как её объект подобно таблицам представлениям и т.п. 
Хранимые процедуры позволяют сократить количество сообщений или транзакций между клиентом и сервером.
триггер возвращает строку, но типа триггер  
IF(условие) THEN составной_оператор [ELSE составной_оператор] 
агрегатные функции, которые возвращают некоторое единственное значение, подсчитанное по значениям конкретного поля в подмножестве кортежей таблицы. 
KOD 
*/
--Создать хранимую процедуру, реализующую факт продажи экземпляра (без его предварительной идентификации) модели автомобиля в соответствии с конфигурацией клиента. Все необходимые данные передавать как параметры.

/*
создаем выполняемую процедуру, которая принимает параметры типа покупки, марки, модели, цвета авто, 
типа оплаты фамилию и телефон покупателя и айди продавца(будет выставляться по умолчанию)
в теле создаются локальные переменные для айди покупки машини и клиента, 
создается представление (соединение авто цветов и клиентов), в котором проходит выборка на соответствие марки и модели авто и проверка на то, что авто не продано
далее айди авто и клиента из представления помещаются в локальные переменные и проходит проверка, если car_id пуст, то выдается ошибка
а далее добавляем покупку исходя из введеных данных и обновляем айди покупки у соответствующего авто  в машинах 
*/
CREATE OR REPLACE FUNCTION addpurchase(
  purchasetype purchase_type,
  car_model character varying,
  model_type character varying,
  color colortype,
  payment_type payment,
  last_name character varying,
  phone_number character,
  seller_id integer)
    RETURNS void 
AS $$
  DECLARE purch_id int;
      car_id char(17);
      client_id INT;
  BEGIN
    WITH newPurchase AS
    (
      SELECT c.carecasenumber, c.price, cl.client_id
      FROM Car c
      INNER JOIN Color col ON col.colore = color
      INNER JOIN Client cl ON cl.lastname = last_name AND cl.phonenumber = phone_number  
      WHERE c.purchase_id IS NULL AND c.carmodel = car_model AND c.modeltype = model_type
          AND c.color_id = col.color_id
    )
    SELECT carecasenumber, np.client_id INTO car_id, client_id
    FROM newPurchase np;
    
    IF(car_id IS NULL)
    THEN 
      raise exception 'No such car I am soryy:c';
    END IF;
    
    INSERT INTO Purchase (purchasetype, carecasenumber, paymenttype, purchasedata, purchaseprice, client_id, sellerid)
    SELECT purchasetype, car_id, payment_Type, CURRENT_DATE, c.price, client_id, seller_id
    FROM Car c
    WHERE c.carecasenumber = car_id;    
    
    SELECT purchase_id INTO purch_id
    FROM Purchase
    WHERE carecasenumber = car_id;
    
    UPDATE Car c
      SET 
        purchase_id = purch_id
      WHERE car_id = c.carecasenumber;
  END;
$$  LANGUAGE plpgsql; 
select addpurchase('По предзаказу', 'Skoda', 'Fabia', 'Серый', 'Лизинг', 'Петров', '+38(050)152-96-30', 1)
--Создать триггер, блокирующий продажу автомобиля, если все экземпляры его модели проданы
/*
	создаем функцию, у которой возвращаемое значение будет иметь тип триггер.
	в теле функции проверяем наличие введеного в покупке номера авто на наличие его в таблице авто и то что такое авто еще не куплено возвращаем последнюю добавленную строку

	создаем триггер, срабатывающий до добавления покупки выполнение хранимой процедуры на текущую строку 

	затем создаем функцию, у которой возвращаемое значение будет иметь тип триггер.
	в теле функции проводим обнавление айди покупки у соответствующего авто и создаем триггер, которорый запустит обнавление при добавлении новой поккупки
*/

CREATE OR REPLACE FUNCTION AddPurchaseFunc()
          RETURNS TRIGGER
AS $$
  DECLARE tmp int;
BEGIN
  IF ((
    SELECT c.carecasenumber
    FROM Car c
    WHERE c.carecasenumber = new.carecasenumber AND c.purchase_id IS NULL) IS NULL)
    THEN RAISE EXCEPTION 'Машина продана либо некорректный номер.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;
CREATE TRIGGER AddPurchase
BEFORE INSERT ON Purchase
FOR EACH ROW 
EXECUTE PROCEDURE AddPurchaseFunc();

CREATE OR REPLACE FUNCTION AddCarPurchaseFunc()
          RETURNS TRIGGER
AS $$
BEGIN
  UPDATE Car
  SET purchase_id = new.purchase_id
  WHERE Car.carecasenumber = new.carecasenumber;  
  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER AddCarPurchase
AFTER INSERT ON Purchase
FOR EACH ROW 
EXECUTE PROCEDURE AddCarPurchaseFunc();

INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '09001230998008540', 'Лизинг', '2019-11-10', 25000, 4, 4);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('По предзаказу', '11111230998008540', 'Лизинг', '2019-11-10', 25000, 4, 4);
INSERT INTO Purchase(PurchaseType, CareCaseNumber, PaymentType, PurchaseData, PurchasePrice, Client_ID, SellerID) VALUES('Без предзаказа', '01109631111569003', 'Лизинг', '2018-03-05', 25000, 4, 4);

--Создать агрегатную функцию, подсчитывающую среднюю стоимость автомобилей каждой модели.
/*
создаем структуру из суммы и количества численного типа
далее создаем функцию которая принимает входные параметры типов пользовательского и варчар, задаем тип возвращаемого значения ,объявляем локальные переменные
подсчитываем сумму и количество авто и помещаем в переменные типа структуры из таблицы авто по конкретной модели и возвращаем результат используя приведение типов к агригатстате
создаем функцию для подсчета средней стоимости и принимаемым значениекм типа структуры, а возвращающей численный тип

и создаем агргатную функцию, принимающую значения типа варчар, в которой вызываем функцию состояния AvgModelPriceFunc, тип данных состояния функцкию завершения AvgModelPriceFinalFunc
и начальное условие
*/
/*
Имя функции перехода состояния, вызываемой для каждой входной строки. Тип данных значения состояния для агрегатной функции. 
Имя функции завершения, вызываемой для вычисления результата агрегатной функции после обработки всех входных строк. Начальное значение переменной состояния. 
*/
CREATE TYPE aggregateState AS
(  
  sum   NUMERIC,
  count NUMERIC
);

CREATE OR REPLACE FUNCTION AvgModelPriceFunc(stat aggregateState, model varchar)
    RETURNS aggregateState
AS $$
  DECLARE sum int;
      count int;
BEGIN 
  SELECT SUM(price), COUNT(carecasenumber) INTO stat.sum, stat.count
  FROM Car
  WHERE modeltype = model;
  
  RETURN (stat.sum,stat.count)::aggregateState;
END;
$$ LANGUAGE plpgSQL;

CREATE OR REPLACE FUNCTION AvgModelPriceFinalFunc(stat aggregateState)
  RETURNS NUMERIC
AS $$
BEGIN  
  RETURN stat.sum/stat.count;
END;
$$ LANGUAGE plpgSQl;


CREATE  AGGREGATE AvgModelPrice(varchar)
(
  sfunc= AvgModelPriceFunc,
  stype = aggregateState,
  finalfunc = AvgModelPriceFinalFunc,
  initcond = '(0,0)'
);

SELECT ModelType, AvgModelPrice(ModelType) FROM CAR GROUP BY 1;







\



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
	CareCaseNumber CHAR(17) NOT NULL,
	PaymentType Payment NOT NULL,
	PurchaseData DATE NOT NULL,
	PurchasePrice INT NOT NULL,
	Client_ID INT NOT NULL REFERENCES Client,
	SellerID INT REFERENCES Sellers ON UPDATE SET NULL  ON DELETE SET NULL
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
	CarModel VARCHAR NOT NULL,
	ModelType VARCHAR NOT NULL,
	Price INT NOT NULL,
	Purchase_ID INT REFERENCES Purchase ON UPDATE SET NULL ON DELETE SET NULL,
	Color_ID INT NOT NULL REFERENCES Color,
	Specification_id INT NOT NULL REFERENCES Specification,
	Maker VARCHAR NOT NULL
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

INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230990259643', 'BMW', 'X5', 35000, NULL, 1, 1, 'BMW GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230990259003', 'BMW', 'X6', 36000, 1, 3, 2, 'BMW GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230991569003', 'BMW', 'X1', 35000, 2, 3, 2, 'BMW GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230990000003', 'BMW', 'X1', 35000, NULL, 6, 2, 'BMW GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230123123003', 'BMW', 'X1', 35000, NULL, 4, 2, 'BMW GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01100030991569003', 'Mercedes', 'GLE', 55000, NULL, 4, 5, 'DAIMLER GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101130991569003', 'Mercedes', 'A', 45000, 3, 4, 4, 'DAIMLER GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101231111569003', 'Mercedes', 'B', 25000, 4, 5, 3, 'DAIMLER GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01109631111569003', 'Mercedes', 'B', 25000, NULL, 1, 3, 'DAIMLER GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101256111569003', 'Mercedes', 'B', 25000, NULL, 2, 3, 'DAIMLER GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230991566603', 'Audi', 'A7', 50000, 5, 3, 7, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230991569088', 'Audi', 'R8', 65000, 6, 6, 8, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230991565659', 'Skoda', 'Octavia', 25000, 7, 9, 6, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230991558943', 'Skoda', 'Superb', 35000, NULL, 1, 9, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230998548543', 'Skoda', 'Fabia', 25000, NULL, 3, 10, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230998008543', 'Skoda', 'Fabia', 26000, NULL, 5, 1, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230118008540', 'Skoda', 'Fabia', 25000, NULL, 1, 3, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230968008540', 'Skoda', 'Fabia', 25000, NULL, 2, 5, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230996548540', 'Skoda', 'Fabia', 25000, NULL, 4, 2, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('01101230996849040', 'Skoda', 'Fabia', 25000, NULL, 6, 2, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('02601230998008540', 'Skoda', 'Fabia', 25000, NULL, 7, 1, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('08901230998008540', 'Skoda', 'Fabia', 25000, NULL, 8, 2, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('09001230998008540', 'Skoda', 'Fabia', 25000, NULL, 9, 2, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('21701230998008540', 'Audi', 'Q3', 55000, NULL, 2, 3, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('36001230998008540', 'Audi', 'Q7', 35000, NULL, 4, 5, 'VOLKSWAGEN AUTO GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('10001230998008540', 'Mercedes', 'C', 65000, NULL, 5, 4, 'DAIMLER GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('99001230998008540', 'Mercedes', 'C', 55000, NULL, 3, 4, 'DAIMLER GROUP');
INSERT INTO Car(CareCaseNumber, CarModel, ModelType, Price, Purchase_ID, Color_ID, Specification_id, Maker) VALUES('65801230998008540', 'Mercedes', 'A', 45000, NULL, 1, 2, 'DAIMLER GROUP');
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








SELECT * FROM Sellers WHERE Pasport_number SIMILAR TO '%[A-Z]{2}[0-9]{6}%';
SELECT * FROM Sellers WHERE Pasport_number SIMILAR TO '%[А-Я]{2}[0-9]{6}%';
SELECT * FROM Sellers WHERE Pasport_number SIMILAR TO '%[0-9]{9}%';
/*      Получить список моделей автомобилей, ранжированных по стоимости. 
ПРОЕКЦИЯ И СОРТИРОВКА*/
SELECT DISTINCT CarModel, ModelType, Price FROM Car ORDER BY Price;


/*      Получить список 10 самых востребованных моделей автомобилей.
НЕОБХОДИМО ВЫБРАТЬ КУПЛЕННЫЕ АВТО СГРУППИРОВАТЬ ПО МАРКАМ И МОДЕЛЯМ ПОДСЧИТАТЬ КОЛИЧЕСТВО В КАЖДОЙ ГРУППЕ И РАНЖИРОВАТЬ ОТ БОЛЬШЕГО К МЕНЬШЕМУ И ПОСТАВИТЬ ЛИМИТ НА 10 АВТО */
SELECT CarModel, ModelType, COUNT(CarModel) FROM Car WHERE Purchase_ID>=1 GROUP BY(CarModel, ModelType) ORDER BY COUNT DESC LIMIT 10;



/*     Получить список моделей автомобилей, которые были проданы, но никогда не участвовали в предзаказе. При необходимости внести изменения в структуру БД.
НЕОБХОДИМО ОСУШЕСТВИТЬ ДЕКАРТОВО ПРОИЗВЕДЕНИЕ ТАБЛИЦ МАШИН И ПОКУПОК И СДЕЛАТЬ ВЫБОРКУ ПО ТИПУ ПОКУПКИ
*/
SELECT CarModel, ModelType, PurchaseType FROM Car, Purchase WHERE Car.Purchase_ID = Purchase.Purchase_ID AND PurchaseType = 'Без предзаказа';
-- ЧЕРЕЗ ПОДЗАПРОС
SELECT CarModel, ModelType FROM Car WHERE CareCaseNumber IN (SELECT CareCaseNumber FROM Purchase WHERE PurchaseType = 'Без предзаказа');

/*      Реализовать факт увольнения сотрудника (если необходимо, выполнить несколько запросов). 
ДЛЯ КОРРЕКТНОГО УДАЛЕНИЕ ПОМИМО ДАННОГО ЗАПРОСА НЕОБХОДИМО ВОСПОЛЬЗОВАТЬСЯ СПЕЦИАЛЬНЫМИ ОПЕРАТОРАМИ CASCADE И SET NULL, 
КОТОРЫЕ ПОЗВОЛЯТ ПРОВЕСТИ КАСКАДНОЕ УДАЛЕНИЕ В ТАБЛИЦЕ ДОПЛАТ И ЗАМЕНИТЬ НОМЕР ПРОДАВЦА НА NULL В ТАБЛИЦЕ ПОКУПОК ПРИ УДАЛЕНИИ СОТРУДНИКА*/
DELETE FROM Sellers WHERE SellerID = 1;
SELECT * FROM Sellers;
SELECT * FROM SellersSupplement;
SELECT * FROM Purchase;
/* ВВІБРАТЬ ЗАГРАН ПАСП  */
/*      Получить количество бензиновых и дизельных (отдельно) автомобилей, поставленных каждым производителем. При необходимости внести изменения в структуру БД.
НЕОБХОДИМО СДЕЛАТЬ ВЫБОРКУ МАШИН С ПОДХОДЯЩИМ ВИДОМ ТОПЛИВА ИЗ СПЕЦИФИКАЦИИ, СГРУППИРОВАВ ИХ ПО ПРОИЗВОДИТЕЛЮ И ПОДСЧИТАТЬ КОЛИЧЕСТВО  
*/
SELECT DISTINCT Maker,COUNT(CarModel) FROM Car, Specification 
WHERE Car.Specification_ID = Specification.Specification_ID AND FuelType_ID IN (1,2) GROUP BY (Maker,  FuelType_ID);


SELECT DISTINCT Maker,COUNT(CarModel), Fuel_Type FROM Car, Specification, FuelType 
WHERE Car.Specification_ID = Specification.Specification_ID AND FuelType.FuelType_ID = Specification.FuelType_ID 
AND Specification.FuelType_ID IN (1,2) GROUP BY (Maker,Fuel_Type);

--БЕНЗИН
SELECT DISTINCT Maker , COUNT(CarModel) FROM Car, Specification WHERE Car.Specification_ID = Specification.Specification_ID AND FuelType_ID = 1 GROUP BY Maker;
--ДИЗЕЛЬ
SELECT DISTINCT Maker , COUNT(CarModel) FROM Car, Specification WHERE Car.Specification_ID = Specification.Specification_ID AND FuelType_ID = 2 GROUP BY Maker;
/*      Показать клиентов, купивших более одного автомобиля в течение года.
ВЫБОРКА ПО ТАБЛИЦЕ КЛИЕНТА С УСЛОВИЕМ ЧТО ID ПРИНИМАЕТ ЗНАЧЕНИЯ ИЗ ВЫБОРКИ ПО ТАБЛИЦЕ ПОКУПОК ГДЕ ГРУППИРОВАНЫ ID И СТОИТ УСЛОВИЕ ЧТО В ГРУППЕ ИХ БОЛЬШЕ 1
*/
SELECT FirstName, FatherName, LastName FROM Client
WHERE Client_ID IN (SELECT Client_ID FROM  Purchase WHERE PurchaseData >= '2019-01-01' 
GROUP BY Client_ID
HAVING COUNT(Client_ID)>1);
/*      Снизить на 30% цену на автомобили с механической КПП и двигателем объёмом менее 2 л.
ДЛЯ ИЗМЕНЕНИЯ ЦЕНЫ НЕОБХОДИМО ИСПОЛЬЗОВАТЬ UPDATE, А ЧТОБЫ СДЕЛАТЬ ЭТО У КОНКРЕТНЫХ ТИПОВ МАШИН НЕОБХОДИМО СДЕЛАТЬ ВЫБОРКУ 
*/
UPDATE Car SET Price = Price - Price*0.3 WHERE  CareCaseNumber IN (SELECT CareCaseNumber FROM Car, Specification 
WHERE Car.Specification_id = Specification.Specification_id AND Purchase_ID IS NULL AND TransmissionType_ID = 1 AND EngineVolume < 2);
SELECT * FROM CAR;


/*      Получить список моделей автомобилей, представленных абсолютно во всех цветах. 
РЕЛЯЦИОННАЯ ОПЕРАЦИЯ ДЕЛЕНИЯ НЕ ПОДДЕРЖИВАЕТСЯ КОМАНДАМИ, НО ВЫПОЛНЯЕТСЯ ПО ФОРМУЛЕ R[N]-((R[N]*S)-R)[N] 
ДЛЯ ЕЕ РЕАЛИЗАЦИИ СДЕЛАЛА ПРЕДСТАВЛЕНИЕ РЕАЛИЗУЮЩЕЕ (R[N]*S)-R, А ПОТОМ РАЗНОСТЬ */
CREATE VIEW C1 AS
SELECT CarModel, ModelType, Color.Color_ID FROM Car, Color 
EXCEPT
SELECT CarModel, ModelType, Color_ID FROM Car;

SELECT CarModel, ModelType FROM Car
EXCEPT
SELECT CarModel, ModelType FROM C1;
/*      Показать модели автомобилей, которые есть и с механической, и с автоматической КПП.
ДЕКАРТОВО ПРОИЗВЕДЕНИЕ + ВЫБОРКА В ПРЕДСТАВЛЕНИЯХ С 1 И 2 ТИПОМ ТРАНСМ И ИХ ПЕРЕСЕЧЕНИЕ */
CREATE VIEW C2 AS
SELECT DISTINCT CarModel, ModelType, TransmissionType_ID FROM Car, Specification 
WHERE Car.Specification_id = Specification.Specification_id AND TransmissionType_ID=1;
CREATE VIEW C3 AS 
SELECT DISTINCT CarModel, ModelType, TransmissionType_ID FROM Car, Specification 
WHERE Car.Specification_id = Specification.Specification_id AND TransmissionType_ID=2;
SELECT CarModel, ModelType FROM C2
INTERSECT
SELECT CarModel, ModelType FROM C3;


/*жалкие попытки
/*Получить список моделей автомобилей с наименьшей ценой среди моделей с таким же типом топлива.

SELECT DISTINCT ModelType, Fuel_Type, Price FROM Car, Specification, FuelType  
WHERE Car.Specification_ID = Specification.Specification_ID AND FuelType.FuelType_ID = Specification.FuelType_ID GROUP BY (ModelType, Fuel_Type, Price) ORDER BY(ModelType, Fuel_Type, Price)
/*Снизить цену на самые старые автомобили каждой модели на 10%
UPDATE Car SET Price = Price - Price*0.1 
WHERE CareCaseNumber IN 
(SELECT CareCaseNumber FROM Car, Specification 
	WHERE Car.Specification_id = Specification.Specification_id AND Purchase_ID IS NULL ORDER BY ReleasData LIMIT 5);
SELECT * FROM Car;

*/




