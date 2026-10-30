create table user1(
id int primary key,
nameuser varchar(50) not null,
Age int ,
Gender bit
);
create table nationldata(
National_id int primary key,
birthday date,
adderss varchar(250),
user_id int foreign key references user1(id)
);

create table Departmint (
id_departmint int primary key,
name_departmint varchar(250)
);

create table Employee (
id int primary key,
nameuser varchar(50) not null,
Age int ,
Gender bit,
Departmint_id int foreign key references Departmint(id_departmint)

);

create table studant (
id_studant int primary key,
name_studant varchar(250)
);

create table courses (
id_courses int primary key,
name_courses varchar(250)
);
create table studant_courses(
studant_id int foreign key references studant(id_studant),
courses_id int foreign key references courses(id_courses),
id_studant_courses int primary key
);

select * from user1
select * from nationldata
select * from studant
select * from courses
select * from studant_courses

insert into Employee values(1,'sara',23,1,3)
insert into Employee values(2,'Dana',23,1,3)
insert into Employee values(3,'Ahmad',50,0,null)

insert into Departmint values(1,'IT')
insert into Departmint values(2,'Marcting')
insert into Departmint values(3,'HR')

select * from Departmint
select * from Employee

create view dana As
select * from Employee inner join 
Departmint on 
Employee.Departmint_id =Departmint.id_departmint

create view sara As
select name_departmint,nameuser from Employee
inner join Departmint on 
Employee.Departmint_id =Departmint.id_departmint


select * from sara
select * from dana