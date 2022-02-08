-- 14a (i), (ii).
CREATE OR REPLACE PACKAGE PKG
IS
	PROCEDURE HIRE_EMP (
		EID IN EMPLOYEE.EMPID%TYPE,
		ENAME IN EMPLOYEE.EMPNAME%TYPE,
		EMPJOB IN EMPLOYEE.JOB%TYPE,
		EMPMGR IN EMPLOYEE.MANAGER%TYPE,
		EMPDEPTNO IN EMPLOYEE.DEPTNO%TYPE,
		EMPHIREDATE IN EMPLOYEE.HIREDATE%TYPE,
		EMPSAL IN EMPLOYEE.SALARY%TYPE,
		EMPCOMM IN EMPLOYEE.COMM%TYPE
	);

	FUNCTION INC_COMM (
		EID IN EMPLOYEE.EMPID%TYPE, 
		NEWCOMM IN EMPLOYEE.COMM%TYPE
	)
	RETURN VARCHAR2;
END;

CREATE OR REPLACE PACKAGE BODY PKG 
IS
	PROCEDURE HIRE_EMP (
		EID IN EMPLOYEE.EMPID%TYPE,
		ENAME IN EMPLOYEE.EMPNAME%TYPE,
		EMPJOB IN EMPLOYEE.JOB%TYPE,
		EMPMGR IN EMPLOYEE.MANAGER%TYPE,
		EMPDEPTNO IN EMPLOYEE.DEPTNO%TYPE,
		EMPHIREDATE IN EMPLOYEE.HIREDATE%TYPE,
		EMPSAL IN EMPLOYEE.SALARY%TYPE,
		EMPCOMM IN EMPLOYEE.COMM%TYPE
	)
	IS
	BEGIN	
		INSERT INTO EMPLOYEE 
		VALUES (
			EID,
			ENAME,
			EMPJOB,
			EMPMGR,
			EMPDEPTNO,
			TO_DATE(EMPHIREDATE, 'DD/MM/YYYY'),
			EMPSAL,
			EMPCOMM
		);
		
		DBMS_OUTPUT.PUT_LINE('EMPLOYEE ADDED.');
	END;

	FUNCTION INC_COMM(EID IN EMPLOYEE.EMPID%TYPE, NEWCOMM IN EMPLOYEE.COMM%TYPE)
	RETURN VARCHAR2
	IS
	BEGIN 
		UPDATE EMPLOYEE 
		SET COMM = NEWCOMM
		WHERE EMPID = EID;

		RETURN EID;
	END;
END;

-- To call the procedure HIRE_EMP
DECLARE 
	EID EMPLOYEE.EMPID%TYPE := '&EID';
	ENAME EMPLOYEE.EMPNAME%TYPE := '&ENAME';
	EMPJOB EMPLOYEE.JOB%TYPE := '&EMPJOB';
	EMPMGR EMPLOYEE.MANAGER%TYPE := '&EMPMGR';
	EMPDEPTNO EMPLOYEE.DEPTNO%TYPE := '&EMPDEPTNO';
	EMPHIREDATE EMPLOYEE.HIREDATE%TYPE := '&EMPHIREDATE';
	EMPSAL EMPLOYEE.SALARY%TYPE := &EMPSAL;
	EMPCOMM EMPLOYEE.COMM%TYPE := &EMPCOMM;
BEGIN
    PKG.HIRE_EMP (
        EID,
        ENAME,
        EMPJOB,
        EMPMGR,
        EMPDEPTNO,
        EMPHIREDATE,
        EMPSAL,
        EMPCOMM
    );
END;

-- To call the function INC_COMM
DECLARE 
	EID EMPLOYEE.EMPID%TYPE;
	NEWCOMM EMPLOYEE.COMM%TYPE;
BEGIN
	EID := '&EID';
	NEWCOMM := &NEWCOMM;
	EID := PKG.INC_COMM(EID, NEWCOMM);

	DBMS_OUTPUT.PUT_LINE('COMMISSION OF EMPLOYEE ' || EID || ' UPDATED TO ' || NEWCOMM);
END;

-- 15a (i), (ii), (iii).
CREATE TABLE MASTER (
	ACCNO VARCHAR2(3) PRIMARY KEY,
	NAME VARCHAR2(20),
	OPEN_DATE DATE,
	BALANCE NUMBER(10, 3)
);

INSERT INTO MASTER VALUES('001', 'ARTHUR', '12-DEC-06', 3250);
INSERT INTO MASTER VALUES('002', 'MICHAEL', '02-JAN-12', 1660);
INSERT INTO MASTER VALUES('003', 'JACK', '20-JUN-09', 2275);
INSERT INTO MASTER VALUES('004', 'JOE', '19-MAR-13', 6280);

