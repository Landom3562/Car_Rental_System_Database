ALTER TABLE rental_agreement
DROP CONSTRAINT rental_agreement_rent_a_car_branch_fk;

ALTER TABLE rental_agreement
DROP CONSTRAINT rental_agreement_bill_fk;

ALTER TABLE rental_agreement
DROP CONSTRAINT rental_agreement_customer_fk;

ALTER TABLE rental_agreement
DROP CONSTRAINT rental_agreement_vehicle_fk;

ALTER TABLE bill
DROP CONSTRAINT bill_customer_fk;

ALTER TABLE vehicle
DROP CONSTRAINT vehicle_rent_a_car_branch_fk;

ALTER TABLE maintenance
DROP CONSTRAINT maintenance_vehicle_fk;

ALTER TABLE employee
DROP CONSTRAINT employee_rent_a_car_branch_fk;

ALTER TABLE employee
DROP CONSTRAINT employee_employee_role_fk;

DROP TABLE   employee;
DROP TABLE   employee_role;
DROP TABLE   vehicle;
DROP TABLE   maintenance;
DROP TABLE   rental_agreement;
DROP TABLE   bill;
DROP TABLE   customer;
DROP TABLE   rent_a_car_branch;

alter session set nls_language='ENGLISH';
alter session set nls_date_format='DD-MON-YYYY';

CREATE TABLE rent_a_car_branch
(
    BRANCH_ID       NUMBER(10) PRIMARY KEY,
    BRANCH_NAME     VARCHAR2(30) NOT NULL,
    BRANCH_CITY           VARCHAR2(20),
    BRANCH_STREET         VARCHAR2(20),
    BRANCH_POST_CODE    NUMBER(20),
    CONTACT_NUMBER VARCHAR2(11) UNIQUE,
    BRANCH_MAIL VARCHAR(50),
    OPERATING_HOURS VARCHAR(50),
    OPERATING_DAYS VARCHAR(100)
); 


CREATE TABLE employee
(
    EMPLOYEE_ID     NUMBER(10) PRIMARY KEY,
    BRANCH_ID       NUMBER(10),
    ROLE_ID         NUMBER(10),
    EMPLOYEE_FIRST_NAME      VARCHAR2(15) NOT NULL,
    EMPLOYEE_MIDDLE_NAME     VARCHAR2(15),
    EMPLOYEE_LAST_NAME       VARCHAR2(15) NOT NULL,
    EMPLOYEE_GENDER          VARCHAR2(6),
    EMPLOYEE_NUMBER          VARCHAR2(11) UNIQUE,
    EMPLOYEE_MAIL            VARCHAR2(50) UNIQUE,
    WORK_HOURS      VARCHAR2(12),
    WORK_DAYS       VARCHAR2(60),
    SALARY          NUMBER
);


CREATE TABLE employee_role
(
    ROLE_ID         NUMBER(10) PRIMARY KEY,
    ROLE_NAME       VARCHAR2(20) UNIQUE,
    ROLE_DESCRIPTION VARCHAR(255)
);

CREATE TABLE rental_agreement
(
    RENT_ID          NUMBER(10) PRIMARY KEY,
    BRANCH_ID          NUMBER(10),
    BILL_ID          NUMBER(10),
    CUSTOMER_ID          NUMBER(10),
    VEHICLE_ID          NUMBER(10),
    PICKUP_DATE         DATE NOT NULL,
    RETURN_DATE         DATE NOT NULL,
    LATE_RETURN_DATE    DATE,
    PICKUP_LOCATION     VARCHAR2(50) NOT NULL,
    RETURN_LOCATION     VARCHAR2(50) NOT NULL,
    RENTAL_STATUS    VARCHAR(10) CHECK (RENTAL_STATUS IN ('Active', 'Inactive')), 
    CONSTRAINT return_greater_than_pickup CHECK(RETURN_DATE > PICKUP_DATE)
);

CREATE TABLE vehicle
(
    VEHICLE_ID      NUMBER(10) PRIMARY KEY,
    BRANCH_ID       NUMBER(10),
    VEHICLE_TYPE    VARCHAR2(20) NOT NULL,
    MODEL           VARCHAR2(30) NOT NULL,
    YEAR            NUMBER(4) NOT NULL,
    COLOR           VARCHAR2(20) NOT NULL,
    LICENSE_PLATE   VARCHAR2(20),
    MILEAGE         NUMBER(10),
    FUEL_TYPE       VARCHAR2(10) NOT NULL,
    AVAILABILITY    VARCHAR2(20) CHECK (AVAILABILITY IN ('Available', 'Not Available')),
    DAILY_RATE      NUMBER(10),
    REGISTRATION_DATE   DATE,
    INSUR_EXP_DATE  DATE,
    CAPACITY        NUMBER(2) NOT NULL
);


CREATE TABLE maintenance
(
    MAINTENANCE_ID     NUMBER(10) PRIMARY KEY,
    VEHICLE_ID         NUMBER(10),
    START_DATE         DATE NOT NULL, 
    FINISH_DATE        DATE,
    MAINTENANCE_STATUS    VARCHAR(10) CHECK (MAINTENANCE_STATUS IN ('Active', 'Inactive')),
    MAINTENANCE_COST   NUMBER(10),
    MAINTENANCE_DESCRIPTION   VARCHAR2(200), 
    CONSTRAINT finish_greater_than_start CHECK(FINISH_DATE > START_DATE)
);

