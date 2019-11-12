CREATE OR REPLACE FUNCTION "preparation"."import_data_fifth_level"()
  RETURNS "pg_catalog"."void" AS $BODY$
BEGIN
		/* заполнение таблицы объектов 5 уровня. времено прописан фэйковый parent_code*/
		TRUNCATE preparation.fifth_level_objects;

		INSERT INTO preparation.fifth_level_objects (
				code, 
				"name", 
				kind_short, 
				postal_code, 
				okato, 
				not_actual, 
				"level")
		SELECT 
				code, 
				"name", 
				socr, 
				"index", 
				ocatd, 
				CASE WHEN RIGHT(k.code,2) = '00' 
							THEN 0 
							ELSE 1 
				END AS not_actual, 
				5 as "level"
		FROM dbf.street AS k;

		/*обновление поля actual_code*/
		--переименованные (код 01)
		update preparation.fifth_level_objects wrong_codes
		set actual_code = right_codes.code
		from preparation.fifth_level_objects right_codes
		where (LEFT(right_codes.code,15) = LEFT(wrong_codes.code,15))
						and RIGHT(wrong_codes.code,2) !='00' 
						AND RIGHT(wrong_codes.code,2)!='51' 
						AND RIGHT(wrong_codes.code,2)!='99' 
						AND RIGHT(right_codes.code,2)='00';

		--поиск parent_code для объектов 5 уровня
		--сначала ищем parent в АКТУАЛЬНЫХ объектах 4 уровня
		update preparation.fifth_level_objects fifth_table
		set parent_code = fourth_table.code
		from preparation.fourth_level_objects fourth_table
		where left(fourth_table.code,11) = left(fifth_table.code,11) and fourth_table.not_actual = 0; --in ('00', '01', '02', '03');

		--ищем parent в АКТУАЛЬНЫХ объектах 3 уровня
		update preparation.fifth_level_objects fifth_table
		set parent_code = third_table.code
		from preparation.third_level_objects third_table
		where left(third_table.code,11) = left(fifth_table.code,11) and third_table.not_actual = 0; --in ('00', '01', '02', '03');

		--ищем parent в АКТУАЛЬНЫХ объектах 2 уровня
		update preparation.fifth_level_objects fifth_table
		set parent_code = second_table.code
		from preparation.second_level_objects second_table
		where left(second_table.code,11) = left(fifth_table.code,11) and second_table.not_actual = 0; --in ('00', '01', '02', '03');

		--ищем parent в АКТУАЛЬНЫХ объектах 1 уровня
		update preparation.fifth_level_objects fifth_table
		set parent_code = first_table.code
		from preparation.first_level_objects first_table
		where left(first_table.code,11) = left(fifth_table.code,11) and first_table.not_actual = 0; --in ('00', '01', '02', '03');

		--поиск parent_code в объектах 4 уровня с учетом кода 51
		update preparation.fifth_level_objects fifth_table
		set parent_code = fourth_table.code
		from preparation.fourth_level_objects fourth_table
		where left(fourth_table.code,11) = left(fifth_table.code,11)
						and right (fourth_table.code, 2) in ('51','99') and right (fifth_table.code, 2) in ('01', '02', '03','51', '99');--('51', '99')

		--поиск parent_code в объектах 3 уровня с учетом кода 51
		update preparation.fifth_level_objects fifth_table
		set parent_code = third_table.code
		from preparation.third_level_objects third_table
		where left(fifth_table.code,11) = left(third_table.code,11)
						and right (third_table.code, 2) in ('51','99') and right (fifth_table.code, 2) in ('01', '02', '03','51', '99');--('51', '99')

		--поиск parent_code в объектах 2 уровня с учетом кода 51
		update preparation.fifth_level_objects fifth_table
		set parent_code = second_table.code
		from preparation.second_level_objects second_table
		where left(fifth_table.code,11) = left(second_table.code,11)
						and right (second_table.code, 2) in ('51','99') and right (fifth_table.code, 2) in ('01', '02', '03','51', '99');

		--поиск parent_code в объектах 1 уровня с учетом кода 51
		update preparation.fifth_level_objects fifth_table
		set parent_code = first_table.code
		from preparation.first_level_objects first_table
		where left(fifth_table.code,11) = left(first_table.code,11)
						and right (first_table.code, 2) in ('51','99') and right (fifth_table.code, 2) in ('01', '02', '03','51', '99');
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