CREATE TABLE TRANSACTION (
	TACCNO VARCHAR(6),
	TAMOUNT NUMBER(10, 3),
	TDATE DATE,
	OPERATION VARCHAR2(9)
);

CREATE OR REPLACE PROCEDURE WITHDRAW (
	ACNO IN MASTER.ACCNO%TYPE,
	AMOUNT IN MASTER.BALANCE%TYPE
)
IS
BEGIN	
	UPDATE MASTER 
	SET BALANCE = BALANCE - AMOUNT
	WHERE ACCNO = ACNO;
	
	DBMS_OUTPUT.PUT_LINE('WITHDRAW SUCCESSFUL.');
END;

CREATE OR REPLACE PROCEDURE DEPOSIT (
	ACNO IN MASTER.ACCNO%TYPE,
	AMOUNT IN MASTER.BALANCE%TYPE
)
IS
BEGIN	
	UPDATE MASTER 
	SET BALANCE = BALANCE + AMOUNT
	WHERE ACCNO = ACNO;
	
	DBMS_OUTPUT.PUT_LINE('DEPOSIT SUCCESSFUL.');
END;

CREATE OR REPLACE TRIGGER CHECK_WITHDRAW 
BEFORE UPDATE ON MASTER 
FOR EACH ROW
BEGIN 
	IF (:NEW.BALANCE < 1000)
	THEN
		RAISE_APPLICATION_ERROR(-20001, 'NOT ENOUGH MINIMUM BALANCE.');
	END IF;
END;

CREATE OR REPLACE TRIGGER ADD_TRANSACTION 
AFTER UPDATE ON MASTER 
FOR EACH ROW
BEGIN 
	IF (:NEW.BALANCE - :OLD.BALANCE > 0)
	THEN
		INSERT INTO TRANSACTION
		VALUES (
			:NEW.ACCNO,
			:NEW.BALANCE - :OLD.BALANCE,
			SYSDATE,
			'DEPOSIT'
		);
	END IF;

	IF (:NEW.BALANCE - :OLD.BALANCE < 0)
	THEN
		INSERT INTO TRANSACTION
		VALUES (
			:NEW.ACCNO,
			-1 * (:NEW.BALANCE - :OLD.BALANCE),
			SYSDATE,
			'WITHDRAW'
		);
	END IF;	

	DBMS_OUTPUT.PUT_LINE('TRANSACTION RECORDED.');
END;

EXECUTE DEPOSIT('001', 700);
EXECUTE WITHDRAW('002', 500);
-- This query will cause an error (not enough minimum balance)
EXECUTE WITHDRAW('002', 1000);

-- 15b.
CREATE TABLE SUPPLIERS (
	SUPPNO VARCHAR2(6) PRIMARY KEY,
	SNAME VARCHAR2(20),
	SADDRESS VARCHAR2(20),
	SCITY VARCHAR2(20),
	SSTATE VARCHAR2(20),
	SPHONE NUMBER,
	SBALANCE NUMBER(10, 3)
);

CREATE TABLE ORDERS (
	ORDNO VARCHAR2(5),
	ORDDATE DATE,
	ORDSUPPNO VARCHAR2(9),
	ORDPARTNO VARCHAR2(9),
	ORDQTY NUMBER
);

CREATE TABLE PARTS (
	PARTNO VARCHAR2(6) PRIMARY KEY,
	PNAME VARCHAR2(20),
	QTY INTEGER,
	PRICE NUMBER
);

INSERT INTO PARTS VALUES('P001', 'P1', 310, 10);
INSERT INTO PARTS VALUES('P002', 'P2', 415, 15);
INSERT INTO PARTS VALUES('P003', 'P3', 530, 20);
INSERT INTO PARTS VALUES('P004', 'P4', 445, 20);

-- 15b (i).
CREATE OR REPLACE TRIGGER T_ORDERS
BEFORE INSERT ON ORDERS
FOR EACH ROW
BEGIN 
	IF :NEW.ORDSUPPNO = 'S002' AND :NEW.ORDQTY > 100
	THEN 
		RAISE_APPLICATION_ERROR(-20001, 'S002 CANNOT HAVE ORDERS > 100 UNITS FOR PARTS.');
	END IF;
END;

-- 15b (ii).
CREATE OR REPLACE TRIGGER SUPPL_NUM 
BEFORE INSERT ON SUPPLIERS
FOR EACH ROW
DECLARE
	S_COUNT INTEGER;