CREATE TABLE customer
(
    CUSTOMER_ID              NUMBER(10) PRIMARY KEY,
    CUSTOMER_FIRST_NAME      VARCHAR2(15) NOT NULL,
    CUSTOMER_MIDDLE_NAME     VARCHAR2(15),
    CUSTOMER_LAST_NAME       VARCHAR2(15) NOT NULL,
    CUSTOMER_AGE             NUMBER(3) CHECK(CUSTOMER_AGE > 17),
    CUSTOMER_GENDER          VARCHAR2(6),
    CUSTOMER_CITY            VARCHAR2(20),
    CUSTOMER_POST_CODE       NUMBER,
    CUSTOMER_STREET          VARCHAR2(20),
    CUSTOMER_NUMBER       VARCHAR2(11) UNIQUE,
    CUSTOMER_EMAIL           VARCHAR2(50) UNIQUE,
    CUSTOMER_SOCIAL_SECURITY_NUMBER NUMBER(11) UNIQUE
);

CREATE TABLE bill
(
    BILL_ID                 NUMBER(10) PRIMARY KEY,
    CUSTOMER_ID             NUMBER(10),
    RENT_ID                 NUMBER(10),
    AMOUNT                  NUMBER(10),
    LATE_FEE                NUMBER(10),
    PAYMENT_DATE            DATE,
    PAYMENT_STATUS          VARCHAR2(20) CHECK (PAYMENT_STATUS IN ('Unpaid', 'Paid', 'Cancelled')),
    PAYMENT_TYPE            VARCHAR2(20)
);

ALTER TABLE rental_agreement
ADD CONSTRAINT rental_agreement_rent_a_car_branch_fk
FOREIGN KEY(BRANCH_ID) REFERENCES rent_a_car_branch(BRANCH_ID)
 ON DELETE SET NULL;

ALTER TABLE rental_agreement
ADD CONSTRAINT rental_agreement_bill_fk
FOREIGN KEY(BILL_ID) REFERENCES bill(BILL_ID)
 ON DELETE SET NULL;

ALTER TABLE rental_agreement
ADD CONSTRAINT rental_agreement_customer_fk
FOREIGN KEY(CUSTOMER_ID) REFERENCES customer(CUSTOMER_ID)
 ON DELETE SET NULL;

ALTER TABLE rental_agreement
ADD CONSTRAINT rental_agreement_vehicle_fk
FOREIGN KEY(VEHICLE_ID) REFERENCES vehicle(VEHICLE_ID)
 ON DELETE SET NULL;

ALTER TABLE bill
ADD CONSTRAINT bill_customer_fk
FOREIGN KEY(CUSTOMER_ID) REFERENCES customer(CUSTOMER_ID)
 ON DELETE SET NULL;

ALTER TABLE vehicle
ADD CONSTRAINT vehicle_rent_a_car_branch_fk
FOREIGN KEY(BRANCH_ID) REFERENCES rent_a_car_branch(BRANCH_ID)
 ON DELETE CASCADE;

ALTER TABLE maintenance
ADD CONSTRAINT maintenance_vehicle_fk
FOREIGN KEY(VEHICLE_ID) REFERENCES vehicle(VEHICLE_ID)
 ON DELETE SET NULL;

ALTER TABLE employee
ADD CONSTRAINT employee_rent_a_car_branch_fk
FOREIGN KEY(BRANCH_ID) REFERENCES rent_a_car_branch(BRANCH_ID)
 ON DELETE CASCADE;

ALTER TABLE employee
ADD CONSTRAINT employee_employee_role_fk
FOREIGN KEY(ROLE_ID) REFERENCES employee_role(ROLE_ID)
 ON DELETE CASCADE;

CREATE OR REPLACE TRIGGER redundant_rent_id_of_bill_check
BEFORE DELETE OR UPDATE OF rent_id ON rental_agreement
FOR EACH ROW
BEGIN
IF UPDATING THEN
    UPDATE bill
    SET rent_id = :new.rent_id
    WHERE bill_id = :new.bill_id;
END IF;
IF DELETING THEN
    UPDATE bill
    SET rent_id = null
    WHERE bill_id = :new.bill_id;
END IF;
END;
/

CREATE OR REPLACE TRIGGER rental_agreement_status_to_vehicle
BEFORE INSERT OR UPDATE OF rental_status ON rental_agreement
FOR EACH ROW
BEGIN
    IF :new.rental_status = 'Active' THEN
        UPDATE vehicle
        SET AVAILABILITY = 'Not Available'
        WHERE vehicle_id = :new.vehicle_id;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER maintenance_status_to_vehicle
BEFORE INSERT OR UPDATE OF maintenance_status ON maintenance
FOR EACH ROW
BEGIN
    IF :new.maintenance_status = 'Active' THEN
        UPDATE vehicle
        SET AVAILABILITY = 'Not Available'
        WHERE vehicle_id = :new.vehicle_id;
    END IF;
END;
/

CREATE OR replace TRIGGER create_bill_according_to_rental_agreement
BEFORE INSERT ON rental_agreement
FOR EACH ROW
DECLARE
    n_bill_id number;
    n_customer_id number;
    n_rent_id number;
    days number;
    n_daily_rate number;
    n_amount number;
BEGIN
    n_bill_id := :new.rent_id;

    n_customer_id := :new.customer_id;

    n_rent_id := :new.rent_id;

    days := :new.return_date - :new.pickup_date;

    IF days < 0 THEN
        Raise_application_error(-20001, 'Return date cannot be earlier than the pickup date');
    END IF;

    select daily_rate into n_daily_rate
    from vehicle
    where vehicle_id = :new.vehicle_id;

    n_amount := days * n_daily_rate;

    INSERT INTO bill (bill_id, customer_id, rent_id, amount, payment_status) values
    (n_bill_id, n_customer_id, n_rent_id, n_amount, 'Unpaid');

    :new.bill_id := n_bill_id; --This is done because the bill is just created and the value of the rental_agreement's bill_id was null.
END;
/

