-- Задача 1
-- Поиск клиентов, у которых более 2-х бронирований в более чем одном уникальном отеле.
-- Для подсчета средней длительности пребывания используется разность дат DATEDIFF(выселение, заселение).
-- Названия отелей группируются в одну строку с помощью GROUP_CONCAT.
WITH CustomerStats AS (
    SELECT c.ID_customer, c.name, c.email, c.phone, COUNT(b.ID_booking) AS total_bookings, COUNT(DISTINCT h.ID_hotel) AS unique_hotels
    FROM Customer c JOIN Booking b ON c.ID_customer = b.ID_customer JOIN Room r ON b.ID_room = r.ID_room JOIN Hotel h ON r.ID_hotel = h.ID_hotel
    GROUP BY c.ID_customer, c.name, c.email, c.phone
)
SELECT cs.name, cs.email, cs.phone, cs.total_bookings,
    (SELECT GROUP_CONCAT(DISTINCT h.name ORDER BY h.name SEPARATOR ', ') FROM Booking b JOIN Room r ON b.ID_room = r.ID_room JOIN Hotel h ON r.ID_hotel = h.ID_hotel WHERE b.ID_customer = cs.ID_customer) AS hotels_list,
    (SELECT AVG(DATEDIFF(b.check_out_date, b.check_in_date)) FROM Booking b WHERE b.ID_customer = cs.ID_customer) AS avg_duration
FROM CustomerStats cs WHERE cs.total_bookings > 2 AND cs.unique_hotels > 1 ORDER BY cs.total_bookings DESC;

-- Задача 2
-- Отбор клиентов, потративших суммарно более 500$ (цена номера * количество дней) и имеющих > 2 бронирований в разных отелях.
-- Группировка производится по клиенту (ID_customer, name) с проверкой через HAVING.
SELECT c.ID_customer, c.name, COUNT(b.ID_booking) AS total_bookings, SUM(r.price * DATEDIFF(b.check_out_date, b.check_in_date)) AS total_spent, COUNT(DISTINCT h.ID_hotel) AS unique_hotels
FROM Customer c JOIN Booking b ON c.ID_customer = b.ID_customer JOIN Room r ON b.ID_room = r.ID_room JOIN Hotel h ON r.ID_hotel = h.ID_hotel
GROUP BY c.ID_customer, c.name
HAVING COUNT(b.ID_booking) > 2 AND COUNT(DISTINCT h.ID_hotel) > 1 AND SUM(r.price * DATEDIFF(b.check_out_date, b.check_in_date)) > 500
ORDER BY total_spent ASC;

-- Задача 3
-- Категоризация отелей на "Дешевый", "Средний", "Дорогой" с использованием оператора CASE.
-- Для каждого клиента формируется рейтинг предпочтений (3 - Дорогой, 2 - Средний, 1 - Дешевый).
-- Если клиент посещал отели разных категорий, ему присваивается наивысшая из них (через MAX(pref_score)).
WITH HotelCategory AS (
    SELECT ID_hotel, name AS hotel_name, AVG(price) AS avg_price,
           CASE WHEN AVG(price) > 300 THEN 'Дорогой' WHEN AVG(price) >= 175 AND AVG(price) <= 300 THEN 'Средний' ELSE 'Дешевый' END AS category
    FROM Room GROUP BY ID_hotel, name
),
CustomerHotels AS (
    SELECT c.ID_customer, c.name AS customer_name, h.category, h.hotel_name
    FROM Customer c JOIN Booking b ON c.ID_customer = b.ID_customer JOIN Room r ON b.ID_room = r.ID_room JOIN HotelCategory h ON r.ID_hotel = h.ID_hotel
),
CustomerPref AS (
    SELECT ID_customer, customer_name, MAX(CASE WHEN category = 'Дорогой' THEN 3 WHEN category = 'Средний' THEN 2 ELSE 1 END) AS pref_score
    FROM CustomerHotels GROUP BY ID_customer, customer_name
)
SELECT cp.ID_customer, cp.customer_name AS name,
       CASE WHEN cp.pref_score = 3 THEN 'Дорогой' WHEN cp.pref_score = 2 THEN 'Средний' ELSE 'Дешевый' END AS preferred_hotel_type,
       (SELECT GROUP_CONCAT(DISTINCT ch.hotel_name ORDER BY ch.hotel_name SEPARATOR ',') FROM CustomerHotels ch WHERE ch.ID_customer = cp.ID_customer) AS visited_hotels
FROM CustomerPref cp ORDER BY cp.pref_score ASC, cp.ID_customer ASC;
