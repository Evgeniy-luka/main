-- Подсказка
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ), rang_city AS (
SELECT *, 
CASE WHEN f.city_id = '6X8I' THEN 'Санкт-Петербург'
ELSE 'ЛенОбл' END AS region, -- выделяю категории объявлений по СПб и ЛенОбл
CASE WHEN days_exposition IS NULL THEN 'active' -- незавершенные объявления
WHEN days_exposition <= 30 THEN 'month' -- до 30 дней включительно
WHEN days_exposition <= 90 THEN 'quarter' -- 31-90 дней
WHEN days_exposition <= 180 THEN 'half_year' -- 91-180 дней
ELSE 'year'  -- более 180 дней,  
END AS activity_period,
last_price / total_area AS price_area   -- Высчитываю стоимости одного квадратного метра
FROM real_estate.flats f
INNER JOIN real_estate.advertisement a using (id)
INNER JOIN filtered_id fi using (id)
WHERE type_id = 'F8EM' -- Фильтрую по подсказке и по типу город  
ORDER BY type_id)
-- Задача 1. Время активности объявлений
SELECT region, activity_period,
COUNT(*) AS listings_count,
ROUND(AVG(days_exposition::numeric), 1) AS avg_selling_time,
round(avg(price_area)::numeric, 2) AS avg_price_per_sqm,
round(avg(total_area)::numeric, 2) AS avg_total_area, 
percentile_cont(0.5) WITHIN GROUP (ORDER BY rooms) AS median_rooms, 
ROUND(MIN(price_area)::numeric, 2) AS min_price_per_sqm, 
ROUND(MAX(price_area)::numeric, 2) AS max_price_per_sqm
FROM rang_city
GROUP BY region, activity_period
ORDER BY region DESC, activity_period;





Работа по замечаниям:
1. Для соединения таблиц, в которых столбец-ключ имеет одинаковое название, стоит использовать USING вместо on. 
В теории небыло информации о using, знал про его существование 
но думал что необходимо использовать только ту информацию которую давали в теории.
Внес изменения. Спасибо
2. Добавил в INNER перед join, хотя он и так ставит его по умолчанию если не указать другой вид join.
3. Исправил наименование столбцов на английский язык
4. Вместо фильтрации WHERE id in сделал через объединение с INNER join
5. Поправил значение интервалов в activity_period, а так же добавил отдельную категорию для активных объявлений


-- Сезонность объявлений
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ), close_date AS 
(SELECT *, total_area as flat_total_area,
(first_day_exposition + days_exposition * INTERVAL '1 day')::date AS date_close  -- создаю поле дата закрытия объвления
FROM real_estate.advertisement a 
join real_estate.flats f using (id)
INNER JOIN filtered_id fi using (id)
WHERE type_id = 'F8EM'), -- Фильтрую по подсказке и по типу город 
trunc_date AS (
SELECT *, 
TO_CHAR(first_day_exposition, 'YYYY-MM') AS publication_month, -- выделяю месяц публикации объявления
TO_CHAR(date_close, 'YYYY-MM')  AS closing_month  -- выделяю месяц закрытия объявления
FROM close_date
WHERE first_day_exposition > '2015-01-01' AND date_close < '2018-12-31'),
--  Активность в публикации объявлений о продаже недвижимости
publication_stats as (
SELECT  
DENSE_RANK() OVER (ORDER BY publication_month) AS rang_start,
publication_month, 
count(*) as published_listings,
round(avg(last_price::numeric / total_area::numeric), 2) AS avg_price_start,
round(avg(total_area)::numeric, 2) AS avg_total_area_start
FROM trunc_date
GROUP BY publication_month
ORDER BY rang_start),
closing_stats as (
-- Активность по снятию объявлений о продаже недвижимости
SELECT 
DENSE_RANK() OVER (ORDER BY closing_month) AS rang_close,  -- присваиваю ранги месяцам закрытия объявлений
closing_month, 
count(*) as closed_listings,  -- -- Количество объявлений, снятых с публикации в месяц
round(avg(last_price::numeric / total_area::numeric), 2) AS avg_price_close,  -- Средняя цена за кв.м при закрытии
round(avg(flat_total_area)::numeric, 2) AS avg_total_area_close -- средний метраж снятых объявлений
FROM trunc_date
where days_exposition IS NOT NULL
GROUP BY closing_month
ORDER BY rang_close)
SELECT publication_month, -- Месяц анализа
rang_start,  -- Ранг месяца публикации
published_listings,   -- Количество размещенных объявлений
avg_price_start,   -- Средняя цена при размещении
avg_total_area_start, -- средний метраж размещенных объявлений
COALESCE(rang_close, 0) rang_close, -- Ранг месяца закрытия (или 0, если нет данных)
COALESCE(closed_listings, 0) closed_listings,    -- Количество снятых объявлений (или 0)
COALESCE(avg_price_close, 0) avg_price_close,  -- Средняя цена при закрытии (или 0)
COALESCE(avg_total_area_close, 0) avg_total_area_close --  средний метраж снятых объявлений
from publication_stats p
full join closing_stats c on p.publication_month=c.closing_month
order by publication_month;

Работа по замечаниям:
1. Исправил наименование столбцов на английский язык
2. Для категоризации месяца использовал TO_CHAR (в теории про него ни слова)))
3. Посчитал средний метраж для размещенных объявлений и средний метраж для снятых объявлений
4. изменил формулу для подсчета avg_price_close и avg_price_close на AVG(last_price/total_area)
5. Добавил фильтрацию по типу город 'F8EM' 
6. Добавил фильтрацию выбросов из подсказки
7. В СТЕ closing_stats  добавиk условие days_exposition IS NOT NULL



--Анализ рынка недвижимости Ленобласти
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
SELECT city, -- Название города
count(f.id) as total_property_listings, -- Количество объявлений в категории
round(COUNT(days_exposition)::numeric / count(f.id)::numeric, 4) as completed_sales_ratio,
round(avg(last_price::numeric), 2) as avg_last_price, -- Средняя стоимость квартиры в объявлении, в руб. 
round(avg(total_area::numeric), 2) as avg_total_area,   --  Средняя площадь квартиры, в кв. метрах.
round(avg(last_price::numeric / total_area::numeric), 2) as avg_price_per_sqm, -- расчет средней цены кв. м. по городу
round(avg(days_exposition::numeric), 1) as avg_market_days -- среднее количество дней, которое объявление находится в публикации до продажи
FROM real_estate.flats f
inner JOIN real_estate.advertisement a using (id)
inner join real_estate.city c using (city_id)
INNER JOIN filtered_id fi using (id)
WHERE f.city_id !='6X8I'
group by city
order by total_property_listings DESC
LIMIT 15;


Работа по замечаниям:
1. Вместо CASE для подсчёта снятых объявлений использовал COUNT(days_exposition)