CREATE OR REPLACE TRIGGER late_return_compute
AFTER INSERT OR UPDATE OF late_return_date ON rental_agreement
FOR EACH ROW
DECLARE
    days_late INT;
    temp_amount INT;
    temp_fee INT;
    rate INT;
    b_amount INT;
BEGIN
    SELECT amount into b_amount
    FROM bill
    WHERE bill_id = :new.bill_id;

    SELECT daily_rate into rate
    FROM vehicle
    WHERE vehicle_id = :new.vehicle_id;

    IF (:new.late_return_date IS NOT NULL) THEN
        days_late := :NEW.late_return_date - :NEW.return_date;
        temp_fee := (days_late * rate) * 2;
        temp_amount := b_amount + temp_fee;

        UPDATE bill
        SET amount = temp_amount
        WHERE bill.bill_id = :new.bill_id;

        UPDATE bill
        SET late_fee = temp_fee
        WHERE bill.bill_id = :new.bill_id;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER maintenance_to_vehicle
BEFORE INSERT ON maintenance
FOR EACH ROW
BEGIN
    UPDATE vehicle
    SET AVAILABILITY = 'Not Available'
    WHERE vehicle.vehicle_id = :new.vehicle_id;
END; 
/



CREATE OR REPLACE TRIGGER branch_added_trigger
AFTER INSERT ON rent_a_car_branch
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('New item added to rent_a_car_branch table. Branch ID: ' || :new.BRANCH_ID);
END;
/

CREATE OR REPLACE TRIGGER vehicle_availability_check_before_maintenance_insertion
BEFORE INSERT OR UPDATE OF finish_date ON maintenance
FOR EACH ROW
DECLARE
    overlapping_rentals INT;
    overlapping_maintenances INT;
BEGIN
    SELECT COUNT(*)
    INTO overlapping_rentals
    FROM rental_agreement
    WHERE vehicle_id = :NEW.vehicle_id
      AND NOT (
          :NEW.finish_date <= pickup_date
          OR :NEW.start_date >= return_date
      );

    SELECT COUNT(*)
    INTO overlapping_maintenances
    FROM maintenance
    WHERE vehicle_id = :NEW.vehicle_id
      AND NOT (
          :NEW.finish_date <= start_date
          OR :NEW.start_date >= finish_date
      );

    IF overlapping_rentals > 0 OR overlapping_maintenances > 0 THEN
        raise_application_error(-20001, 'Vehicle is not available during the maintenance period');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER vehicle_availability_check_before_rental_agreement_insertion
BEFORE INSERT OR UPDATE OF pickup_date ON rental_agreement
FOR EACH ROW
DECLARE
    overlapping_rentals INT;
    overlapping_maintenances INT;
BEGIN
    SELECT COUNT(*)
    INTO overlapping_rentals
    FROM rental_agreement
    WHERE vehicle_id = :NEW.vehicle_id
      AND NOT (
          :NEW.return_date <= pickup_date
          OR :NEW.pickup_date >= return_date
      );

    SELECT COUNT(*)
    INTO overlapping_maintenances
    FROM maintenance
    WHERE vehicle_id = :NEW.vehicle_id
      AND NOT (
          :NEW.return_date <= start_date
          OR :NEW.pickup_date >= finish_date
      );

    IF overlapping_rentals > 0 OR overlapping_maintenances > 0 THEN
        raise_application_error(-20001, 'Vehicle is not available during the maintenance period');
    END IF;
