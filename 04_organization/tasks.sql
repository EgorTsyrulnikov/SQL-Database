-- Задача 1
-- Поиск всех сотрудников, находящихся в подчинении у Ивана Иванова (ID=1).
-- Используется рекурсивное обобщенное табличное выражение (WITH RECURSIVE).
-- На каждом шаге рекурсии ищутся сотрудники, чьим менеджером является сотрудник, найденный на предыдущем шаге.
-- Дополнительно используется GROUP_CONCAT для вывода всех проектов и задач сотрудника через запятую.
WITH RECURSIVE EmployeeHierarchy AS (
    SELECT EmployeeID, Name AS EmployeeName, ManagerID, DepartmentID, RoleID FROM Employees WHERE EmployeeID = 1
    UNION ALL
    SELECT e.EmployeeID, e.Name, e.ManagerID, e.DepartmentID, e.RoleID FROM Employees e INNER JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
)
SELECT eh.EmployeeID, eh.EmployeeName, eh.ManagerID, d.DepartmentName, r.RoleName,
    (SELECT GROUP_CONCAT(DISTINCT p.ProjectName ORDER BY p.ProjectName SEPARATOR ', ') FROM Projects p WHERE p.DepartmentID = eh.DepartmentID) AS ProjectNames,
    (SELECT GROUP_CONCAT(DISTINCT t.TaskName ORDER BY t.TaskName SEPARATOR ', ') FROM Tasks t WHERE t.AssignedTo = eh.EmployeeID) AS TaskNames
FROM EmployeeHierarchy eh LEFT JOIN Departments d ON eh.DepartmentID = d.DepartmentID LEFT JOIN Roles r ON eh.RoleID = r.RoleID
ORDER BY eh.EmployeeName ASC;

-- Задача 2
-- Аналогично первой задаче формируется древовидная структура подчиненных Ивана Иванова.
-- Дополнительно рассчитывается количество назначенных задач (COUNT FROM Tasks) и
-- количество прямых подчиненных (сотрудников, у которых ManagerID указывает на текущего сотрудника).
WITH RECURSIVE EmployeeHierarchy AS (
    SELECT EmployeeID, Name AS EmployeeName, ManagerID, DepartmentID, RoleID FROM Employees WHERE EmployeeID = 1
    UNION ALL
    SELECT e.EmployeeID, e.Name, e.ManagerID, e.DepartmentID, e.RoleID FROM Employees e INNER JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
)
SELECT eh.EmployeeID, eh.EmployeeName, eh.ManagerID, d.DepartmentName, r.RoleName,
    (SELECT GROUP_CONCAT(DISTINCT p.ProjectName ORDER BY p.ProjectName SEPARATOR ', ') FROM Projects p WHERE p.DepartmentID = eh.DepartmentID) AS ProjectNames,
    (SELECT GROUP_CONCAT(DISTINCT t.TaskName ORDER BY t.TaskName SEPARATOR ', ') FROM Tasks t WHERE t.AssignedTo = eh.EmployeeID) AS TaskNames,
    (SELECT COUNT(*) FROM Tasks t WHERE t.AssignedTo = eh.EmployeeID) AS TotalTasks,
    (SELECT COUNT(*) FROM Employees e2 WHERE e2.ManagerID = eh.EmployeeID) AS TotalSubordinates
FROM EmployeeHierarchy eh LEFT JOIN Departments d ON eh.DepartmentID = d.DepartmentID LEFT JOIN Roles r ON eh.RoleID = r.RoleID
ORDER BY eh.EmployeeName ASC;

-- Задача 3
-- Поиск всех менеджеров (роль "Менеджер") и рекурсивный подсчет ВСЕХ их подчиненных.
-- В рекурсивном запросе базовый случай — прямые подчиненные менеджеров,
-- шаг рекурсии — подчиненные подчиненных. В конце агрегируется количество всех найденных подчиненных.
WITH RECURSIVE SubordinateTree AS (
    SELECT e.ManagerID AS RootManagerID, e.EmployeeID AS SubordinateID
    FROM Employees e JOIN Employees m ON e.ManagerID = m.EmployeeID JOIN Roles r ON m.RoleID = r.RoleID WHERE r.RoleName = 'Менеджер'
    UNION ALL
    SELECT st.RootManagerID, e.EmployeeID
    FROM Employees e INNER JOIN SubordinateTree st ON e.ManagerID = st.SubordinateID
)
SELECT m.EmployeeID, m.Name AS EmployeeName, m.ManagerID, d.DepartmentName, r.RoleName,
    (SELECT GROUP_CONCAT(DISTINCT p.ProjectName ORDER BY p.ProjectName SEPARATOR ', ') FROM Projects p WHERE p.DepartmentID = m.DepartmentID) AS ProjectNames,
    (SELECT GROUP_CONCAT(DISTINCT t.TaskName ORDER BY t.TaskName SEPARATOR ', ') FROM Tasks t WHERE t.AssignedTo = m.EmployeeID) AS TaskNames,
    COUNT(st.SubordinateID) AS TotalSubordinates
FROM Employees m JOIN Roles r ON m.RoleID = r.RoleID
LEFT JOIN Departments d ON m.DepartmentID = d.DepartmentID LEFT JOIN SubordinateTree st ON m.EmployeeID = st.RootManagerID
WHERE r.RoleName = 'Менеджер' GROUP BY m.EmployeeID, m.Name, m.ManagerID, d.DepartmentName, r.RoleName
HAVING COUNT(st.SubordinateID) > 0 ORDER BY m.Name ASC;
