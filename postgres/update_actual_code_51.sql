CREATE OR REPLACE FUNCTION "preparation"."update_actual_code_51"()
  RETURNS "pg_catalog"."void" AS $BODY$
/*проставление актуального кода неактуальным объектам с кодом 51*/
BEGIN
	DECLARE curs refcursor;
				cur_row RECORD;
				new_code varchar;
				old_code varchar;
				current_code varchar;
				actual varchar;
				i int;
	BEGIN
		i:=0;
		open curs for 
			select * 
			from preparation.addresses 
			where "level" in (4,5) 
					and actual_code is null 
					and not_actual = 1 
					and RIGHT(code,2) = '51' ;
					--limit 1000;
		
		loop
			FETCH curs INTO cur_row;
			EXIT WHEN NOT FOUND;
			
			IF "length"(cur_row.code) = 13 THEN
					old_code:= overlay(cur_row.code placing '00' from 12); 
			ELSE
					old_code:= overlay(cur_row.code placing '00' from 16);
			end IF;

			current_code:='0';
			-- ищем актуальный код
			loop
				select newcode into current_code
				from dbf.altnames
				where oldcode = old_code;

				if current_code !='0' THEN --если код найден, значит он не последний. заходим еще на круг
						old_code:=current_code;
				ELSE
						new_code:=old_code;	--если код не найден: current_code = null, но значения кода на предыдущем шаге сохранено в old_code
						current_code:='0';
						exit;
				end if;
			end loop;
			
			begin  --пытаемся сделать обновление. если ловим foreign_key_violation, значит такого значения в поле code нет 
							-- (объект перестал быть актуальным со времени последнего переподчинения).
				update preparation.addresses 
				set actual_code = new_code
				where code = cur_row.code;
				
				EXCEPTION WHEN foreign_key_violation THEN
					--ничего не делать
			end;

			i:=i+1;
			--raise notice '%', i;
		end loop;
	close curs;

	end;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100