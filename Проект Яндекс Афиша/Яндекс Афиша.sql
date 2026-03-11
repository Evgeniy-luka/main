SELECT 
    'order_id' as id_field,
    COUNT(*) as total_records,
    COUNT(DISTINCT order_id) as unique_values,
   COUNT(distinct user_id),
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT order_id) THEN 'Уникален'
        ELSE 'Есть дубликаты'
    END as status
FROM afisha.purchases;

-- Распределение заказов по возрастным ограничениям
SELECT 
    age_limit,
    COUNT(*) as orders_count
  FROM afisha.purchases
GROUP BY age_limit

-- Проверка наличия NULL значений в tickets_count
SELECT 
    'tickets_count' as field_name,
    COUNT(*) as total_records,
    COUNT(tickets_count) as non_null_records,
    COUNT(*) - COUNT(tickets_count) as null_records,
    ROUND(100.0 * COUNT(tickets_count) / COUNT(*), 2) as fill_percentage,
    ROUND(100.0 * (COUNT(*) - COUNT(tickets_count)) / COUNT(*), 2) as null_percentage
FROM afisha.purchases;

-- Популярность по типам мероприятий
SELECT 
    e.event_type_main,
    COUNT(*) as orders_count,
    SUM(p.revenue) as total_revenue,
    COUNT(DISTINCT e.event_name_code) as unique_events
FROM afisha.purchases p
JOIN afisha.events e ON p.event_id = e.event_id
GROUP BY e.event_type_main
ORDER BY orders_count DESC;


-- Проверка уникальности event_id
SELECT 
    'event_id' as id_field,
    COUNT(*) as total_records,
    COUNT(DISTINCT event_id) as unique_values,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT event_id) THEN 'Уникален'
        ELSE 'Есть дубликаты'
    END as status
FROM afisha.events;

-- Проверка уникальности venue_id
SELECT 
    'venue_id' as id_field,
    COUNT(*) as total_records,
    COUNT(DISTINCT venue_id) as unique_values,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT venue_id) THEN 'Уникален'
        ELSE 'Есть дубликаты'
    END as status
FROM afisha.venues;

-- Проверка уникальности city_id
SELECT 
    'city_id' as id_field,
    COUNT(*) as total_records,
    COUNT(DISTINCT city_id) as unique_values,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT city_id) THEN 'Уникален'
        ELSE 'Есть дубликаты'
    END as status
FROM afisha.city;

-- Проверка уникальности region_id
SELECT 
    'region_id' as id_field,
    COUNT(*) as total_records,
    COUNT(DISTINCT region_id) as unique_values,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT region_id) THEN 'Уникален'
        ELSE 'Есть дубликаты'
    END as status
FROM afisha.regions;

-- Проверка уникальных значений и пропусков в device_type_canonical
SELECT 
    'device_type_canonical' as field_name,
    COUNT(*) as total_records,
    COUNT(device_type_canonical) as non_null_records,
    COUNT(*) - COUNT(device_type_canonical) as null_records,
    COUNT(DISTINCT device_type_canonical) as unique_values,
    ROUND(100.0 * COUNT(device_type_canonical) / COUNT(*), 2) as fill_percentage
FROM afisha.purchases;

-- Распределение по типам устройств
SELECT device_type_canonical,
    COUNT(*) as orders_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 5) as percentage
FROM afisha.purchases
GROUP by device_type_canonical

-- Проверка уникальных значений и пропусков в city_name
SELECT 
    'city_name' as field_name,
    COUNT(*) as total_records,
    COUNT(city_name) as non_null_records,
    COUNT(*) - COUNT(city_name) as null_records,
    COUNT(DISTINCT city_name) as unique_values,
    ROUND(100.0 * COUNT(city_name) / COUNT(*), 2) as fill_percentage
FROM afisha.city;

-- Список всех городов (с количеством мероприятий)
SELECT 
    c.city_name,
    COUNT(DISTINCT e.event_id) as events_count,
    c.region_id
FROM afisha.city c
LEFT JOIN afisha.events e ON c.city_id = e.city_id
WHERE c.city_name IS NOT NULL
GROUP BY c.city_name, c.region_id
ORDER BY events_count DESC, c.city_name;

