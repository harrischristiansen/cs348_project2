-- CS348 Project 2 - Harris Christiansen (harrischristiansen.com)

set serveroutput on size 32000

-- Problem 1
create or replace procedure Pro_order_status as
	most_recent_order_date date;
	last_month_delayed number;
	last_month_shipped number;
	last_year_delayed number;
	last_year_shipped number;

	CURSOR c1 IS SELECT OrderId, OrderDate, Status FROM Orders ORDER BY OrderDate DESC;
	order_query_result c1%rowtype;
	
	begin
		dbms_output.put_line(' DURATION  | DELAYED_ORDERS | SHIPPED_ORDERS');
		dbms_output.put_line('---------------------------------------------');

		-- Set Initial Values
		most_recent_order_date := SYSDATE;
		last_month_delayed := 0;
		last_month_shipped := 0;
		last_year_delayed := 0;
		last_year_shipped := 0;

		-- Calculate Totals
		for order_query_result in c1 loop
			IF most_recent_order_date = SYSDATE THEN -- Set most_recent_order_date to first order (by OrderDate desc)
				most_recent_order_date := order_query_result.OrderDate;
			end IF;

			-- Last Month (30 days)
			IF order_query_result.OrderDate > most_recent_order_date - 30 THEN
				IF order_query_result.Status = 'delayed' THEN
					last_month_delayed := last_month_delayed + 1;
				ELSIF order_query_result.Status = 'shipped' THEN
					last_month_shipped := last_month_shipped + 1;
				end IF;
			end IF;

			-- Last Year (365 days)
			IF order_query_result.OrderDate > most_recent_order_date - 365 THEN
				IF order_query_result.Status = 'delayed' THEN
					last_year_delayed := last_year_delayed + 1;
				ELSIF order_query_result.Status = 'shipped' THEN
					last_year_shipped := last_year_shipped + 1;
				end IF;
			end IF;
		end loop;

		dbms_output.put_line('LAST_MONTH |' || ' ' || RPAD(last_month_delayed, 15) || '| ' || last_month_shipped);
		dbms_output.put_line('LAST_YEAR  |' || ' ' || RPAD(last_year_delayed, 15) || '| ' || last_year_shipped);

		
	end Pro_order_status;
	/

begin Pro_order_status;
end;
/

-- Problem 2
create or replace procedure Pro_prod_report as
	count_available number; -- Available (TotalStock > 10)
	count_critical number; -- Critical (TotalStock <= 10)
	count_oos number; -- Out of stock (TotalStock = 0)

	CURSOR c1 IS SELECT Product.ProductId, ProductName, TotalStock FROM Product
	LEFT JOIN Inventory ON Product.ProductId=Inventory.ProductId
	ORDER BY ProductId;
	product_query_result c1%rowtype;

	CURSOR c2 IS SELECT Product.ProductId, ProductName, TotalStock, FirstName, LastName, PhoneNo FROM Product
	LEFT JOIN Inventory ON Product.ProductId=Inventory.ProductId
	LEFT JOIN Supplier ON Product.SupplierId=Supplier.SupplierId
	WHERE TotalStock = 0
	ORDER BY ProductId;
	oos_query_result c2%rowtype;
	
	begin
		dbms_output.put_line(' AVAILABLE | CRITICAL | OUT OF STOCK');
		dbms_output.put_line('--------------------------------------');

		-- Set Initial Values
		count_available := 0;
		count_critical := 0;
		count_oos := 0;

		-- Calculate Totals
		for product_query_result in c1 loop
			IF product_query_result.TotalStock = 0 THEN
				count_oos := count_oos + 1;
			ELSIF product_query_result.TotalStock <= 10 THEN
				count_critical := count_critical + 1;
			ELSIF product_query_result.TotalStock > 10 THEN
				count_available := count_available + 1;
			end IF;
		end loop;

		dbms_output.put_line(' ' || RPAD(count_available, 10) || '| ' || RPAD(count_critical, 9) || '| ' || count_oos);

		dbms_output.put(CHR(13) || CHR(10)); -- New Line, Out of Stock Product List
		dbms_output.put_line('Out Of Stock Products');
		dbms_output.put_line(' Product ID | Product Name             | Supplier Name            | Supplier Phone Number');
		dbms_output.put_line('------------------------------------------------------------------------------------------');

		for oos_query_result in c2 loop
			dbms_output.put_line(' ' || RPAD(oos_query_result.productId, 11) || '| ' || RPAD(oos_query_result.productName, 25) || '| ' || RPAD(oos_query_result.FirstName || ' ' || oos_query_result.LastName, 25) || '| ' || oos_query_result.PhoneNo);
		end loop;

		
	end Pro_prod_report;
	/

begin Pro_prod_report;
end;
/

