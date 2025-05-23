# Redis 초급 3단계: String 데이터 타입 실습 ⭐⭐⭐

## 🎯 학습 목표
Redis의 가장 기본적인 데이터 타입인 String의 다양한 명령어를 실습하고, 문자열 조작 및 숫자 연산 기능을 익힙니다.

## 📋 사전 준비사항
- Redis CLI에 접속되어 있어야 합니다
- 2단계 실습이 완료되어 있어야 합니다

---

## 🔧 기본 String 명령어 실습

### 3-1. SET/GET 기본 사용법
```bash
# Redis CLI에서 실행
127.0.0.1:6379> set product:1001 "노트북"
# 출력: OK

127.0.0.1:6379> get product:1001
# 출력: "노트북"

# 여러 키-값 동시 저장
127.0.0.1:6379> mset product:1002 "마우스" product:1003 "키보드" product:1004 "모니터"
# 출력: OK

# 여러 값 동시 조회
127.0.0.1:6379> mget product:1001 product:1002 product:1003 product:1004
# 출력:
# 1) "노트북"
# 2) "마우스"
# 3) "키보드"
# 4) "모니터"
```

### 3-2. 문자열 길이 및 존재 확인
```bash
# 문자열 길이 확인
127.0.0.1:6379> strlen product:1001
# 출력: (integer) 9  (UTF-8 바이트 길이)

# 키 존재 여부 확인
127.0.0.1:6379> exists product:1001
# 출력: (integer) 1  (존재함)

127.0.0.1:6379> exists product:9999
# 출력: (integer) 0  (존재하지 않음)
```

---

## 🔢 숫자 연산 실습

### 3-3. 숫자 저장 및 증감 연산
```bash
# 숫자 데이터 저장
127.0.0.1:6379> set price:1001 1200000
# 출력: OK

127.0.0.1:6379> set stock:1001 50
# 출력: OK

127.0.0.1:6379> set discount:1001 0.15
# 출력: OK

# 기본 조회
127.0.0.1:6379> get price:1001
# 출력: "1200000"

127.0.0.1:6379> get stock:1001
# 출력: "50"
```

### 3-4. INCR/DECR 명령어 실습
```bash
# 1씩 증가
127.0.0.1:6379> incr stock:1001
# 출력: (integer) 51

127.0.0.1:6379> incr stock:1001
# 출력: (integer) 52

# 1씩 감소
127.0.0.1:6379> decr stock:1001
# 출력: (integer) 51

# 지정한 값만큼 증가
127.0.0.1:6379> incrby price:1001 100000
# 출력: (integer) 1300000

# 지정한 값만큼 감소
127.0.0.1:6379> decrby stock:1001 10
# 출력: (integer) 41

# 실수 연산
127.0.0.1:6379> incrbyfloat discount:1001 0.05
# 출력: "0.2"
```

---

## 📝 문자열 조작 실습

### 3-5. APPEND 명령어 실습
```bash
# 기본 문자열 저장
127.0.0.1:6379> set description:1001 "고성능"
# 출력: OK

# 문자열 뒤에 추가
127.0.0.1:6379> append description:1001 " 게이밍 노트북"
# 출력: (integer) 19

127.0.0.1:6379> get description:1001
# 출력: "고성능 게이밍 노트북"

# 추가로 문자열 붙이기
127.0.0.1:6379> append description:1001 " - 최신 모델"
# 출력: (integer) 29

127.0.0.1:6379> get description:1001
# 출력: "고성능 게이밍 노트북 - 최신 모델"
```

### 3-6. GETRANGE/SETRANGE 명령어 실습
```bash
# 부분 문자열 추출
127.0.0.1:6379> getrange description:1001 0 2
# 출력: "고성능"

127.0.0.1:6379> getrange description:1001 4 9
# 출력: "게이밍 노"

# 전체 문자열 조회 (음수 인덱스 사용)
127.0.0.1:6379> getrange description:1001 0 -1
# 출력: "고성능 게이밍 노트북 - 최신 모델"

# 문자열 특정 위치 변경
127.0.0.1:6379> setrange description:1001 4 "프리미엄"
# 출력: (integer) 29

127.0.0.1:6379> get description:1001
# 출력: "고성능 프리미엄북 - 최신 모델"
```

---

## 🎮 실무 시나리오 실습

