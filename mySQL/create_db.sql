-- usage: mysql -uroot -pbitnami < create_db.sql
use mysql;
drop user if exists 'minirpg'@'localhost';
create user 'minirpg'@'localhost' identified by 'minirpg';
select User,Host from user where User='minirpg';
flush privileges; -- please don't forget to add the following command
drop database if exists minirpg;
select '' as 'show databases';
show databases;

create database minirpg;
grant all on minirpg.* to 'minirpg'@'localhost';
flush privileges;
select '' as 'show newly created databases';
show databases;