BEGIN 
	SELECT COUNT(*)
	INTO S_COUNT
	FROM SUPPLIERS
	WHERE SUPPLIERS.SCITY = :NEW.SCITY;

	IF S_COUNT > 0
	THEN
		RAISE_APPLICATION_ERROR(-20001, 'CANNOT HAVE TWO SUPPLIERS IN THE SAME CITY.');
	END IF;
END;

CREATE OR REPLACE TRIGGER S_BALANCE 
BEFORE INSERT ON ORDERS
FOR EACH ROW
DECLARE
	P_NO PARTS.PARTNO%TYPE;
	P_PRICE PARTS.PRICE%TYPE;
	P_QTY PARTS.QTY%TYPE;
	ORDER_QTY PARTS.QTY%TYPE;
	TOTAL NUMBER;
	CURR_BALANCE SUPPLIERS.SBALANCE%TYPE;
BEGIN 
	SELECT PARTNO INTO P_NO 
	FROM PARTS 
	WHERE PARTNO = :NEW.ORDPARTNO;

	SELECT PRICE INTO P_PRICE
	FROM PARTS 
	WHERE PARTNO = :NEW.ORDPARTNO;

	SELECT QTY INTO P_QTY
	FROM PARTS 
	WHERE PARTNO = :NEW.ORDPARTNO;

	SELECT SBALANCE INTO CURR_BALANCE
	FROM SUPPLIERS
	WHERE SUPPNO = :NEW.ORDSUPPNO;

	IF P_QTY < :NEW.ORDQTY
	THEN
		RAISE_APPLICATION_ERROR(-20001, 'NOT ENOUGH PARTS AVAILABLE.');
	END IF;

	IF :NEW.ORDQTY * P_PRICE > CURR_BALANCE
	THEN
		RAISE_APPLICATION_ERROR(-20001, 'NOT ENOUGH BALANCE TO PLACE ORDER.');
	END IF;
END;

INSERT INTO SUPPLIERS VALUES('S001', 'SUP1', 'AD1', 'EKM', 'KERALA', 99999, 2000);
-- This query will raise an error (two suppliers in same city)
INSERT INTO SUPPLIERS VALUES('S002', 'SUP2', 'AD2', 'EKM', 'KERALA', 99999, 5000);
INSERT INTO SUPPLIERS VALUES('S002', 'SUP2', 'AD2', 'PKD', 'KERALA', 99999, 2000);
INSERT INTO SUPPLIERS VALUES('S003', 'SUP3', 'AD3', 'TVM', 'KERALA', 87882, 3500);
INSERT INTO SUPPLIERS VALUES('S004', 'SUP4', 'AD4', 'KTM', 'KERALA', 65555, 5700);
INSERT INTO SUPPLIERS VALUES('S005', 'SUP5', 'AD5', 'KLM', 'KERALA', 99988, 4750);

INSERT INTO ORDERS VALUES('O001', '12-JAN-21', 'S001', 'P001', 20);
-- This query will raise an error (S002 ordering parts with QTY > 100)
INSERT INTO ORDERS VALUES('O002', '08-JAN-21', 'S002', 'P002', 120);
-- This query will raise an error (Not enough balance to order)
INSERT INTO ORDERS VALUES('O003', '10-DEC-20', 'S003', 'P004', 200);
INSERT INTO ORDERS VALUES('O004', '16-JUL-20', 'S004', 'P003', 65);

-- 15c.
DECLARE 
	CURSOR SAL_CUR
	IS
		SELECT EMPID, SALARY
		FROM EMPLOYEE
		WHERE SALARY < 10000 
		OR (SALARY >= 10000 AND SALARY < 30000)
		OR (SALARY >= 30000 AND SALARY < 60000);
	
	EID EMPLOYEE.EMPID%TYPE;
	SAL EMPLOYEE.SALARY%TYPE;
BEGIN
	OPEN SAL_CUR;
	LOOP
		FETCH SAL_CUR INTO EID, SAL;	
		EXIT WHEN SAL_CUR%NOTFOUND;	
		IF SAL < 10000
		THEN 
			UPDATE EMPLOYEE
			SET SALARY = 15000
			WHERE EMPID = EID;
		ELSIF SAL >= 10000 AND SAL < 30000
		THEN 
			UPDATE EMPLOYEE
			SET SALARY = 35000
			WHERE EMPID = EID;
		ELSIF SAL >= 30000 AND SAL < 60000
		THEN
			UPDATE EMPLOYEE
			SET SALARY = 65000
			WHERE EMPID = EID;
		END IF;
	END LOOP;

	DBMS_OUTPUT.PUT_LINE(SAL_CUR%ROWCOUNT || ' RECORDS UPDATED.');
END;