-- Города с NULL в названии (если есть)
SELECT * FROM afisha.city WHERE city_name IS NULL;

-- Анонимизированные названия городов (паттерн с подчеркиванием и кодом)
SELECT 
    city_name,
    COUNT(*) as count
FROM afisha.city
WHERE city_name LIKE '%\_%' ESCAPE '\'
GROUP BY city_name
ORDER BY city_name;
GROUP BY device_type_canonical
ORDER BY orders_count DESC;

-- Проверка уникальных значений и пропусков в region_name
SELECT 
    'region_name' as field_name,
    COUNT(*) as total_records,
    COUNT(region_name) as non_null_records,
    COUNT(*) - COUNT(region_name) as null_records,
    COUNT(DISTINCT region_name) as unique_values,
    ROUND(100.0 * COUNT(region_name) / COUNT(*), 2) as fill_percentage
FROM afisha.regions;

-- Список всех регионов с количеством городов
SELECT 
    r.region_name,
    COUNT(DISTINCT c.city_id) as cities_count,
    r.region_id
FROM afisha.regions r
LEFT JOIN afisha.city c ON r.region_id = c.region_id
WHERE r.region_name IS NOT NULL
GROUP BY r.region_name, r.region_id
ORDER BY cities_count DESC, r.region_name;

-- Проверка анонимизации регионов
SELECT 
    region_name,
    LENGTH(region_name) as name_length,
    CASE 
        WHEN region_name LIKE '%\_%' ESCAPE '\' THEN 'Анонимизирован'
        ELSE 'Обычное название'
    END as name_type
FROM afisha.regions
ORDER BY name_type, region_name;

-- Проверка уникальных значений и пропусков в currency_code
SELECT 
    'currency_code' as field_name,
    COUNT(*) as total_records,
    COUNT(currency_code) as non_null_records,
    COUNT(*) - COUNT(currency_code) as null_records,
    COUNT(DISTINCT currency_code) as unique_values,
    ROUND(100.0 * COUNT(currency_code) / COUNT(*), 2) as fill_percentage
FROM afisha.purchases;

-- Распределение по валютам
SELECT 
    currency_code,
    COUNT(*) as orders_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 4) as percentage,
    SUM(revenue) as total_revenue,
    ROUND(AVG(revenue), 2) as avg_revenue,
    MIN(revenue) as min_revenue,
    MAX(revenue) as max_revenue,
    COUNT(DISTINCT user_id) as unique_users
FROM afisha.purchases
WHERE currency_code IS NOT NULL
GROUP BY currency_code
ORDER BY orders_count DESC;

-- Детальный анализ заказов не в рублях
SELECT 
    currency_code,
    DATE_TRUNC('month', created_dt_msk) as month,
    COUNT(*) as orders_count,
    SUM(revenue) as total_revenue,
    SUM(tickets_count) as total_tickets
FROM afisha.purchases
WHERE currency_code != 'rub'
GROUP BY currency_code, DATE_TRUNC('month', created_dt_msk)
ORDER BY month DESC, currency_code;

-- Проверка, есть ли заказы без указания валюты
SELECT currency_code 
FROM afisha.purchases 
GROUP BY currency_code

-- Весь период данных в таблице purchases
SELECT 
    MIN(created_dt_msk) as earliest_date,
    MAX(created_dt_msk) as latest_date
FROM afisha.purchases;

-- Минимальное, максимальное и среднее значение revenue
SELECT currency_code,
    MIN(revenue) as min_revenue,
    MAX(revenue) as max_revenue,
    AVG(revenue) as avg_revenue,
    COUNT(*) as total_orders,
    COUNT(DISTINCT revenue) as unique_revenue_values
FROM afisha.purchases
GROUP by currency_code;

select service_name,
COUNT(*)
FROM afisha.purchases
GROUP by service_name

select COUNT(distinct event_id),
COUNT(distinct event_name_code)
FROM afisha.events


select COUNT(order_id),
SUM(revenue),
AVG(revenue),
AVG(tickets_count)
FROM afisha.purchases
