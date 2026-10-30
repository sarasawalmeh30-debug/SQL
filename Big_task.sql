create table TempInstructors (
TempID INT primary key, 
TempName VARCHAR(50), 
JoinedDate DATE
)
create Table Departments (
DepartmentID INT primary key, 
DepartmentName VARCHAR(100) NOT NULL UNIQUE
)
create Table Students  (
StudentID INT primary key, 
FullName VARCHAR(100) NOT NULL, 
Email VARCHAR(100) UNIQUE, 
GPA DECIMAL(3,2), 
DepartmentID INT FOREIGN KEY References Departments
)
create Table StudentProfiles(
ProfileID INT primary key, 
StudentID INT UNIQUE FOREIGN KEY References Students, 
AddressI VARCHAR(200), 
EmergencyPhone VARCHAR(20)
)
create Table Courses (
CourseID INT primary key, 
CourseName VARCHAR(100) NOT NULL, 
Credits INT, 
DepartmentID INT FOREIGN KEY References Departments
) 
create Table StudentCourses  (
StudentID INT FOREIGN KEY References Students , 
CourseID INT FOREIGN KEY References Courses , 
EnrollmentDate DATE DEFAULT GETDATE(),
PRIMARY KEY (StudentID, CourseID)

)

alter table Students add Age INT 
drop table TempInstructors


insert into Departments 
values
(1, 'Computer Science'), 
(2, 'Software Engineering'), 
(3, 'Business Administration')

insert into Students 
values
( 101 ,  'Ali Smadi',  'ali@coursehub.com' , 3.80 ,  1 ,  22),
( 102 , 'Omar Ahmad' , 'omar@coursehub.com' , 2.90 , 1, 21),
( 103 , 'Laila Hassan' , 'laila@coursehub.com' , 3.50 , 2 , 23),
(104 , 'Tariq Zaid' , 'tariq@coursehub.com' , 2.10 , 3 , 20)

insert into StudentProfiles 
values
(1, 101, 'Amman, Jordan', '0791111111'), 
(2, 102, 'Irbid, Jordan', '0792222222'), 
(3, 103, 'Zarqa, Jordan', '0793333333')

insert into Courses 
values
(201, 'Database Systems', 3, 1), 
(202, 'Web Development', 3, 1), 
(203, 'Software Architecture', 3, 2)

insert into StudentCourses
values
(101,201),
(101,202),
(102,201),
(103,203)

update Students set GPA=2.50 where StudentID=104
delete from Students where StudentID=104


select  FullName, GPA, DepartmentName  from Students inner join Departments on 
Students.DepartmentID=Departments.DepartmentID

select DepartmentName, FullName from Departments left join Students
on Departments.DepartmentID = Students.DepartmentID

select  FullName, AddressI, EmergencyPhone from Students inner join StudentProfiles
on Students.StudentID=StudentProfiles.StudentID

select FullName, CourseName, EnrollmentDate from Students inner join StudentCourses
on Students.StudentID =StudentCourses.StudentID inner join Courses  on 
Courses.CourseID=StudentCourses.CourseID


select count(Students.StudentID) As TotalStudents ,avg(Students.GPA)As AverageGPA ,max(Students.GPA)As HighestGPA ,min(Students.GPA)As LowestGPA from Students
select DepartmentID,Avg(Students.GPA),count(Students.StudentID) from Students group by DepartmentID
select DepartmentID,avg(Students.GPA)from Students  group by DepartmentID having avg(Students.GPA)>3

select DepartmentID,count(Students.StudentID) from Students  
where  Students.GPA>=2.50 Group by DepartmentID having count(Students.StudentID)>1



create view vw_StudentAcademicDetails As 
select StudentID, FullName, GPA, DepartmentName from Students inner join Departments
on Students.DepartmentID=Departments.DepartmentID

select  FullName, GPA from Students where GPA > (select AVG(GPA) from Students)

create procedure  sp_GetStudentsByDepartment
    @DeptID INT
as
begin
    select *
    from Students
    where DepartmentID = @DeptID;
end;