END;
/
/*
REVOKE SELECT, INSERT, UPDATE, DELETE ON employee FROM admin_role;
REVOKE SELECT, INSERT, UPDATE, DELETE ON employee_role FROM admin_role;
REVOKE SELECT, INSERT, UPDATE, DELETE ON vehicle FROM admin_role;
REVOKE SELECT, INSERT, UPDATE, DELETE ON maintenance FROM admin_role;
REVOKE SELECT, INSERT, UPDATE, DELETE ON rental_agreement FROM admin_role;
REVOKE SELECT, INSERT, UPDATE, DELETE ON bill FROM admin_role;
REVOKE SELECT, INSERT, UPDATE, DELETE ON customer FROM admin_role;
REVOKE SELECT, INSERT, UPDATE, DELETE ON rent_a_car_branch FROM admin_role;

DROP ROLE admin_role;

REVOKE SELECT, INSERT, UPDATE, DELETE ON employee FROM manager_role;
REVOKE SELECT, INSERT, UPDATE, DELETE ON rent_a_car_branch FROM manager_role;
REVOKE SELECT, INSERT, UPDATE, DELETE ON vehicle FROM manager_role;
REVOKE SELECT ON rental_agreement FROM manager_role;
REVOKE SELECT ON customer FROM manager_role;
REVOKE SELECT (BILL_ID, CUSTOMER_ID, RENT_ID, PAYMENT_DATE, PAYMENT_STATUS, PAYMENT_TYPE) ON bill FROM manager_role;

DROP ROLE manager_role;

REVOKE SELECT, INSERT, UPDATE, DELETE ON rental_agreement FROM emp_role;
REVOKE SELECT ON customer FROM emp_role;
REVOKE SELECT ON vehicle FROM emp_role;
REVOKE SELECT, INSERT ON maintenance FROM emp_role;
REVOKE SELECT (BILL_ID, CUSTOMER_ID, RENT_ID, PAYMENT_STATUS) ON bill FROM emp_role;

DROP ROLE emp_role;

REVOKE SELECT ON vehicle FROM customer_role;
REVOKE SELECT, INSERT, UPDATE, DELETE ON rental_agreement FROM customer_role;

DROP ROLE customer_role;

CREATE ROLE admin_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON employee TO admin_role WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON employee_role TO admin_role WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON vehicle TO admin_role WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON maintenance TO admin_role WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON rental_agreement TO admin_role WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON bill TO admin_role WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON customer TO admin_role WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON rent_a_car_branch TO admin_role WITH GRANT OPTION;

CREATE ROLE manager_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON employee TO manager_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rent_a_car_branch TO manager_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON vehicle TO manager_role;
GRANT SELECT ON rental_agreement TO manager_role;
GRANT SELECT ON customer TO manager_role;
GRANT SELECT (BILL_ID, CUSTOMER_ID, RENT_ID, PAYMENT_DATE, PAYMENT_STATUS, PAYMENT_TYPE) ON bill TO manager_role;

CREATE ROLE emp_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON rental_agreement TO emp_role;
GRANT SELECT ON customer TO emp_role;
GRANT SELECT ON vehicle TO emp_role;
GRANT SELECT, INSERT ON maintenance TO emp_role
    WHERE VEHICLE_ID IN (SELECT VEHICLE_ID FROM vehicle WHERE BRANCH_ID = (SELECT BRANCH_ID FROM employee WHERE EMPLOYEE_ID = USER)); --This refers to the id of the employee that is written in employee table.

GRANT SELECT (BILL_ID, CUSTOMER_ID, RENT_ID, PAYMENT_STATUS) ON bill TO emp_role;

CREATE ROLE customer_role;

GRANT SELECT ON vehicle TO customer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rental_agreement TO customer_role 
    WHERE CUSTOMER_ID = USER; --This refers to the id of the customer that is written in customer table.

/
*/
INSERT INTO employee_role (ROLE_ID, ROLE_NAME, ROLE_DESCRIPTION)
VALUES
(1, 'Manager', 'Responsible for branch operations');
INSERT INTO employee_role (ROLE_ID, ROLE_NAME, ROLE_DESCRIPTION)
VALUES
(2, 'Salesperson', 'Deals with customers and sales');
INSERT INTO employee_role (ROLE_ID, ROLE_NAME, ROLE_DESCRIPTION)
VALUES
(3, 'Technician', 'Handles vehicle maintenance');
INSERT INTO employee_role (ROLE_ID, ROLE_NAME, ROLE_DESCRIPTION)
VALUES
(4, 'Accountant', 'Manages financial transactions');
INSERT INTO employee_role (ROLE_ID, ROLE_NAME, ROLE_DESCRIPTION)
VALUES
(5, 'HR', 'Handles human resource matters');
INSERT INTO employee_role (ROLE_ID, ROLE_NAME, ROLE_DESCRIPTION)
VALUES
(6, 'Marketing', 'Responsible for marketing activities');
INSERT INTO employee_role (ROLE_ID, ROLE_NAME, ROLE_DESCRIPTION)
VALUES
(7, 'IT', 'Manages IT systems and support');
INSERT INTO employee_role (ROLE_ID, ROLE_NAME, ROLE_DESCRIPTION)
VALUES
(8, 'Customer Service', 'Deals with customer inquiries and support');

INSERT INTO rent_a_car_branch (BRANCH_ID, BRANCH_NAME, BRANCH_CITY, BRANCH_STREET, BRANCH_POST_CODE, CONTACT_NUMBER, BRANCH_MAIL, OPERATING_HOURS, OPERATING_DAYS)
VALUES
(1, 'Downtown Branch', 'New York', 'Broadway St', 10001, 1234567890, 'downtown@example.com', '09.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY');
INSERT INTO rent_a_car_branch (BRANCH_ID, BRANCH_NAME, BRANCH_CITY, BRANCH_STREET, BRANCH_POST_CODE, CONTACT_NUMBER, BRANCH_MAIL, OPERATING_HOURS, OPERATING_DAYS)
VALUES
(2, 'Uptown Branch', 'New York', 'Madison Ave', 10002, 2345678901, 'uptown@example.com', '7.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY');

INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(1, 1, 1, 'John', NULL, 'Doe', 'Male', 2125551234, 'john@example.com', '09.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY', 60000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(2, 1, 2, 'Jane', 'Elizabeth', 'Smith', 'Female', 3105555678, 'jane@example.com', '09.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY', 50000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(3, 1, 3, 'Michael', NULL, 'Johnson', 'Male', 7135559012, 'michael@example.com', '09.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY', 55000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(4, 1, 4, 'Emily', NULL, 'Brown', 'Female', 7865553456, 'emily@example.com', '09.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY', 58000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(5, 1, 5, 'Daniel', NULL, 'Garcia', 'Male', 4155557890, 'daniel@example.com', '09.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY', 52000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(6, 1, 6, 'Olivia', NULL, 'Martinez', 'Female', 9175552345, 'olivia@example.com', '09.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY', 56000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(7, 1, 7, 'William', 'Charles', 'Lopez', 'Male', 5125556789, 'william@example.com', '09.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY', 60000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(8, 1, 8, 'Sophia', NULL, 'Gonzalez', 'Female', 6155551234, 'sophia@example.com', '09.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY', 54000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(9, 1, 2, 'James', NULL, 'Rodriguez', 'Male', 2025555678, 'james@example.com', '09.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY', 57000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(10, 1, 8, 'Amelia', NULL, 'Miller', 'Female', 6025559012, 'amelia@example.com', '09.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY', 59000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(11, 2, 1, 'Benjamin', 'Samuel', 'Taylor', 'Male', 2145553456, 'benjamin@example.com', '7.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY', 53000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(12, 2, 2, 'Evelyn', NULL, 'Clark', 'Female', 3125557890, 'evelyn@example.com', '7.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY', 56000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(13, 2, 3, 'Alexander', 'Joseph', 'Hernandez', 'Male', 4075552345, 'alexander@example.com', '7.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY', 61000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(14, 2, 4, 'Mia', NULL, 'Young', 'Female', 5035556789, 'mia@example.com', '7.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY', 54000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(15, 2, 5, 'Charlotte', 'Grace', 'Flores', 'Female', 8325551234, 'charlotte@example.com', '7.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY', 59000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(16, 2, 6, 'Henry', NULL, 'King', 'Male', 7045555678, 'henry@example.com', '7.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY', 57000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(17, 2, 7, 'Scarlett', NULL, 'Baker', 'Female', 7025559012, 'scarlett@example.com', '7.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY', 54000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(18, 2, 8, 'Liam', NULL, 'Gomez', 'Male', 8185553456, 'liam@example.com', '7.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY', 58000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(19, 2, 8, 'Chloe', NULL, 'Perez', 'Female', 2065557890, 'chloe@example.com', '7.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY', 55000);
INSERT INTO employee (EMPLOYEE_ID, BRANCH_ID, ROLE_ID, EMPLOYEE_FIRST_NAME, EMPLOYEE_MIDDLE_NAME, EMPLOYEE_LAST_NAME, EMPLOYEE_GENDER, EMPLOYEE_NUMBER, EMPLOYEE_MAIL, WORK_HOURS, WORK_DAYS, SALARY)
VALUES
(20, 2, 2, 'Aiden', NULL, 'Turner', 'Male', 3035552345, 'aiden@example.com', '7.00-00.00', 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY', 56000);

INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(1, 1, 'Sedan', 'Toyota Camry', 2022, 'Red', 'ABC123', 15000, 'Gasoline', 'Available', 60, TO_DATE('2023-12-01', 'YYYY-MM-DD'), TO_DATE('2024-01-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(2, 1, 'SUV', 'Honda CR-V', 2021, 'Black', 'DEF456', 18000, 'Gasoline', 'Available', 80, TO_DATE('2023-11-01', 'YYYY-MM-DD'), TO_DATE('2024-02-01', 'YYYY-MM-DD'), 3);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(3, 2, 'Compact', 'Ford Focus', 2020, 'Blue', 'GHI789', 20000, 'Gasoline', 'Available', 50, TO_DATE('2023-10-01', 'YYYY-MM-DD'), TO_DATE('2024-03-01', 'YYYY-MM-DD'), 4);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(4, 2, 'Sedan', 'Nissan Altima', 2022, 'White', 'JKL012', 12000, 'Gasoline', 'Available', 65, TO_DATE('2023-09-01', 'YYYY-MM-DD'), TO_DATE('2024-04-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(5, 1, 'SUV', 'Toyota RAV4', 2021, 'Silver', 'MNO345', 22000, 'Gasoline', 'Available', 75, TO_DATE('2023-08-01', 'YYYY-MM-DD'), TO_DATE('2024-05-01', 'YYYY-MM-DD'), 6);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(6, 1, 'Compact', 'Honda Civic', 2022, 'Gray', 'PQR678', 14000, 'Gasoline', 'Available', 55, TO_DATE('2023-07-01', 'YYYY-MM-DD'), TO_DATE('2024-06-01', 'YYYY-MM-DD'),5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(7, 2, 'SUV', 'Ford Escape', 2020, 'Green', 'STU901', 19000, 'Gasoline', 'Available', 70, TO_DATE('2023-06-01', 'YYYY-MM-DD'), TO_DATE('2024-07-01', 'YYYY-MM-DD'),5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(8, 2, 'Sedan', 'Chevrolet Malibu', 2021, 'Black', 'VWX234', 16000, 'Gasoline', 'Available', 65, TO_DATE('2023-05-01', 'YYYY-MM-DD'), TO_DATE('2024-08-01', 'YYYY-MM-DD'),5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(9, 1, 'Compact', 'Hyundai Elantra', 2022, 'Red', 'YZA567', 13000, 'Gasoline', 'Available', 50, TO_DATE('2023-04-01', 'YYYY-MM-DD'), TO_DATE('2024-09-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(10, 1, 'SUV', 'Kia Sportage', 2020, 'White', 'BCD890', 20000, 'Gasoline', 'Available', 80, TO_DATE('2023-03-01', 'YYYY-MM-DD'), TO_DATE('2024-10-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(11, 2, 'Compact', 'Mazda 3', 2021, 'Blue', 'EFG123', 18000, 'Gasoline', 'Available', 60, TO_DATE('2023-02-01', 'YYYY-MM-DD'), TO_DATE('2024-11-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(12, 2, 'Sedan', 'Volkswagen Passat', 2022, 'Silver', 'HIJ456', 15000, 'Gasoline', 'Available', 70, TO_DATE('2023-01-01', 'YYYY-MM-DD'), TO_DATE('2024-12-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(13, 1, 'SUV', 'Subaru Outback', 2020, 'Black', 'KLM789', 16000, 'Gasoline', 'Available', 75, TO_DATE('2022-12-01', 'YYYY-MM-DD'), TO_DATE('2025-01-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(14, 1, 'Compact', 'Nissan Versa', 2021, 'Red', 'NOP012', 13000, 'Gasoline', 'Available', 55, TO_DATE('2022-11-01', 'YYYY-MM-DD'), TO_DATE('2025-02-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(15, 2, 'Sedan', 'Toyota Avalon', 2022, 'White', 'QRS345', 17000, 'Gasoline', 'Available', 65, TO_DATE('2022-10-01', 'YYYY-MM-DD'), TO_DATE('2025-03-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(16, 2, 'Compact', 'Ford Fiesta', 2020, 'Blue', 'TUV678', 14000, 'Gasoline', 'Available', 50, TO_DATE('2022-09-01', 'YYYY-MM-DD'), TO_DATE('2025-04-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(17, 1, 'SUV', 'Jeep Cherokee', 2021, 'Green', 'VWX901', 18000, 'Gasoline', 'Available', 70, TO_DATE('2022-08-01', 'YYYY-MM-DD'), TO_DATE('2025-05-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(18, 1, 'Compact', 'Chevrolet Sonic', 2022, 'Red', 'YZA234', 15000, 'Gasoline', 'Available', 60, TO_DATE('2022-07-01', 'YYYY-MM-DD'), TO_DATE('2025-06-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(19, 2, 'Sedan', 'Honda Accord', 2020, 'Silver', 'BCD567', 16000, 'Gasoline', 'Available', 65, TO_DATE('2022-06-01', 'YYYY-MM-DD'), TO_DATE('2025-07-01', 'YYYY-MM-DD'), 5);
INSERT INTO vehicle (VEHICLE_ID, BRANCH_ID, VEHICLE_TYPE, MODEL, YEAR, COLOR, LICENSE_PLATE, MILEAGE, FUEL_TYPE, AVAILABILITY, DAILY_RATE, REGISTRATION_DATE, INSUR_EXP_DATE, CAPACITY)
VALUES
(20, 2, 'Compact', 'Volkswagen Golf', 2021, 'Blue', 'EFG890', 14000, 'Gasoline', 'Available', 55, TO_DATE('2022-05-01', 'YYYY-MM-DD'), TO_DATE('2025-08-01', 'YYYY-MM-DD'), 5);


INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (1, 1, TO_DATE('01-JAN-2023'), TO_DATE('03-JAN-2023'), 'Active', 100.00, 'Oil change, brake inspection, and tire rotation');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (2, 2, TO_DATE('02-JAN-2023'), TO_DATE('04-JAN-2023'), 'Inactive', 150.00, 'Transmission fluid change and engine diagnostics');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (3, 3, TO_DATE('03-JAN-2023'), TO_DATE('05-JAN-2023'), 'Active', 200.00, 'Coolant system flush and spark plug replacement');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (4, 4, TO_DATE('04-JAN-2023'), TO_DATE('06-JAN-2023'), 'Inactive', 250.00, 'Air filter replacement and suspension check');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (5, 5, TO_DATE('05-JAN-2023'), TO_DATE('07-JAN-2023'), 'Active', 300.00, 'Brake pad replacement and wheel alignment');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (6, 6, TO_DATE('06-JAN-2023'), TO_DATE('08-JAN-2023'), 'Inactive', 350.00, 'Engine tune-up and battery inspection');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (7, 7, TO_DATE('07-JAN-2023'), TO_DATE('09-JAN-2023'), 'Active', 400.00, 'Tire change and steering system check');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (8, 8, TO_DATE('08-JAN-2023'), TO_DATE('10-JAN-2023'), 'Inactive', 450.00, 'Headlight alignment and exhaust system check');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (9, 9, TO_DATE('09-JAN-2023'), TO_DATE('11-JAN-2023'), 'Active', 500.00, 'Fuel system cleaning and windshield wiper replacement');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (10, 10, TO_DATE('10-JAN-2023'), TO_DATE('12-JAN-2023'), 'Inactive', 550.00, 'Radiator flush and power steering fluid change');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (11, 11, TO_DATE('11-JAN-2023'), TO_DATE('13-JAN-2023'), 'Active', 600.00, 'Suspension overhaul and brake system inspection');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (12, 12, TO_DATE('12-JAN-2023'), TO_DATE('14-JAN-2023'), 'Inactive', 650.00, 'Engine diagnostics and oil pressure check');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (13, 13, TO_DATE('13-JAN-2023'), TO_DATE('15-JAN-2023'), 'Active', 700.00, 'Transmission inspection and fluid change');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (14, 14, TO_DATE('14-JAN-2023'), TO_DATE('16-JAN-2023'), 'Inactive', 750.00, 'Coolant system check and thermostat replacement');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (15, 15, TO_DATE('15-JAN-2023'), TO_DATE('17-JAN-2023'), 'Active', 800.00, 'Brake system flush and rotor replacement');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (16, 16, TO_DATE('16-JAN-2023'), TO_DATE('18-JAN-2023'), 'Inactive', 850.00, 'Battery load test and electrical system check');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (17, 17, TO_DATE('17-JAN-2023'), TO_DATE('19-JAN-2023'), 'Active', 900.00, 'Wheel bearing replacement and alignment');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (18, 18, TO_DATE('18-JAN-2023'), TO_DATE('20-JAN-2023'), 'Inactive', 950.00, 'Power steering inspection and fluid top-up');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (19, 19, TO_DATE('19-JAN-2023'), TO_DATE('21-JAN-2023'), 'Active', 1000.00, 'Fuel injector cleaning and air intake check');
INSERT INTO Maintenance (maintenance_id, vehicle_id, start_date, finish_date, maintenance_status, maintenance_cost, maintenance_description)
VALUES
  (20, 20, TO_DATE('20-JAN-2023'), TO_DATE('22-JAN-2023'), 'Inactive', 1050.00, 'Full vehicle inspection and maintenance');
/

INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (1, 'John', NULL, 'Doe', 'Male', 35, 'New York', 10001, '123 Main St', 1234567890, 'john@example.com', 123456789);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (2, 'Jane', 'Elizabeth', 'Smith', 'Female', 28, 'Los Angeles', 90001, '456 Elm St', 1987654321, 'jane@example.com', 987654321);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (3, 'Michael', 'Charles', 'Johnson', 'Male', 42, 'Chicago', 60601, '789 Oak St', 1122334455, 'michael@example.com', 112233445);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (4, 'Emily', NULL, 'Brown', 'Female', 30, 'Houston', 77001, '987 Cedar St', 1445566778, 'emily@example.com', 144556677);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (5, 'William', 'Henry', 'Taylor', 'Male', 39, 'Phoenix', 85001, '654 Pine St', 1765432987, 'william@example.com', 176543298);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (6, 'Olivia', 'Grace', 'Anderson', 'Female', 25, 'Philadelphia', 19101, '321 Birch St', 5532568714, 'olivia@example.com', 521487632);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (7, 'James', NULL, 'Martinez', 'Male', 45, 'San Antonio', 78201, '852 Maple St', 1654321987, 'james@example.com', 165432198);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (8, 'Sophia', 'Rose', 'Garcia', 'Female', 33, 'San Diego', 92101, '741 Walnut St', 1908765432, 'sophia@example.com', 190876543);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (9, 'Alexander', NULL, 'Lopez', 'Male', 29, 'Dallas', 75201, '369 Cedar St', 1555666777, 'alexander@example.com', 155566677);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (10, 'Mia', 'Isabella', 'Hernandez', 'Female', 37, 'San Jose', 95101, '159 Pine St', 1789456123, 'mia@example.com', 178945612);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (11, 'Liam', 'Michael', 'Gonzalez', 'Male', 31, 'Austin', 73301, '258 Oak St', 1777222333, 'liam@example.com', 177722233);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (12, 'Charlotte', NULL, 'Wilson', 'Female', 26, 'Jacksonville', 32099, '753 Maple St', 1324364758, 'charlotte@example.com', 132436475);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (13, 'Ethan', 'Christopher', 'Perez', 'Male', 40, 'San Francisco', 94101, '123 Cedar St', 1918171615, 'ethan@example.com', 191817161);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (14, 'Ava', 'Sophie', 'Torres', 'Female', 27, 'Indianapolis', 46201, '456 Birch St', 1661728394, 'ava@example.com', 166172839);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (15, 'Noah', 'Samuel', 'Rivera', 'Male', 34, 'Columbus', 43085, '789 Pine St', 1800854321, 'noah@example.com', 180085432);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (16, 'Amelia', NULL, 'Long', 'Female', 32, 'Charlotte', 28201, '963 Maple St', 3261248896, 'amelia@example.com', 198765432);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (17, 'Logan', 'David', 'Scott', 'Male', 38, 'Seattle', 98101, '741 Oak St', 1209876543, 'logan@example.com', 120987654);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (18, 'Avery', 'Grace', 'Nguyen', 'Female', 24, 'Denver', 80201, '852 Elm St', 1309854321, 'avery@example.com', 130985432);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (19, 'Lucas', NULL, 'Kim', 'Male', 36, 'Washington', 20001, '963 Cedar St', 1256789432, 'lucas@example.com', 125678943);
INSERT INTO Customer (customer_id,customer_first_name,customer_middle_name,customer_last_name,customer_gender,customer_age,customer_city,customer_post_code,customer_street,customer_number,customer_email,customer_social_security_number)
VALUES
    (20, 'Harper', 'Lillian', 'Collins', 'Female', 41, 'Boston', 2101, '159 Pine St', 1405678932, 'harper@example.com', 140567893);
/


INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('1', '1', NULL, '1', '1', TO_DATE('05-JAN-2023', 'DD-MON-YYYY'), TO_DATE('10-JAN-2023', 'DD-MON-YYYY'), TO_DATE('12-JAN-2023', 'DD-MON-YYYY'), 'City Center', 'Airport', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('2', '2', NULL, '2', '2', TO_DATE('10-FEB-2023', 'DD-MON-YYYY'), TO_DATE('17-FEB-2023', 'DD-MON-YYYY'), NULL, 'Suburb Plaza', 'Downtown', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('3', '1', NULL, '3', '3', TO_DATE('20-MAR-2023', 'DD-MON-YYYY'), TO_DATE('25-MAR-2023', 'DD-MON-YYYY'), NULL, 'Beachside', 'Beachside', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('4', '2', NULL, '4', '4', TO_DATE('15-APR-2023', 'DD-MON-YYYY'), TO_DATE('20-APR-2023', 'DD-MON-YYYY'), NULL, 'Downtown', 'City Center', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('5', '1', NULL, '5', '5', TO_DATE('01-MAY-2023', 'DD-MON-YYYY'), TO_DATE('05-MAY-2023', 'DD-MON-YYYY'), NULL, 'Airport', 'Suburb Plaza', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('6', '2', NULL, '6', '6', TO_DATE('10-JUN-2023', 'DD-MON-YYYY'), TO_DATE('12-JUN-2023', 'DD-MON-YYYY'), TO_DATE('15-JUN-2023', 'DD-MON-YYYY'), 'City Center', 'Downtown', 'Active');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('7', '1', NULL, '7', '7', TO_DATE('20-JUL-2023', 'DD-MON-YYYY'), TO_DATE('25-JUL-2023', 'DD-MON-YYYY'), NULL, 'Beachside', 'Beachside', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('8', '2', NULL, '8', '8', TO_DATE('12-AUG-2023', 'DD-MON-YYYY'), TO_DATE('18-AUG-2023', 'DD-MON-YYYY'), NULL, 'Suburb Plaza', 'Airport', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('9', '1', NULL, '9', '9', TO_DATE('05-SEP-2023', 'DD-MON-YYYY'), TO_DATE('10-SEP-2023', 'DD-MON-YYYY'), NULL, 'Downtown', 'City Center', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('10', '2', NULL, '10', '10', TO_DATE('18-OCT-2023', 'DD-MON-YYYY'), TO_DATE('22-OCT-2023', 'DD-MON-YYYY'), NULL, 'Airport', 'Suburb Plaza', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('11', '1', NULL, '11', '11', TO_DATE('05-NOV-2023', 'DD-MON-YYYY'), TO_DATE('10-NOV-2023', 'DD-MON-YYYY'), TO_DATE('15-NOV-2023', 'DD-MON-YYYY'), 'City Center', 'Downtown', 'Active');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('12', '2', NULL, '12', '12', TO_DATE('20-DEC-2023', 'DD-MON-YYYY'), TO_DATE('25-DEC-2023', 'DD-MON-YYYY'), NULL, 'Suburb Plaza', 'Airport', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('13', '1', NULL, '13', '13', TO_DATE('10-JAN-2024', 'DD-MON-YYYY'), TO_DATE('15-JAN-2024', 'DD-MON-YYYY'), NULL, 'Downtown', 'City Center', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('14', '2', NULL, '14', '14', TO_DATE('18-FEB-2024', 'DD-MON-YYYY'), TO_DATE('22-FEB-2024', 'DD-MON-YYYY'), NULL, 'Airport', 'Suburb Plaza', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('15', '1', NULL, '15', '15', TO_DATE('05-MAR-2024', 'DD-MON-YYYY'), TO_DATE('10-MAR-2024', 'DD-MON-YYYY'), NULL, 'Beachside', 'Beachside', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('16', '2', NULL, '16', '16', TO_DATE('10-APR-2024', 'DD-MON-YYYY'), TO_DATE('15-APR-2024', 'DD-MON-YYYY'), TO_DATE('18-APR-2024', 'DD-MON-YYYY'), 'City Center', 'Downtown', 'Active');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('17', '1', NULL, '17', '17', TO_DATE('20-MAY-2024', 'DD-MON-YYYY'), TO_DATE('25-MAY-2024', 'DD-MON-YYYY'), NULL, 'Suburb Plaza', 'Airport', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('18', '2', NULL, '18', '18', TO_DATE('12-JUN-2024', 'DD-MON-YYYY'), TO_DATE('18-JUN-2024', 'DD-MON-YYYY'), NULL, 'Downtown', 'City Center', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('19', '1', NULL, '19', '19', TO_DATE('05-JUL-2024', 'DD-MON-YYYY'), TO_DATE('10-JUL-2024', 'DD-MON-YYYY'), NULL, 'Airport', 'Suburb Plaza', 'Inactive');
INSERT INTO rental_agreement (rent_id, branch_id, bill_id, customer_id, vehicle_id, pickup_date, return_date, late_return_date, pickup_location, return_location, rental_status) 
VALUES 
('20', '2', NULL, '20', '20', TO_DATE('18-AUG-2024', 'DD-MON-YYYY'), TO_DATE('22-AUG-2024', 'DD-MON-YYYY'), TO_DATE('25-AUG-2024', 'DD-MON-YYYY'), 'Beachside', 'Beachside', 'Active');



UPDATE bill
SET 
    payment_date = TO_DATE('22-DEC-2023', 'DD-MON-YYYY'),
    payment_type = 'Credit Card',
    payment_status = 'Paid'
WHERE
    bill_id = 7;

/
UPDATE bill
SET 
    payment_date = TO_DATE('25-DEC-2023', 'DD-MON-YYYY'),
    payment_type = 'Check',
    payment_status = 'Paid'
WHERE
    bill_id = 12;

/
UPDATE bill
SET 
    payment_date = TO_DATE('28-DEC-2023', 'DD-MON-YYYY'),
    payment_type = 'Bank Transfer',
    payment_status = 'Paid'
WHERE
    bill_id = 15;

/
UPDATE bill
SET 
    payment_date = TO_DATE('30-DEC-2023', 'DD-MON-YYYY'),
    payment_type = 'Cash',
    payment_status = 'Paid'
WHERE
    bill_id = 18;

/
UPDATE bill
SET 
    payment_date = TO_DATE('31-DEC-2023', 'DD-MON-YYYY'),
    payment_type = 'Online Payment',
    payment_status = 'Paid'
WHERE
    bill_id = 20;

/
UPDATE bill
SET 
    payment_date = TO_DATE('29-DEC-2023', 'DD-MON-YYYY'),
    payment_type = 'Debit Card',
    payment_status = 'Paid'
WHERE
    bill_id = 3;

/
UPDATE bill
SET 
    payment_date = TO_DATE('27-DEC-2023', 'DD-MON-YYYY'),
    payment_type = 'Credit Card',
    payment_status = 'Paid'
WHERE
    bill_id = 8;

/
UPDATE bill
SET 
    payment_date = TO_DATE('26-DEC-2023', 'DD-MON-YYYY'),
    payment_type = 'Bank Transfer',
    payment_status = 'Paid'
WHERE
    bill_id = 11;

/
UPDATE Bill
SET 
    payment_date = TO_DATE('23-DEC-2023', 'DD-MON-YYYY'),
    payment_type = 'Cash',
    payment_status = 'Paid'
WHERE
    bill_id = 4;

/
UPDATE Bill
SET 
    payment_date = TO_DATE('24-DEC-2023', 'DD-MON-YYYY'),
    payment_type = 'Credit Card',
    payment_status = 'Paid'
WHERE
    bill_id = 9;

/
UPDATE Bill
SET 
    payment_date = TO_DATE('29-DEC-2023', 'DD-MON-YYYY'),
    payment_type = 'Online Payment',
    payment_status = 'Paid'
WHERE
    bill_id = 14;

/
UPDATE Bill
SET 
    payment_date = TO_DATE('30-DEC-2023', 'DD-MON-YYYY'),
    payment_type = 'Debit Card',
    payment_status = 'Paid'
WHERE
    bill_id = 19;
