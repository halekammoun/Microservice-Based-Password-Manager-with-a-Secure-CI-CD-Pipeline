# Microservice-Based-Password-Manager-with-a-Secure-CI-CD-Pipeline

* `docker compose up --build`: build + run app
* `docker compose up`: run app without rebuilding
* `docker ps`: list running docker containers
* `docker exec -it DOCKER_CONTAINER_ID /bin/bash`: access container shell (for debugging)
    * (web) `python manage.py migrate`: create tables (after each database schema change)
    * (db) `mysql -u MYSQL_USER -p MYSQL_PASSWORD`: access mysql shell
        * `mysql> show databases;`: list databases
        * `mysql> use password_manager;`: select database
        * `mysql> show tables;`: list tables in selected database   
        * `mysql> describe TABLE_NAME;`: show table structure
        * `select * from TABLE_NAME;`: show table content

> the application can be accessible from [localhost:8000](http://localhost:8000/)


<p align="center">
  <img src="high-level diagram.png" alt="high-level diagram"/>
</p>
