-- Получение статистики по заработной плате
SELECT ROUND(AVG(salary_from), 2) AS avg_salary_from,
       ROUND(AVG(salary_to), 2) AS avg_salary_to,
       MIN(salary_from) AS min_salary_from,
       MAX(salary_from) AS max_salary_from,
       MIN(salary_to) AS min_salary_to,
       MAX(salary_to) AS max_salary_to
FROM public.parcing_table;


-- Средняя зарплата в категории «от» составляет около 109525 рублей, а  
-- в категории «до» — около 153846 рублей. Это указывает на то, что работодатели готовы платить
-- аналитикам данных и системным аналитикам в среднем около 130000 рублей. 



-- Количество вакансий по регионам
SELECT area,
       COUNT(*) AS num_vacancies
FROM public.parcing_table
GROUP BY area
ORDER BY num_vacancies DESC;



-- Количество вакансий по компаниям
SELECT employer,
       COUNT(*) AS num_vacancies 
FROM public.parcing_table 
GROUP BY employer 
ORDER BY num_vacancies DESC;


-- Количество вакансий по типу занятости
SELECT employment,
       COUNT(*) AS num_vacancies
FROM public.parcing_table 
GROUP BY employment 
ORDER BY num_vacancies DESC;


-- Количество вакансий по графику работы
SELECT schedule,
       COUNT(*) AS num_vacancies 
FROM public.parcing_table 
GROUP BY schedule 
ORDER BY num_vacancies DESC;


-- Большинство вакансий (1441) предлагают работу с полным днём. 
-- Однако значительное количество вакансий (310) также позволяет удалённую работу. Это указывает на то, что работодатели готовы быть гибкими в современных условиях. Возможно, в ответ на пандемию COVID-19  и изменения в предпочтениях работников.




-- Выявление грейда требуемых специалистов по опыту
SELECT experience,
       COUNT(*) AS num_vacancies
FROM public.parcing_table 
GROUP BY experience 
ORDER BY num_vacancies DESC;


-- Наибольшее количество вакансий предназначено для специалистов с опытом от 1 до 3 лет (Junior+),  что свидетельствует о высоком спросе на специалистов начального и среднего уровней. 
-- Вакансий для Middle-специалистов (3–6 лет) также много, в то время как спрос на Senior-специалистов (6+ лет) крайне низкий, возможно, из-за узкого круга специалистов с таким уровнем опыта или предпочитаемых долгосрочных позиций.



-- Определение доли грейдов среди вакансий аналитиков

--  Сначала нужно вычислить общее количество вакансий вручную:

SELECT COUNT(*) 
FROM public.parcing_table 
WHERE name LIKE '%Аналитик данных%' 
   OR name LIKE '%аналитик данных%'
   OR name LIKE '%Системный аналитик%'
   OR name LIKE '%системный аналитик%';


-- Теперь используем это число чтобы рассчитать доли:

SELECT experience,
       COUNT(*) AS num_vacancies,
       ROUND(COUNT(*) * 100.0 / 1326, 2) AS percent_vacancies
FROM public.parcing_table
WHERE name LIKE '%Аналитик данных%' 
   OR name LIKE '%аналитик данных%'
   OR name LIKE '%Системный аналитик%'
   OR name LIKE '%системный аналитик%'
GROUP BY experience
ORDER BY percent_vacancies DESC;


-- Большинство вакансий для аналитиков данных и системных аналитиков предназначены для специалистов уровня Junior+ (64.40%) и Middle (26.02%). Это подтверждает высокую  потребность в специалистах начального и среднего уровней. 
-- Доли вакансий для стажёров (9.13%) и Senior (0.45%) значительно ниже,  что может указывать на меньшую потребность в новичках и высококвалифицированных специалистах,  но это совсем не так — тут уже надо понимать особенности рынка.   



-- Определение типичного места работы для аналитиков по различным параметрам
SELECT employer,
       COUNT(*) AS num_vacancies,
       ROUND(AVG(salary_from), 2) AS avg_salary_from,
       ROUND(AVG(salary_to), 2) AS avg_salary_to,
       employment,
       schedule
FROM public.parcing_table 
WHERE name LIKE '%Аналитик данных%' OR name LIKE '%аналитик данных%' OR name LIKE '%Системный аналитик%' OR name LIKE '%системный аналитик%'
GROUP BY employer, employment, schedule 
ORDER BY num_vacancies DESC;


-- СБЕР выделяется как основной работодатель для аналитиков данных и системных аналитиков с 117 вакансиями и средней зарплатой от 110583 рублей до 73333 рублей. 
-- Средняя зарплата «до» ниже средней зарплаты «от» — скорее всего, СБЕР часто пишет сумму «до», не указываю сумму «от». 
-- Основной тип занятости в СБЕР — полная занятость с полным рабочим днём. Значит, компания предпочитает длительное сотрудничество с сотрудниками.
-- Банк ВТБ (ПАО) и Ozon также предлагают достаточно вакансий с аналогичными условиями занятости.



SELECT key_skills_1,
       COUNT(*) AS num_mention
FROM public.parcing_table 
GROUP BY key_skills_1 
ORDER BY num_mention DESC;


-- Среди ключевых навыков чаще упоминается «Анализ данных» (312 упоминаний), 
-- что логично для позиций аналитиков данных. SQL (161 упоминание) и MS SQL (87 упоминаний) также являются
-- важными навыками, что подчёркивает важность работы с базами данных. «Документация» (89 упоминаний) 
-- указывает на необходимость ведения точных записей и отчётов. Это особенно актуально для системных аналитиков.
-- Примечательно, что в топ ключевых навыков не входит Python, однако его часто подразумевают под навыком «Анализ данных».