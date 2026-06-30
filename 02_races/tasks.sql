-- Задача 1
-- Определяем наименьшую среднюю позицию для автомобилей в каждом классе.
-- Сначала рассчитываем среднюю позицию для каждой машины, затем ищем минимум по каждому классу, 
-- и наконец объединяем (JOIN) результаты, чтобы вывести машины, достигнувшие этого минимума.
WITH AvgPos AS (
    SELECT c.name AS car_name, c.class AS car_class, AVG(r.position) AS average_position, COUNT(r.race) AS race_count
    FROM Cars c JOIN Results r ON c.name = r.car GROUP BY c.name, c.class
),
MinAvgPos AS (
    SELECT car_class, MIN(average_position) AS min_avg_position FROM AvgPos GROUP BY car_class
)
SELECT ap.car_name, ap.car_class, ap.average_position, ap.race_count
FROM AvgPos ap JOIN MinAvgPos map ON ap.car_class = map.car_class AND ap.average_position = map.min_avg_position
ORDER BY ap.average_position ASC;

-- Задача 2
-- Поиск единственного автомобиля с наименьшей средней позицией среди абсолютно всех автомобилей.
-- Для разрешения ничьих (когда у нескольких машин одинаковая позиция) используется сортировка по имени (car_name ASC).
SELECT c.name AS car_name, c.class AS car_class, AVG(r.position) AS average_position,
       COUNT(r.race) AS race_count, cl.country AS car_country
FROM Cars c JOIN Results r ON c.name = r.car JOIN Classes cl ON c.class = cl.class
GROUP BY c.name, c.class, cl.country
ORDER BY average_position ASC, car_name ASC LIMIT 1;

-- Задача 3
-- Определение классов с наименьшей средней позицией.
-- Рассчитывается средняя позиция по всем результатам машин каждого класса. 
-- Выводятся все машины, относящиеся к классу-победителю (или классам-победителям).
WITH ClassAvg AS (
    SELECT c.class, AVG(r.position) AS class_average, COUNT(r.race) AS total_races
    FROM Cars c JOIN Results r ON c.name = r.car GROUP BY c.class
),
MinClassAvg AS ( SELECT MIN(class_average) AS min_class_average FROM ClassAvg ),
BestClasses AS (
    SELECT class, total_races FROM ClassAvg
    WHERE class_average = (SELECT min_class_average FROM MinClassAvg)
)
SELECT c.name AS car_name, c.class AS car_class,
       (SELECT AVG(position) FROM Results WHERE car = c.name) AS average_position,
       (SELECT COUNT(race) FROM Results WHERE car = c.name) AS race_count,
       cl.country AS car_country, bc.total_races
FROM Cars c JOIN Classes cl ON c.class = cl.class JOIN BestClasses bc ON c.class = bc.class;

-- Задача 4
-- Сравнение средней позиции конкретной машины со средней позицией всех машин в её классе.
-- Фильтрация оставляет только те классы, где больше одной машины (cars_in_class >= 2).
WITH ClassAvg AS (
    SELECT c.class, AVG(r.position) AS class_avg_position, COUNT(DISTINCT c.name) AS cars_in_class
    FROM Cars c JOIN Results r ON c.name = r.car GROUP BY c.class
),
CarAvg AS (
    SELECT c.name AS car_name, c.class AS car_class, AVG(r.position) AS average_position,
           COUNT(r.race) AS race_count, cl.country AS car_country
    FROM Cars c JOIN Results r ON c.name = r.car JOIN Classes cl ON c.class = cl.class
    GROUP BY c.name, c.class, cl.country
)
SELECT ca.car_name, ca.car_class, ca.average_position, ca.race_count, ca.car_country
FROM CarAvg ca JOIN ClassAvg cla ON ca.car_class = cla.class
WHERE cla.cars_in_class >= 2 AND ca.average_position < cla.class_avg_position
ORDER BY ca.car_class ASC, ca.average_position ASC;

-- Задача 5
-- Поиск классов, в которых больше всего автомобилей имеют среднюю позицию хуже (больше) 3.0.
-- Сначала определяется количество таких автомобилей в каждом классе, находится максимальное значение,
-- и выводятся все автомобили из этих "отстающих" классов.
WITH CarAvg AS (
    SELECT c.name AS car_name, c.class AS car_class, AVG(r.position) AS average_position,
           COUNT(r.race) AS race_count, cl.country AS car_country
    FROM Cars c JOIN Results r ON c.name = r.car JOIN Classes cl ON c.class = cl.class
    GROUP BY c.name, c.class, cl.country
),
ClassStats AS (
    SELECT car_class, SUM(CASE WHEN average_position > 3.0 THEN 1 ELSE 0 END) AS low_position_count, SUM(race_count) AS total_races
    FROM CarAvg GROUP BY car_class
),
MaxLowPos AS ( SELECT MAX(low_position_count) AS max_low_count FROM ClassStats )
SELECT ca.car_name, ca.car_class, ca.average_position, ca.race_count, ca.car_country, cs.total_races, cs.low_position_count
FROM CarAvg ca JOIN ClassStats cs ON ca.car_class = cs.car_class
WHERE cs.low_position_count = (SELECT max_low_count FROM MaxLowPos)
ORDER BY cs.low_position_count DESC, ca.car_name ASC;
