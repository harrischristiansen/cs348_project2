-- CS348 Project 2 - Harris Christiansen (harrischristiansen.com)

set serveroutput on size 32000

-- Problem 1
create or replace procedure Pro_order_status as
	most_recent_order_date date;
	last_month_delayed number;
	last_month_shipped number;
	last_year_delayed number;
	last_year_shipped number;

	CURSOR c1 IS SELECT OrderId, OrderDate, Status from Orders order by OrderDate desc;
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
