/*      Получить общий список проданных бензиновых и дизельных автомобилей с указанием для каждого типа количества автомобилей с механической и автоматической КПП. 
Результат представить в виде таблицы:
‘бензиновые’ | кол-во мех. КПП | кол-во авт. КПП
‘дизельные’   | кол-во мех. КПП | кол-во авт. КПП*/
SELECT  COUNT(FuelType_ID) FROM Car, Specification 
WHERE Car.Specification_id = Specification.Specification_id 
AND Purchcase_ID >=1 AND FuelType_ID = 1 AND TransmissionType_ID = 1 
GROUP BY FuelType_ID;

SELECT COUNT(FuelType_ID) FROM Car, Specification 
WHERE Car.Specification_id = Specification.Specification_id 
AND Purchcase_ID >=1 AND FuelType_ID = 1 AND TransmissionType_ID = 2 
GROUP BY FuelType_ID;

SELECT  COUNT(FuelType_ID) FROM Car, Specification 
WHERE Car.Specification_id = Specification.Specification_id 
AND Purchcase_ID >=1 AND FuelType_ID = 2 AND TransmissionType_ID = 1 
GROUP BY FuelType_ID;

SELECT  COUNT(FuelType_ID) FROM Car, Specification 
WHERE Car.Specification_id = Specification.Specification_id 
AND Purchcase_ID >=1 AND FuelType_ID = 2 AND TransmissionType_ID = 2 
GROUP BY FuelType_ID;

/*CREATE OR REPLACE FUNCTION AddPurchaseFunc()
          RETURNS TRIGGER
AS $$
  DECLARE tmp int;
BEGIN
  IF ((
    SELECT c.carecasenumber
    FROM Car c
    WHERE c.carecasenumber = new.carecasenumber AND c.purchcase_id IS NULL) IS NULL)
    THEN RAISE EXCEPTION 'Машина продана либо некорректный номер.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;*/
/*
CREATE TRIGGER AddPurchase
BEFORE INSERT ON Purchase
FOR EACH ROW 
EXECUTE PROCEDURE AddPurchaseFunc();*/


/*      Получить общий список проданных бензиновых и дизельных автомобилей с указанием для каждого типа количества автомобилей с механической и автоматической КПП. 
Результат представить в виде таблицы:
‘бензиновые’ | кол-во мех. КПП | кол-во авт. КПП
‘дизельные’   | кол-во мех. КПП | кол-во авт. КПП*/
SELECT  COUNT(FuelType_ID) FROM Car, Specification 
WHERE Car.Specification_id = Specification.Specification_id 
AND Purchcase_ID >=1 AND FuelType_ID = 1 AND TransmissionType_ID = 1 
GROUP BY FuelType_ID;

SELECT COUNT(FuelType_ID) FROM Car, Specification 
WHERE Car.Specification_id = Specification.Specification_id 
AND Purchcase_ID >=1 AND FuelType_ID = 1 AND TransmissionType_ID = 2 
GROUP BY FuelType_ID;

SELECT  COUNT(FuelType_ID) FROM Car, Specification 
WHERE Car.Specification_id = Specification.Specification_id 
AND Purchcase_ID >=1 AND FuelType_ID = 2 AND TransmissionType_ID = 1 
GROUP BY FuelType_ID;

SELECT  COUNT(FuelType_ID) FROM Car, Specification 
WHERE Car.Specification_id = Specification.Specification_id 
AND Purchcase_ID >=1 AND FuelType_ID = 2 AND TransmissionType_ID = 2 
GROUP BY FuelType_ID;

/*CREATE OR REPLACE FUNCTION AddCarPurchaseFunc()
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
EXECUTE PROCEDURE AddCarPurchaseFunc();*/