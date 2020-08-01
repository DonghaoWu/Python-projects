# crewasis
Python Postgresql database

 ## Steps you need to run these code locally (Windows 10)
 These instructions will get you a copy of the project up and running on your local windows machine for development and testing purposes.
 ### Prerequirements
 - a. Python 3.7.4
 - b. PostgreSQL 12.1
1. After installing and setting python and postgres (with pgAdmin using for creating PostgreSQL Server according to http://www.postgresqltutorial.com/connect-to-postgresql-database/) on your local windows machine you can check using these commands in git bash:
 ```
 $ python -V
 $ postgres -V
 ```
 If these commands run without error and shows versions programs installed correctly
 Also now you have access to the database <postgres> reated by default usin this command in git bash:
  ```
  $ psql -U postgres postgres
  ```
  where first <postgres> is username created by default and second <postgres> is database name. Then if asked you can use password 'postgres'.
  
 2. To not be prompted for a password you need use trust authentication (which you should only use for development). For this change pg_hba.conf file, that you can find in C:\Program Files\PostgreSQL\12\data 
  ```
    IPv4 local connections:
    host    all             all             127.0.0.1/32            trust
    # IPv6 local connections:
    host    all             all             ::1/128                 trust
    # Allow replication connections from localhost, by a user with the
    # replication privilege.
    host    replication     DIMA        127.0.0.1/32            trust
    host    replication     DIMA        ::1/128                 trust
```
  And restart PostgreSQL Server in pgAdmin. In some cases you will need to create PostgreSQL Server again according to first step. To check if trust authentication try to access database 'postgres' using command above. Note that password is not required.
 
 3. Now let's set our database 'crewasis' and new role. For this run these command inside 'postgres' database:
  ```
  postgres=# create database crewasis;
  postgres=# create user <username>;
  postgres=# grant all privileges on database crewasis to <username>;
  postgres=# \q \\ for exit
  ```
  For access database crewasis from flask app by default, i.e without username, you can indicate 'username' the same what you have in your git bash console. To find out your username try to run these command from git bash:
  ```
  $ psql postgres
  ```
 You may get an error: FATAL: role 'username' does not exist. Try using this 'username' for new role name in second line. 
 Also when you are creating new user you may get an error related to encoding. If there is such an error run these command:
  ```
  postgres=# set client_encoding='utf8'
  ```
 After these settings you can restart server in pgAdmin and find new database crewasis was created.
  
### Clone, install requirements, environment variables and run
 From git bash:
 ```
 $ git clone https://github.com/ArtemAleksieiev/crewasis.git
 $ cd crewasis
 $ source venv/bin/activate
 $ pip install -r requirements.txt
 $ export FLASK_APP=microblog.py
 $ flask db upgrade
 $ flask run
 ```
 If you use different role name in PostgreSQL Server that your username in git bash before upgrading crewasis database you need to change DATABASE_URL variable in .env file:
```
DATABASE_URL="postgresql://<username>@localhost/crewasis"
```
  Now you can see app running on http://127.0.0.1:5000

 
