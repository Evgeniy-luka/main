/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Ляпустин Евгений Александрович
 * Дата: 28.07.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь

SELECT
  COUNT(payer) AS total_users, -- общее количество игроков
  SUM(payer) AS total_payers, -- количество платящих (сумма единичек)
  round(AVG(payer), 2) AS payers_share -- доля платящих (среднее значение)
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
WITH pay AS (SELECT race,
COUNT(DISTINCT id)  AS pay_users -- количество платящих игроков этой расы
FROM fantasy.race r
JOIN fantasy.users u ON r.race_id=u.race_id
WHERE payer = 1
GROUP BY race
), total AS (
SELECT race,
COUNT(DISTINCT id)  AS total_users -- общее количество зарегистрированных игроков этой расы
FROM fantasy.race r
JOIN fantasy.users u ON r.race_id=u.race_id
GROUP BY race
) SELECT p.race, -- раса персонажа
pay_users,
total_users,
round((pay_users::numeric / total_users::NUMERIC), 4) AS doly_pay -- доля платящих игроков среди всех зарегистрированных игроков этой расы
FROM pay p 
LEFT JOIN total t ON p.race=t.race;

-- заимосвязи между долей платящих игроков от выбранной расы персонажа нет

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT count(amount) total_amount, -- общее количество покупок
sum(amount) sum_amount, -- суммарную стоимость всех покупок
min(amount) min_amount, -- минимальная стоимость покупки
max(amount) max_amount, -- максимальная стоимость покупки
round(avg(amount::numeric), 2) avg_amount, -- среднее значение стоимости покупки
PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY amount) AS perc, -- медиана стоимости покупки
round(STDDEV(amount::numeric), 2) st_amount -- стандартное отклонение стоимости покупки
FROM fantasy.events
WHERE amount != 0

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь

SELECT
  COUNT(CASE WHEN amount = 0 THEN 1 END) AS zero_buy, -- покупки с нулевой стоимостью
  COUNT(*) AS total_byu, -- общее количество покупок
  round(AVG(CASE WHEN amount = 0 THEN 1 ELSE 0 END), 4) AS zero_part_buy --доля покупок с нулевой стоимостью от общего количества покупок
FROM fantasy.events


-- 2.3: Популярные эпические предметы:
-- Напишите ваш запрос здесь
WITH total AS (
SELECT item_code,
count(*) AS total_item, -- Общее количество продаж сгруппированно по кодам эпического предмета
round(count(*) / (SELECT count(*)::NUMERIC FROM fantasy.events), 6) AS percentage_of_total, -- доля продажи каждого предмета от всех продаж
count(DISTINCT id) AS total_id, -- доля игроков, которые хотя бы раз покупали предмет
round(count(DISTINCT id) / (SELECT count(DISTINCT id)::NUMERIC FROM fantasy.events WHERE amount != 0), 5) AS percentage_of_total_id -- доля игроков от общего числа внутриигровых покупателей
FROM fantasy.events
WHERE amount != 0 -- исключаем покупки с нулевой стоимостью
GROUP BY item_code
)
SELECT game_items, -- название эпического предмета
total_item, -- Общее количество продаж эпического предмета сгруппированно 
percentage_of_total, -- доля продажи каждого предмета от всех продаж
total_id, -- доля игроков, которые хотя бы раз покупали предмет
percentage_of_total_id -- доля игроков от общего числа внутриигровых покупателей
FROM total t 
JOIN fantasy.items i ON t.item_code=i.item_code
ORDER BY total_item DESC



-- Часть 2. Решение ad hoc-задачbи
-- Задача: Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь

WITH registered_players_by_race AS (
    -- (1) отдельный CTE для определения количества зарегистрированных игроков
    SELECT race_id,
        count(id) AS registered_players_count 
    FROM fantasy.users
    GROUP BY race_id
), 
paying_players_by_race AS (
  --(2) CTE для определения количества внутриигровых покупателей и доли платящих
    SELECT race_id,
        count(id) AS paying_players_count, -- Количество уникальных платящих игроков
        round(avg(payer::NUMERIC), 4) AS paying_players_ratio -- Доля платящих игроков от всех зарегистрированных
    FROM fantasy.users
    WHERE id IN (SELECT id FROM fantasy.events WHERE amount != 0)
    GROUP BY race_id
), 
purchase_stats_by_race AS (
  -- (3) CTE для определения суммарного количества покупок и суммарных затрат
    SELECT race_id,
        count(e.transaction_id) AS total_purchases_count, -- Общее количество совершенных покупок
        sum(amount) AS total_spent_amount -- Общая сумма потраченных внутриигровых валютных единиц
    FROM fantasy.events e
    JOIN fantasy.users u ON e.id = u.id
    WHERE amount != 0
    GROUP BY race_id
)
SELECT race AS race_name, -- Название расы
    registered_players_count, -- Всего зарегистрировано игроков
    paying_players_count, -- Из них совершили покупки
    round(paying_players_count::NUMERIC / registered_players_count, 4) AS registration_to_paying_conversion, -- Количество платящих игроков и их доля от зарегистрированных
    paying_players_ratio, -- доля платящих игроков среди игроков, которые совершили внутриигровые покупки
    round(total_purchases_count::NUMERIC / paying_players_count, 2) AS avg_purchases_per_payer, -- Среднее количество покупок на одного игрока, совершившего внутриигровые покупки
    round(total_spent_amount::NUMERIC / total_purchases_count, 2) AS avg_purchase_value, -- средняя стоимость одной покупки на одного игрока, совершившего внутриигровые покупки
    round(total_spent_amount::NUMERIC / paying_players_count, 2) AS arppu -- средняя суммарная стоимость всех покупок на одного игрока, совершившего внутриигровые покупки
FROM fantasy.race r
LEFT JOIN registered_players_by_race ur ON r.race_id = ur.race_id
LEFT JOIN paying_players_by_race p ON ur.race_id = p.race_id
LEFT JOIN purchase_stats_by_race st ON p.race_id = st.race_id
ORDER BY registered_players_count DESC;



