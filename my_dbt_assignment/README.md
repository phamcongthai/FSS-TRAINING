# my_dbt_assignment — dbt + Spark + Docker (bài tập làm quen luồng)

Bài tập ETL cơ bản dùng **dbt** chạy trên **Spark** (qua Thrift Server), gồm 3 tầng
transform: `staging -> intermediate -> marts`, có test schema và sinh docs/lineage.

Toàn bộ file trong project này đã được viết sẵn, hoàn chỉnh. Bạn chỉ cần chạy các
bước dưới đây theo đúng thứ tự — không cần sửa code.

## Cấu trúc project

```
my_dbt_assignment/
├── docker-compose.yml       # 3 service: spark-master, spark-worker, dbt
├── profiles.yml             # profile dbt, mount vào container dbt tại ~/.dbt/profiles.yml
├── README.md
└── dbt_project/
    ├── dbt_project.yml
    ├── seeds/
    │   ├── raw_orders.csv
    │   └── raw_order_items.csv
    ├── models/
    │   ├── staging/
    │   │   ├── stg_orders.sql
    │   │   ├── stg_order_items.sql
    │   │   └── schema.yml
    │   ├── intermediate/
    │   │   └── int_order_amounts.sql
    │   └── marts/
    │       ├── fct_orders.sql
    │       └── schema.yml
```

## Yêu cầu trước khi chạy

- Đã cài Docker Desktop và đang chạy.
- Mở terminal tại thư mục gốc `my_dbt_assignment/` (nơi chứa `docker-compose.yml`).

## Các bước thực hiện (theo đúng thứ tự)

### 1. Khởi động hạ tầng

```
docker-compose up -d
```

Lần đầu chạy sẽ hơi lâu vì:
- Container `spark-master` và `spark-worker` cần pull image `apache/spark:3.5.1`.
- Container `dbt` cần `apt-get install` các gói build (build-essential, libsasl2-dev,
  python3-dev) rồi `pip install dbt-core dbt-spark[PyHive]` ngay trong lệnh khởi động
  (không dùng Dockerfile, cài trực tiếp qua `command` trong docker-compose.yml).

### Bảng port (đã đổi sang dải khác để không đụng project khác đang chạy song song)

| Dịch vụ            | Port trong container | Port trên host |
|--------------------|-----------------------|-----------------|
| Spark Master UI    | 8080                  | **18080**       |
| Spark Worker UI    | 8081                  | **18081**       |
| Spark Thrift Server| 10000                 | **11000**       |
| dbt docs serve     | 8080                  | **18888**       |

**Lưu ý:** cột "Port trong container" không đổi — dbt kết nối tới `spark-master`
qua tên service trong cùng docker network (không đi qua port map ra host), nên
`profiles.yml` vẫn dùng `port: 10000`. Port `11000` trên host chỉ dùng khi bạn
muốn kết nối vào Thrift Server **từ máy host** (ví dụ dùng beeline hoặc DBeaver
cài trực tiếp trên Windows, không phải từ trong container).

### 2. Đợi Spark Thrift Server khởi động xong

Thrift Server cần một khoảng thời gian để Master + Worker + HiveThriftServer2 lên hết.
Kiểm tra bằng một trong hai cách sau:

**Cách 1 — xem log container spark-master:**

```
docker logs -f spark-master
```

Đợi đến khi thấy các dòng log dạng:
- `Master: I have been elected leader!` (Master đã lên)
- `HiveThriftServer2 started` (Thrift Server đã sẵn sàng nhận kết nối JDBC)

Nhấn `Ctrl+C` để thoát khỏi chế độ theo dõi log (không làm dừng container).

**Cách 2 — thử kết nối bằng beeline ngay trong container spark-master:**

```
docker exec -it spark-master /opt/spark/bin/beeline -u jdbc:hive2://localhost:10000
```

(Lệnh trên chạy bên trong container nên vẫn dùng port nội bộ `10000`. Nếu muốn
thử từ máy host thì dùng `jdbc:hive2://localhost:11000`.)

Nếu thấy prompt kiểu `0: jdbc:hive2://localhost:10000>` xuất hiện (không báo lỗi
connection refused) nghĩa là Thrift Server đã sẵn sàng. Gõ `!quit` để thoát.

**Lưu ý:** cũng nên kiểm tra container `dbt` đã cài xong dependencies chưa:

```
docker logs -f dbt
```

Khi log dừng lại (không còn dòng pip/apt-get nào chạy tiếp) tức là dbt-core và
dbt-spark đã cài xong và container đang ở trạng thái chờ (`tail -f /dev/null`).

### 3. Exec vào container dbt

```
docker exec -it dbt bash
```

Container đã có sẵn `working_dir: /usr/app/dbt_project`, nên sau khi exec vào bạn
đang đứng sẵn ở đúng thư mục project — không cần `cd` hay dùng `--project-dir`.

### 4. Nạp dữ liệu mẫu (seed)

```
dbt seed
```

### 5. Chạy các model (staging -> intermediate -> marts)

```
dbt run
```

### 6. Chạy test schema

```
dbt test
```

**Lưu ý quan trọng:** test `accepted_values` trên cột `status` của `fct_orders`
được kỳ vọng sẽ **FAIL** một cách có chủ đích — vì dữ liệu seed `raw_orders.csv`
có chứa một dòng `status = "cancelled"` (không nằm trong danh sách hợp lệ
`['placed', 'shipped', 'completed', 'returned']`). Đây là hành vi minh hoạ cho việc
dbt test phát hiện lỗi dữ liệu, không phải lỗi cấu hình.

### 7. Sinh docs & lineage

```
dbt docs generate
```

### 8. Xem docs

```
dbt docs serve --host 0.0.0.0 --port 8080
```

Giữ terminal này (đang exec trong container `dbt`) mở, sau đó ra trình duyệt trên
máy host và mở:

```
http://localhost:18888
```

(Cổng `18888` trên máy host đã được map sang cổng `8080` trong container `dbt` ở
`docker-compose.yml`.)

Muốn xem Spark Master UI thì mở: `http://localhost:18080`
Muốn xem Spark Worker UI thì mở: `http://localhost:18081`

## Dừng hệ thống

```
docker-compose down
```

## Ghi chú

- `dbt_project/` được mount trực tiếp vào container `dbt`, nên sửa code trong VS Code
  sẽ có hiệu lực ngay, không cần rebuild image hay khởi động lại container.
- `profiles.yml` ở thư mục gốc được mount vào container `dbt` tại
  `~/.dbt/profiles.yml`, cấu hình kết nối tới Spark Thrift Server qua
  `host: spark-master`, `port: 10000` (port nội bộ trong docker network,
  không phải port `11000` đã map ra host), `schema: analytics`.
- Nếu `dbt run`/`dbt seed` báo lỗi kết nối tới Spark, khả năng cao là Thrift Server
  chưa kịp khởi động xong — quay lại bước 2 để kiểm tra log trước khi thử lại.