-- Problem 3
create or replace procedure Pro_age_categ as

	CURSOR c1 IS SELECT TRUNC(Age-1, -1) AS age_bucket
	FROM Customer c
	GROUP BY TRUNC(Age-1, -1)
	ORDER BY age_bucket;
	customer_query_result c1%rowtype;

	CURSOR c2(age_in in number) IS SELECT Category, COUNT(Category) AS pop
	FROM OrderItems i
	INNER JOIN Product p ON p.ProductId=i.ProductId
	INNER JOIN Orders o ON o.OrderId=i.OrderId
	INNER JOIN Customer c ON c.CustomerId=o.CustomerId
	WHERE TRUNC(Age-1, -1) = age_in
	GROUP BY Category
	ORDER BY pop DESC
	FETCH FIRST 1 row ONLY;
	item_query_result c2%rowtype;
	
	begin
		dbms_output.put_line('Hit Categories By Age Range');
		for customer_query_result in c1 loop
			dbms_output.put(' >' || customer_query_result.age_bucket || ', <=' || (TO_NUMBER(customer_query_result.age_bucket)+10) || '        |');
		end loop;
		dbms_output.put_line(CHR(13) || CHR(10) || '-------------------------------------------------------------------------------');
		dbms_output.put(' ');
		for customer_query_result in c1 loop
			for item_query_result in c2(customer_query_result.age_bucket) loop
				dbms_output.put(RPAD(item_query_result.Category, 17) || '| ');
			end loop;
		end loop;
		dbms_output.put_line(CHR(13) || CHR(10)); -- New Line

	end Pro_age_categ;
	/

begin Pro_age_categ;
end;
/

-- Problem 4
create or replace procedure Pro_category_info as

	CURSOR c1 IS SELECT Category,
	(SELECT sum(Quantity) FROM OrderItems i INNER JOIN Product p2 on p2.ProductId=i.ProductId WHERE p2.Category = p.Category) TOTAL_UNITS
	FROM Product p
	GROUP BY Category
	ORDER BY TOTAL_UNITS DESC;
	product_query_result c1%rowtype;

	CURSOR c2(category_in in Product.Category%TYPE) IS SELECT
	sum(Quantity) as TOTAL_UNITS,
	to_char(COALESCE(avg(cast (UnitPrice as decimal(10,2))),0), 'FM$999990.00') as AVG_PRICE, -- TODO: Does not account for Quantity
	to_char(COALESCE(avg(cast (Discount as decimal(10,2))),0), 'FM$999990.00') as AVG_DISCOUNT
	FROM OrderItems i
	INNER JOIN Product p on p.ProductId=i.ProductId
	WHERE p.Category = category_in;
	item_query_result c2%rowtype;
	
	begin
		dbms_output.put_line('Category Report');
		dbms_output.put_line(' Category           | TOTAL_UNITS      | AVG_PRICE        | AVG_DISCOUNT');
		dbms_output.put_line('-------------------------------------------------------------------------');
		
		for product_query_result in c1 loop
			OPEN c2(product_query_result.Category);
			FETCH c2 INTO item_query_result;
			CLOSE c2;
			dbms_output.put_line(' ' || RPAD(product_query_result.Category, 12) || '       | ' || RPAD(item_query_result.TOTAL_UNITS, 10) || '       | ' || RPAD(item_query_result.AVG_PRICE, 10) || '       | ' || item_query_result.AVG_DISCOUNT);
		end loop;

	end Pro_category_info;
	/

begin Pro_category_info;
end;
/

-- Problem 5
create or replace procedure Pro_search_customer(input_id in number) as

	CURSOR c1(customer_id in number) IS SELECT FirstName, LastName, Age, PhoneNo,
	(select count(*) FROM Orders o WHERE o.CustomerId = c.CustomerId) NUM_ORDERS
	FROM Customer c
	WHERE CustomerId = customer_id;
	customer_query_result c1%rowtype;
	
	begin
		OPEN c1(input_id);
		FETCH c1 INTO customer_query_result;
		CLOSE c1;
		IF customer_query_result.FirstName IS NULL THEN
			dbms_output.put_line('Customer with id ' || input_id || ' not found.');
		ELSE
			dbms_output.put_line('Customer Name: ' || customer_query_result.FirstName || ' ' || customer_query_result.LastName);
			dbms_output.put_line('Customer Age: ' || customer_query_result.Age);
			dbms_output.put_line('Customer Phone No: ' || customer_query_result.PhoneNo);
			dbms_output.put_line('Number of Orders Placed: ' || customer_query_result.NUM_ORDERS);
		end IF;

	end Pro_search_customer;
	/

accept x number prompt 'Enter CustomerID:';
begin Pro_search_customer(&x);
end;
/
