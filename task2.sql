Create table  AccessCards  (
	CardID INT PRIMARY KEY,
	CardNumber VARCHAR(50) NOT NULL UNIQUE,
	EmployeeID INT UNIQUE FOREIGN KEY References Employees

);
create table Projects ( 
ProjectID INT primary key,
ProjectName VARCHAR(100) NOT NULL
);
Create Table EmployeeProjects (
    AssignedDate DATE,
	EmployeeIDFK INT UNIQUE FOREIGN KEY References Employees,
	ProjectIDFK INT UNIQUE FOREIGN KEY References Employees
); 

insert into AccessCards values( 1, ' Card 101 ',1 ),( 2,'  Card 102 ',2 ),(  3,' Card 103 ',3)
insert into Projects values( 1, 'AI & Security Training' ),( 2, 'Cloud Migration')
insert into EmployeeProjects values(1, 1,null),(1, 2,null),(2, 1,null),(3, 2,null)



select FullName,Salary,DepartmentName from Employees inner join Departments 
on Employees.DepartmentID=Departments.DepartmentID


select * from Employees left join Departments 
on Employees.DepartmentID=Departments.DepartmentID

select FullName,CardNumber from Employees inner join AccessCards 
on AccessCards.EmployeeID=Employees.EmployeeID

select FullName, ProjectName, AssignedDate FROM Employees
INNER JOIN EmployeeProjects ON Employees.EmployeeID = EmployeeProjects.EmployeeIDFK
INNER JOIN Projects
ON EmployeeProjects.ProjectIDFK = Projects.ProjectID

select  Departments.DepartmentID,sum(Employees.Salary)AS TotalSalary ,count(Employees.EmployeeID)As EmployeeCount from Employees inner join Departments
on Employees.DepartmentID=Departments.DepartmentID GROUP BY Departments.DepartmentID;


select Departments.DepartmentID,avg(Employees.Salary)As AvgSalary from Departments inner join Employees on Employees.DepartmentID=Departments.DepartmentID
GROUP BY Departments.DepartmentID
having avg(Employees.Salary)>1000;

select Employees.FullName from Employees where Employees.Salary>
(select avg(Employees.Salary) from Employees)

create view vw_EmployeeDetails As
select Employees.EmployeeID,Employees.FullName,Employees.Email,Departments.DepartmentName from Employees  inner join Departments 
on Employees.DepartmentID=Departments.DepartmentID


create Trigger EmployeeAudit on Employees 
after delete as begin 
print('AFTER DELETE trigger on Employees that logs deleted employee IDs.')
end

create table EmployeeAudit (
AuditID INT primary key IDENTITY, 
EmployeeID INT, 
ActionI VARCHAR(50), 
ActionDate DATETIME
)


create procedure sp_GetEmployeesByDepartment
    @DeptID INT
AS
begin
    select *
    from Employees
    where DepartmentID = @DeptID;
end