### 3-7. 전자상거래 상품 관리 시뮬레이션
```bash
# 상품 정보 저장
127.0.0.1:6379> mset product:2001:name "무선 마우스" product:2001:price 45000 product:2001:stock 100 product:2001:sold 0
# 출력: OK

# 상품 조회
127.0.0.1:6379> mget product:2001:name product:2001:price product:2001:stock product:2001:sold
# 출력:
# 1) "무선 마우스"
# 2) "45000"
# 3) "100"
# 4) "0"

# 상품 판매 시뮬레이션 (재고 감소, 판매량 증가)
127.0.0.1:6379> decr product:2001:stock
# 출력: (integer) 99

127.0.0.1:6379> incr product:2001:sold
# 출력: (integer) 1

# 대량 주문 처리
127.0.0.1:6379> decrby product:2001:stock 5
# 출력: (integer) 94

127.0.0.1:6379> incrby product:2001:sold 5
# 출력: (integer) 6

# 현재 상태 확인
127.0.0.1:6379> mget product:2001:stock product:2001:sold
# 출력:
# 1) "94"
# 2) "6"
```

### 3-8. 사용자 카운터 시뮬레이션
```bash
# 웹사이트 방문자 수 카운터
127.0.0.1:6379> set visitors:today 0
# 출력: OK

127.0.0.1:6379> set visitors:total 15420
# 출력: OK

# 방문자 증가 시뮬레이션
127.0.0.1:6379> incr visitors:today
# 출력: (integer) 1

127.0.0.1:6379> incr visitors:total
# 출력: (integer) 15421

# 페이지별 조회수
127.0.0.1:6379> mset page:home:views 0 page:products:views 0 page:about:views 0
# 출력: OK

# 여러 페이지 조회 시뮬레이션
127.0.0.1:6379> incrby page:home:views 10
# 출력: (integer) 10

127.0.0.1:6379> incrby page:products:views 25
# 출력: (integer) 25

127.0.0.1:6379> incrby page:about:views 3
# 출력: (integer) 3

# 전체 페이지 조회수 확인
127.0.0.1:6379> mget page:home:views page:products:views page:about:views
# 출력:
# 1) "10"
# 2) "25"
# 3) "3"
```

---

## 🏷️ 고급 String 명령어 실습

### 3-9. 조건부 저장 명령어
```bash
# 키가 존재하지 않을 때만 저장 (SET IF NOT EXISTS)
127.0.0.1:6379> setnx config:max_users 1000
# 출력: (integer) 1  (새로 생성됨)

127.0.0.1:6379> setnx config:max_users 2000
# 출력: (integer) 0  (이미 존재해서 저장되지 않음)

127.0.0.1:6379> get config:max_users
# 출력: "1000"

# 키가 존재할 때만 저장 (SET IF EXISTS)
127.0.0.1:6379> set config:max_users 1500 xx
# 출력: OK

127.0.0.1:6379> set config:min_users 10 xx
# 출력: (nil)  (키가 존재하지 않아서 저장되지 않음)
```

### 3-10. GETSET 명령어 실습
```bash
# 값을 조회하면서 동시에 새 값으로 변경
127.0.0.1:6379> getset config:max_users 2000
# 출력: "1500"  (이전 값 반환)

127.0.0.1:6379> get config:max_users
# 출력: "2000"  (새 값으로 변경됨)
```

---

## 📊 현재 저장된 실습 데이터 현황

실습을 완료하면 다음 데이터가 Redis에 저장되어 있어야 합니다:

### 상품 정보
| 키 | 값 |
|---|---|
| product:1001 | "노트북" |
| product:1002 | "마우스" |
| product:1003 | "키보드" |
| product:1004 | "모니터" |
| price:1001 | "1300000" |
| stock:1001 | "41" |
| discount:1001 | "0.2" |
| description:1001 | "고성능 프리미엄북 - 최신 모델" |

### 전자상거래 시뮬레이션
| 키 | 값 |
|---|---|
| product:2001:name | "무선 마우스" |
| product:2001:price | "45000" |
| product:2001:stock | "94" |
| product:2001:sold | "6" |

### 방문자 통계
| 키 | 값 |
|---|---|
| visitors:today | "1" |
| visitors:total | "15421" |
| page:home:views | "10" |
| page:products:views | "25" |
| page:about:views | "3" |