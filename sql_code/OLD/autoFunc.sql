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
      WHERE c.purchase_id IS NULL AND c.modeltype = model_type
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




