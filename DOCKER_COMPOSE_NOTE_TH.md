# โน้ตอธิบาย `docker-compose.yml`

ไฟล์หลัก: `docker-compose.yml`

## ภาพรวม

สแต็กนี้ออกแบบให้รัน Laravel หลายโปรเจคพร้อมกัน โดยแชร์ฐานข้อมูล MySQL ก้อนเดียว

- Shared services: `mysql`, `phpmyadmin`
- Project services:
  - โปรเจค 1: `project1_app` + `project1_nginx`
  - โปรเจค 2: `project2_app` + `project2_nginx`

---

## 1) `name: laravel-multi`

กำหนดชื่อโปรเจคของ Docker Compose

- ใช้เป็น prefix ของ network/volume อัตโนมัติ
- ช่วยแยกทรัพยากรจาก compose โปรเจคอื่นในเครื่องเดียวกัน

---

## 2) ส่วน `x-php-service` และ `x-nginx-service` (YAML anchors)

ส่วนนี้คือ “template” เพื่อไม่ต้องเขียนซ้ำ

### `x-php-service: &php-service`

ใช้เป็นค่าพื้นฐานให้ทุก service ที่เป็น PHP app

- `build.context: .` ใช้โฟลเดอร์โปรเจคนี้เป็น build context
- `build.dockerfile: docker/php/Dockerfile` ชี้ Dockerfile ของ PHP-FPM
- `restart: unless-stopped` รีสตาร์ทอัตโนมัติถ้า container ตาย
- `networks: laravel` ให้อยู่เครือข่ายเดียวกัน
- `depends_on.mysql.condition: service_healthy` รอ MySQL พร้อมก่อนเริ่ม app

### `x-nginx-service: &nginx-service`

ใช้เป็นค่าพื้นฐานให้ทุก service ที่เป็น Nginx

- ใช้ image `nginx:1.27-alpine`
- ตั้ง `restart` และ `network` เหมือนกัน

> ตอนนำไปใช้จริงใน service จะเขียน `<<: *php-service` หรือ `<<: *nginx-service`

---

## 3) Shared service: `mysql`

ฐานข้อมูลกลางที่ทุก Laravel project ใช้ร่วมกัน

- `image: mysql:8.0`
- `container_name: mysql_shared`
- `environment` อ่านค่าจากไฟล์ `.env`
  - `MYSQL_ROOT_PASSWORD`
  - `MYSQL_DATABASE`
  - `MYSQL_USER`
  - `MYSQL_PASSWORD`
  - `TZ`
- `command` บังคับ charset/collation เป็น `utf8mb4`
- `ports: 3306:3306` เปิดให้ host ต่อ DB ได้โดยตรง
- `volumes: mysql_data:/var/lib/mysql` เก็บข้อมูลถาวร
- `healthcheck` ตรวจว่า MySQL พร้อมใช้งานจริง

---

## 4) Shared service: `phpmyadmin`

UI สำหรับจัดการฐานข้อมูลผ่านเบราว์เซอร์

- `image: phpmyadmin:5-apache`
- `depends_on mysql (service_healthy)` รอ MySQL พร้อม
- `PMA_HOST: mysql` ต่อ DB ผ่านชื่อ service ใน network เดียวกัน
- `ports: 8080:80`
  - เปิดที่ `http://localhost:8080`

---

## 5) โปรเจค 1

### `project1_app`

PHP-FPM สำหรับ Laravel โปรเจค 1

- สืบทอดจาก `*php-service`
- `working_dir: /var/www`
- bind mount โค้ด: `./projects/project1:/var/www`
- mount php config: `./docker/php/local.ini:/usr/local/etc/php/conf.d/local.ini`
- `extra_hosts: host.docker.internal:host-gateway`
  - ให้ container เรียก host machine ได้

### `project1_nginx`

เว็บเซิร์ฟเวอร์โปรเจค 1

- สืบทอดจาก `*nginx-service`
- `depends_on: project1_app`
- `ports: 8001:80`
  - เปิดที่ `http://localhost:8001`
- mount code และ nginx config ของโปรเจค 1
  - `./docker/nginx/project1.conf:/etc/nginx/conf.d/default.conf:ro`

---

## 6) โปรเจค 2

โครงสร้างเหมือนโปรเจค 1 ทุกอย่าง แต่แยกชื่อ service/path/port

- `project2_app` ใช้โค้ดจาก `./projects/project2`
- `project2_nginx` เปิดพอร์ต `8002:80`
  - ใช้งานที่ `http://localhost:8002`
- Nginx config แยกไฟล์ `project2.conf`

---

## 7) `networks` และ `volumes`

### `networks.laravel`

เครือข่ายภายในสำหรับ container ทั้งหมดในสแต็กนี้

- service คุยกันผ่านชื่อ service ได้ เช่น app ต่อ DB ด้วย host `mysql`

### `volumes.mysql_data`

volume สำหรับเก็บข้อมูล MySQL ถาวร

- ลบ/สร้าง container ใหม่แล้วข้อมูล DB ยังอยู่

---

## 8) วิธีเพิ่มโปรเจคใหม่ (เช่น project3)

1. เพิ่มโฟลเดอร์ `projects/project3`
2. คัดลอก service `project2_app` เป็น `project3_app`
3. คัดลอก service `project2_nginx` เป็น `project3_nginx`
4. เปลี่ยนพอร์ตเป็น `8003:80`
5. สร้างไฟล์ `docker/nginx/project3.conf`
6. ใน `project3.conf` ให้ `fastcgi_pass project3_app:9000;`

---

## 9) คำสั่งใช้งานบ่อย

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f project1_app
docker compose exec project1_app php artisan migrate
docker compose down
```

> ถ้าต้องการลบข้อมูล DB ด้วย ให้ใช้ `docker compose down -v`
