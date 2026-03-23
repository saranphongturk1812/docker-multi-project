# Laravel + PHP + MySQL (Multi-Project Docker)

โครงนี้ออกแบบให้ **หลาย Laravel project ใช้ MySQL ก้อนเดียวกัน** ได้ โดยแยก web/app container ต่อโปรเจค

## โครงสร้าง

- `mysql` และ `phpmyadmin` เป็น shared service
- `project1_app` + `project1_nginx` สำหรับโปรเจคที่ 1 (`http://localhost:8001`)
- `project2_app` + `project2_nginx` สำหรับโปรเจคที่ 2 (`http://localhost:8002`)

## เริ่มใช้งาน

1. สร้างไฟล์ env ของ compose

```bash
cp .env.example .env
```

2. ใส่ Laravel code ลงใน

- `projects/project1`
- `projects/project2`

3. สตาร์ท container

```bash
docker compose up -d --build
```

4. ติดตั้ง dependency (ทำครั้งแรกต่อโปรเจค)

```bash
docker compose exec project1_app composer install
docker compose exec project2_app composer install
```

5. ตั้งค่า Laravel env ภายในแต่ละโปรเจค

```env
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=ชื่อฐานข้อมูลของโปรเจคนั้น
DB_USERNAME=laravel
DB_PASSWORD=secret
```

> แนะนำให้แต่ละโปรเจคใช้คนละ DB name ภายใน MySQL เดียวกัน

## สร้าง Laravel ใหม่จากโครงนี้

ตัวอย่างสร้างโปรเจคใหม่ใน `project1`:

```bash
docker compose run --rm project1_app composer create-project laravel/laravel .
docker compose exec project1_app php artisan key:generate
```

## เพิ่มโปรเจคที่ 3

1. เพิ่ม folder เช่น `projects/project3`
2. คัดลอก service `project2_app` และ `project2_nginx` ใน `docker-compose.yml`
3. เปลี่ยนชื่อ service/container เป็น `project3_*`
4. เปลี่ยน port เช่น `8003:80`
5. สร้างไฟล์ `docker/nginx/project3.conf` แล้วตั้ง `fastcgi_pass project3_app:9000;`

## เครื่องมือที่มีให้

- Laravel Project 1: `http://localhost:8001`
- Laravel Project 2: `http://localhost:8002`
- phpMyAdmin: `http://localhost:8080`
