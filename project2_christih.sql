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

	CURSOR c2 IS SELECT Product.ProductId, ProductName, TotalStock, FirstName, LastName FROM Product
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

		dbms_output.put(CHR(13) || CHR(10)); -- New Line
		dbms_output.put_line('Out Of Stock Products');
		dbms_output.put_line(' Product ID | Product Name             | Supplier Name            | Supplier Phone Number');
		dbms_output.put_line('----------------------------------------------------------------------------------');

		for oos_query_result in c2 loop
			dbms_output.put_line(' ' || RPAD(oos_query_result.productId, 11) || '| ' || RPAD(oos_query_result.productName, 25) || '| ' || RPAD(oos_query_result.FirstName || ' ' || oos_query_result.LastName, 25) || '| ' || 'phoneNo');
		end loop;

		
	end Pro_prod_report;
	/

begin Pro_prod_report; 
end;
/
