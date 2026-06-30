-- Задача 1
-- Поиск спортивных мотоциклов (тип Sport) с мощностью > 150 л.с. и ценой < 20 000 $.
-- Используется JOIN для связи характеристик мотоцикла с его производителем из таблицы Vehicle.
SELECT 
    v.maker, 
    m.model
FROM Motorcycle m
JOIN Vehicle v ON m.model = v.model
WHERE m.horsepower > 150 
  AND m.price < 20000 
  AND m.type = 'Sport'
ORDER BY m.horsepower DESC;

-- Задача 2
-- Объединение информации по трем типам транспортных средств с помощью UNION ALL.
-- Для каждого типа (Car, Motorcycle, Bicycle) применяются свои фильтры характеристик.
-- Поскольку у велосипедов нет двигателя, для мощности и объема подставляется NULL.
-- Итоговая выборка сортируется по мощности по убыванию, при этом NULL-значения (велосипеды)
-- принудительно опускаются вниз списка с помощью условия в ORDER BY.
SELECT v.maker, c.model, c.horsepower, c.engine_capacity, 'Car' AS vehicle_type
FROM Car c JOIN Vehicle v ON c.model = v.model
WHERE c.horsepower > 150 AND c.engine_capacity < 3.0 AND c.price < 35000
UNION ALL
SELECT v.maker, m.model, m.horsepower, m.engine_capacity, 'Motorcycle' AS vehicle_type
FROM Motorcycle m JOIN Vehicle v ON m.model = v.model
WHERE m.horsepower > 150 AND m.engine_capacity < 1.5 AND m.price < 20000
UNION ALL
SELECT v.maker, b.model, NULL AS horsepower, NULL AS engine_capacity, 'Bicycle' AS vehicle_type
FROM Bicycle b JOIN Vehicle v ON b.model = v.model
WHERE b.gear_count > 18 AND b.price < 4000
ORDER BY CASE WHEN horsepower IS NULL THEN 1 ELSE 0 END, horsepower DESC;
