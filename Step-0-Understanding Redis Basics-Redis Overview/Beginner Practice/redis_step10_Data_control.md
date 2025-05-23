# Redis 초급 10번 - 데이터 영속성 확인 실습 교안

## 📋 학습 목표
- Redis 데이터 영속성의 중요성 이해
- Docker 볼륨을 통한 데이터 보존 방법 학습
- 컨테이너 재시작 후 데이터 유지 확인
- RDB와 AOF 백업 방식의 차이점 이해
- 실무에서 데이터 손실을 방지하는 설정 방법 습득

## 🎯 실습 시나리오
**전자상거래 시스템의 중요 데이터**를 Redis에 저장하고, 서버 재시작 상황을 시뮬레이션하여 데이터가 안전하게 보존되는지 확인합니다.

## 🔧 사전 준비사항

### 환경 확인
- Docker Desktop 실행 상태
- VSCode PowerShell 터미널 준비
- 이전 실습에서 생성된 Redis 컨테이너가 있다면 정리

```powershell
# 기존 Redis 컨테이너 정리 (있다면)
docker stop $(docker ps -q --filter "ancestor=redis:7-alpine") 2>$null
docker rm $(docker ps -aq --filter "ancestor=redis:7-alpine") 2>$null

# 환경 확인
docker --version
docker info --format "{{.Name}}: {{.ServerVersion}}"
```

## 🚀 실습 1: 볼륨 없는 Redis (데이터 손실 확인)

### 1-1. 일반 Redis 컨테이너 실행
```powershell
# 볼륨 마운트 없는 Redis 컨테이너 실행
docker run -d --name redis-temporary -p 6379:6379 redis:7-alpine

# 컨테이너 실행 확인
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 1-2. 전자상거래 데이터 입력
```powershell
# Redis CLI 접속
docker exec -it redis-temporary redis-cli

# 아래 명령들을 Redis CLI에서 실행
```

**Redis CLI 내부에서 실행할 명령들:**
```redis
# 📦 상품 정보 저장 (Hash)
HSET product:1001 name "갤럭시 S24 Ultra" price 1200000 stock 50 category "smartphone"
HSET product:1002 name "아이폰 15 Pro" price 1350000 stock 30 category "smartphone"
HSET product:1003 name "맥북 프로 M3" price 2500000 stock 15 category "laptop"

# 👤 사용자 정보 저장 (Hash)
HSET user:2001 name "김철수" email "kim@example.com" level "VIP" point 15000
HSET user:2002 name "이영희" email "lee@example.com" level "GOLD" point 8500
HSET user:2003 name "박민수" email "park@example.com" level "SILVER" point 3200

# 🛒 장바구니 정보 저장 (List)
LPUSH cart:user:2001 "product:1001:2" "product:1003:1"
LPUSH cart:user:2002 "product:1002:1" "product:1001:1"

# 📊 일일 판매량 카운터 (String)
SET daily_sales:2024-05-23 1250000
SET daily_orders:2024-05-23 89
INCR total_customers 2543

# 🏷️ 상품 태그 (Set)
SADD tags:1001 "5G" "카메라" "고성능" "삼성"
SADD tags:1002 "iOS" "카메라" "프리미엄" "애플"
SADD tags:1003 "M3칩" "개발용" "고성능" "애플"

# 🏆 베스트셀러 랭킹 (Sorted Set)
ZADD bestsellers 950 "product:1001" 1200 "product:1002" 680 "product:1003"
ZADD user_points 15000 "user:2001" 8500 "user:2002" 3200 "user:2003"

# ⏰ 할인 쿠폰 (만료시간 설정)
SET coupon:SUMMER2024 "20% 할인"
EXPIRE coupon:SUMMER2024 3600

# 💳 최근 주문 내역 (List)
RPUSH orders:recent "주문-240523-001:김철수:갤럭시S24" "주문-240523-002:이영희:아이폰15" "주문-240523-003:박민수:맥북프로"
```

### 1-3. 저장된 데이터 확인
```redis
# 전체 키 확인
KEYS *

# 카테고리별 데이터 확인
KEYS product:*
KEYS user:*
KEYS cart:*

# 상품 정보 확인
HGETALL product:1001
HGETALL user:2001

# 장바구니 확인
LRANGE cart:user:2001 0 -1

# 랭킹 확인 (높은 점수순)
ZREVRANGE bestsellers 0 -1 WITHSCORES
ZREVRANGE user_points 0 -1 WITHSCORES

# 태그 확인
SMEMBERS tags:1001

# 일일 통계 확인
GET daily_sales:2024-05-23
GET daily_orders:2024-05-23
GET total_customers

# Redis CLI 종료
exit
```

### 1-4. 데이터 손실 시뮬레이션
```powershell
# 컨테이너 중지 및 삭제
docker stop redis-temporary
docker rm redis-temporary

# 같은 이름으로 새 컨테이너 실행
docker run -d --name redis-temporary -p 6379:6379 redis:7-alpine

# 데이터 확인 (모든 데이터가 사라졌는지 확인)
docker exec -it redis-temporary redis-cli
```

```redis
# 데이터 손실 확인
KEYS *
# 결과: (empty array)

# 특정 데이터 확인 시도
HGETALL product:1001
# 결과: (empty array)

GET total_customers
# 결과: (nil)

exit
```

```powershell
# 임시 컨테이너 정리
docker stop redis-temporary
docker rm redis-temporary
```

## 🔒 실습 2: 볼륨을 사용한 영속적 Redis

### 2-1. 볼륨 생성 및 Redis 컨테이너 실행
```powershell
# 전용 볼륨 생성
docker volume create redis-ecommerce-data

# 볼륨 정보 확인
docker volume inspect redis-ecommerce-data

# 볼륨을 마운트한 Redis 컨테이너 실행
docker run -d --name redis-persistent -p 6379:6379 -v redis-ecommerce-data:/data redis:7-alpine

# 컨테이너 실행 확인
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Mounts}}"
```

### 2-2. 전자상거래 데이터 재입력
```powershell
# Redis CLI 접속
docker exec -it redis-persistent redis-cli
```

**Redis CLI에서 실행 (실습 1과 동일한 데이터):**
```redis
# 📦 상품 정보 저장
HSET product:1001 name "갤럭시 S24 Ultra" price 1200000 stock 50 category "smartphone"
HSET product:1002 name "아이폰 15 Pro" price 1350000 stock 30 category "smartphone"
HSET product:1003 name "맥북 프로 M3" price 2500000 stock 15 category "laptop"
HSET product:1004 name "에어팟 프로" price 350000 stock 100 category "accessory"
HSET product:1005 name "갤럭시 워치" price 450000 stock 75 category "wearable"

# 👤 사용자 정보 저장
HSET user:2001 name "김철수" email "kim@example.com" level "VIP" point 15000 join_date "2023-01-15"
HSET user:2002 name "이영희" email "lee@example.com" level "GOLD" point 8500 join_date "2023-03-22"
HSET user:2003 name "박민수" email "park@example.com" level "SILVER" point 3200 join_date "2023-07-10"
HSET user:2004 name "최지은" email "choi@example.com" level "BRONZE" point 1200 join_date "2024-01-05"

# 🛒 장바구니 정보 저장
LPUSH cart:user:2001 "product:1001:2" "product:1003:1" "product:1004:1"
LPUSH cart:user:2002 "product:1002:1" "product:1001:1" "product:1005:1"
LPUSH cart:user:2003 "product:1004:2" "product:1005:1"

# 📊 비즈니스 지표 저장
SET daily_sales:2024-05-23 1250000
SET daily_orders:2024-05-23 89
SET monthly_sales:2024-05 35000000
SET monthly_orders:2024-05 2654
INCR total_customers 2543
INCR total_orders 15847

# 🏷️ 상품 태그 및 카테고리
SADD tags:1001 "5G" "카메라" "고성능" "삼성" "안드로이드"
SADD tags:1002 "iOS" "카메라" "프리미엄" "애플"
SADD tags:1003 "M3칩" "개발용" "고성능" "애플" "노트북"
SADD tags:1004 "무선" "노이즈캔슬링" "애플" "이어폰"
SADD tags:1005 "웨어러블" "건강관리" "삼성" "스마트워치"

# 📈 상품별 판매량 랭킹
ZADD bestsellers 1250 "product:1001" 1100 "product:1002" 850 "product:1004" 680 "product:1003" 520 "product:1005"

# 🏅 사용자 포인트 랭킹
ZADD user_points 15000 "user:2001" 8500 "user:2002" 3200 "user:2003" 1200 "user:2004"

# 💰 할인 쿠폰 (TTL 설정)
SET coupon:SUMMER2024 "여름 특가 20% 할인"
EXPIRE coupon:SUMMER2024 7200
SET coupon:NEWBIE50 "신규 가입 50% 할인"  
EXPIRE coupon:NEWBIE50 86400

# 📋 최근 주문 내역
RPUSH orders:recent "주문-240523-001:김철수:갤럭시S24:2400000" 
RPUSH orders:recent "주문-240523-002:이영희:아이폰15:1350000"
RPUSH orders:recent "주문-240523-003:박민수:에어팟프로:350000"
RPUSH orders:recent "주문-240523-004:최지은:갤럭시워치:450000"
RPUSH orders:recent "주문-240523-005:김철수:맥북프로:2500000"

# 🔍 검색 키워드 통계
ZINCRBY search_keywords 15 "갤럭시"
ZINCRBY search_keywords 12 "아이폰"
ZINCRBY search_keywords 8 "맥북"
ZINCRBY search_keywords 6 "에어팟"
ZINCRBY search_keywords 4 "워치"

# 🎯 상품 조회수
INCR views:product:1001
INCRBY views:product:1001 24
INCRBY views:product:1002 18
INCRBY views:product:1003 12
INCRBY views:product:1004 31
INCRBY views:product:1005 19
```

### 2-3. 저장된 데이터 종합 확인
```redis
# 전체 데이터 현황 확인
KEYS *

# 상품 정보 확인
ECHO "=== 상품 정보 ==="
HGETALL product:1001
HGETALL product:1002

# 사용자 정보 확인  
ECHO "=== 사용자 정보 ==="
HGETALL user:2001
HGETALL user:2002

# 장바구니 확인
ECHO "=== 장바구니 현황 ==="
LRANGE cart:user:2001 0 -1
LRANGE cart:user:2002 0 -1

# 비즈니스 지표 확인
ECHO "=== 비즈니스 지표 ==="
GET daily_sales:2024-05-23
GET daily_orders:2024-05-23
GET total_customers
GET total_orders

# 랭킹 정보 확인
ECHO "=== 베스트셀러 랭킹 TOP 3 ==="
ZREVRANGE bestsellers 0 2 WITHSCORES

ECHO "=== 사용자 포인트 랭킹 ==="
ZREVRANGE user_points 0 -1 WITHSCORES

# 검색 키워드 통계
ECHO "=== 인기 검색어 TOP 5 ==="
ZREVRANGE search_keywords 0 4 WITHSCORES

# 상품 조회수 확인
ECHO "=== 상품 조회수 ==="
GET views:product:1001
GET views:product:1002
GET views:product:1004

# 쿠폰 확인 (만료시간 포함)
ECHO "=== 활성 쿠폰 ==="
GET coupon:SUMMER2024
TTL coupon:SUMMER2024
GET coupon:NEWBIE50
TTL coupon:NEWBIE50

# 최근 주문 내역 (최신 3건)
ECHO "=== 최근 주문 내역 ==="
LRANGE orders:recent -3 -1

exit
```

## 🔄 실습 3: 데이터 영속성 검증

### 3-1. 컨테이너 재시작 시뮬레이션
```powershell
Write-Host "=== 컨테이너 재시작 전 상태 확인 ===" -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"

Write-Host "`n=== 컨테이너 중지 ===" -ForegroundColor Red
docker stop redis-persistent

Write-Host "`n=== 컨테이너 재시작 ===" -ForegroundColor Green
docker start redis-persistent

# 재시작 완료 대기
Start-Sleep -Seconds 3

Write-Host "`n=== 재시작 후 상태 확인 ===" -ForegroundColor Green
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"
```

### 3-2. 데이터 영속성 검증
```powershell
Write-Host "`n=== 데이터 영속성 검증 시작 ===" -ForegroundColor Cyan
docker exec -it redis-persistent redis-cli
```

**Redis CLI에서 데이터 확인:**
```redis
# 🔍 전체 데이터 존재 확인
DBSIZE
ECHO "총 저장된 키 개수 확인"

# 📦 상품 데이터 검증
ECHO "=== 상품 데이터 검증 ==="
EXISTS product:1001
HGET product:1001 name
HGET product:1001 price
HLEN product:1001

EXISTS product:1003
HGETALL product:1003

# 👤 사용자 데이터 검증  
ECHO "=== 사용자 데이터 검증 ==="
EXISTS user:2001
HGET user:2001 name
HGET user:2001 level
HGET user:2001 point

# 🛒 장바구니 데이터 검증
ECHO "=== 장바구니 데이터 검증 ==="
EXISTS cart:user:2001
LLEN cart:user:2001
LRANGE cart:user:2001 0 -1

# 📊 비즈니스 지표 검증
ECHO "=== 비즈니스 지표 검증 ==="
GET daily_sales:2024-05-23
GET total_customers
GET total_orders

# 🏆 랭킹 데이터 검증
ECHO "=== 랭킹 데이터 검증 ==="
ZCARD bestsellers
ZREVRANGE bestsellers 0 2 WITHSCORES

ZCARD user_points  
ZREVRANGE user_points 0 1 WITHSCORES

# 🏷️ 태그 데이터 검증
ECHO "=== 태그 데이터 검증 ==="
SCARD tags:1001
SMEMBERS tags:1001

# 📈 검색 통계 검증
ECHO "=== 검색 통계 검증 ==="
ZCARD search_keywords
ZREVRANGE search_keywords 0 2 WITHSCORES

# 🎯 조회수 검증
ECHO "=== 조회수 검증 ==="
GET views:product:1001
GET views:product:1004

# ⏰ TTL 데이터 검증 (쿠폰)
ECHO "=== TTL 데이터 검증 ==="
EXISTS coupon:SUMMER2024
TTL coupon:SUMMER2024
EXISTS coupon:NEWBIE50
TTL coupon:NEWBIE50

# 📋 주문 내역 검증
ECHO "=== 주문 내역 검증 ==="
LLEN orders:recent
LRANGE orders:recent 0 2

exit
```

### 3-3. 추가 영속성 테스트
```powershell
Write-Host "`n=== 추가 데이터 입력 및 재검증 ===" -ForegroundColor Magenta
docker exec -it redis-persistent redis-cli
```

```redis
# 새로운 데이터 추가
ECHO "=== 새 데이터 추가 ==="
HSET product:1006 name "갤럭시 버즈" price 180000 stock 200 category "accessory"
SADD tags:1006 "무선" "컴팩트" "삼성" "이어폰"
ZADD bestsellers 95 "product:1006"

# 기존 데이터 업데이트
HINCRBY product:1001 stock -5
ZINCRBY user_points 500 "user:2001"
LPUSH orders:recent "주문-240523-006:이영희:갤럭시버즈:180000"

# 변경사항 확인
HGET product:1001 stock
ZSCORE user_points "user:2001"
LRANGE orders:recent -1 -1

exit
```

```powershell
# 한 번 더 재시작 테스트
Write-Host "`n=== 최종 재시작 테스트 ===" -ForegroundColor Yellow
docker restart redis-persistent
Start-Sleep -Seconds 3

# 최종 검증
docker exec -it redis-persistent redis-cli
```

```redis
# 최종 데이터 무결성 검증
ECHO "=== 최종 데이터 무결성 검증 ==="
DBSIZE

# 새로 추가한 데이터 확인
HGETALL product:1006
SMEMBERS tags:1006

# 업데이트된 데이터 확인  
HGET product:1001 stock
ZSCORE user_points "user:2001"
LINDEX orders:recent -1

ECHO "✅ 모든 데이터가 정상적으로 보존되었습니다!"

exit
```

## 📊 실습 4: 백업 방식 이해

### 4-1. RDB 백업 설정 확인
```powershell
docker exec -it redis-persistent redis-cli
```

```redis
# 현재 백업 설정 확인
CONFIG GET save
CONFIG GET dir
CONFIG GET dbfilename

# 수동 백업 실행
BGSAVE

# 백업 상태 확인
ECHO "마지막 백업 시간 확인"
LASTSAVE

# 백업 통계 확인
INFO persistence

exit
```

### 4-2. 백업 파일 확인
```powershell
# 컨테이너 내부의 백업 파일 확인
docker exec redis-persistent ls -la /data/

# 백업 파일 상세 정보
docker exec redis-persistent ls -lh /data/dump.rdb 2>$null || Write-Host "RDB 파일이 아직 생성되지 않았습니다."
```

### 4-3. AOF 설정 (선택사항)
```powershell
docker exec -it redis-persistent redis-cli
```

```redis
# AOF 활성화 (런타임에서)
CONFIG SET appendonly yes
CONFIG SET appendfsync everysec

# AOF 설정 확인
CONFIG GET appendonly
CONFIG GET appendfsync

# AOF 상태 확인
INFO persistence

exit
```

## 🔧 실습 5: 볼륨 관리 및 백업

### 5-1. 볼륨 정보 상세 확인
```powershell
# 볼륨 상세 정보
docker volume inspect redis-ecommerce-data

# 볼륨 사용량 확인 (Windows에서)
docker exec redis-persistent du -sh /data 2>$null || docker exec redis-persistent ls -la /data
```

### 5-2. 데이터 백업 시뮬레이션
```powershell
# 현재 상태 스냅샷
Write-Host "=== 현재 Redis 데이터 통계 ===" -ForegroundColor Green
docker exec redis-persistent redis-cli INFO keyspace

# 수동 백업 트리거
docker exec redis-persistent redis-cli BGSAVE

# 백업 완료 대기
Start-Sleep -Seconds 5

# 백업 파일 확인
docker exec redis-persistent ls -la /data/
```

## ✅ 학습 완료 검증

### 최종 검증 스크립트
```powershell
Write-Host "=== Redis 데이터 영속성 최종 검증 ===" -ForegroundColor Cyan

# 1. 컨테이너 상태 확인
Write-Host "`n1. 컨테이너 상태:" -ForegroundColor Yellow
docker ps --filter "name=redis-persistent" --format "table {{.Names}}\t{{.Status}}\t{{.Mounts}}"

# 2. 볼륨 확인
Write-Host "`n2. 볼륨 상태:" -ForegroundColor Yellow  
docker volume ls --filter "name=redis-ecommerce-data"

# 3. 데이터 개수 확인
Write-Host "`n3. 저장된 데이터 통계:" -ForegroundColor Yellow
docker exec redis-persistent redis-cli DBSIZE
docker exec redis-persistent redis-cli INFO keyspace

# 4. 핵심 데이터 샘플 확인
Write-Host "`n4. 핵심 데이터 샘플:" -ForegroundColor Yellow
docker exec redis-persistent redis-cli HGET product:1001 name
docker exec redis-persistent redis-cli HGET user:2001 name  
docker exec redis-persistent redis-cli GET total_customers

# 5. 백업 파일 확인
Write-Host "`n5. 백업 파일 상태:" -ForegroundColor Yellow
docker exec redis-persistent ls -la /data/ 2>$null

Write-Host "`n✅ 데이터 영속성 검증 완료!" -ForegroundColor Green
Write-Host "모든 데이터가 컨테이너 재시작 후에도 안전하게 보존됩니다." -ForegroundColor Green
```

## 🎯 실습 과제

### 과제 1: 재해 복구 시나리오
1. 현재 Redis 컨테이너를 완전히 삭제
2. 볼륨은 그대로 유지한 채 새 컨테이너 생성
3. 기존 데이터가 모두 복구되는지 확인

```powershell
# 과제 1 수행 명령어 (참고용)
# docker stop redis-persistent
# docker rm redis-persistent  
# docker run -d --name redis-recovered -p 6379:6379 -v redis-ecommerce-data:/data redis:7-alpine
# docker exec -it redis-recovered redis-cli KEYS "*"
```

### 과제 2: 백업 파일 추출
1. 컨테이너에서 로컬로 dump.rdb 파일 추출
2. 새로운 볼륨에 백업 파일 복사
3. 백업에서 데이터 복원 테스트

```powershell
# 과제 2 수행 명령어 (참고용)  
# docker cp redis-persistent:/data/dump.rdb ./redis-backup.rdb
# docker volume create redis-backup-test
# # 새 컨테이너에서 백업 파일 복원 테스트
```

## 💡 문제 해결 가이드

### 일반적인 문제들

#### 문제 1: 데이터가 사라짐
**원인:** 볼륨 마운트 없이 컨테이너 실행
**해결:** `-v` 옵션으로 볼륨 마운트 확인

#### 문제 2: 백업 파일이 생성되지 않음
**원인:** SAVE 설정이 비활성화됨
**해결:** `CONFIG SET save "900 1 300 10 60 10000"` 실행

#### 문제 3: 볼륨 권한 문제
**원인:** Docker Desktop 볼륨 권한 설정
**해결:** Docker Desktop 재시작 또는 볼륨 재생성

#### 문제 4: 메모리 부족으로 인한 데이터 손실
**원인:** Redis 메모리 정책 설정
**해결:** `CONFIG SET maxmemory-policy allkeys-lru` 설정

## 📚 핵심 개념 정리

### 데이터 영속성 방법
1. **RDB (Redis Database Backup)**
   - 스냅샷 방식의 백업
   - 압축된 바이너리 파일
   - 복구 속도 빠름

2. **AOF (Append Only File)**
   - 모든 쓰기 작업 로깅
   - 더 안전한 데이터 보존
   - 파일 크기가 큼

3. **볼륨 마운트**
   - Docker 컨테이너 데이터 보존
   - 컨테이너 독립적인 데이터 저장
   - 쉬운 백업 및 복원

### 실무 권장 설정
```redis
# 권장 영속성 설정
CONFIG SET save "900 1 300 10 60 10000"
CONFIG SET appendonly yes
CONFIG SET appendfsync everysec
```

## 🔗 다음 단계
다음은 **중급 1번 - Bitmap 데이터 타입 실습**입니다. 데이터 영속성을 확보했으니, 이제 더 고급 데이터 타입들을 활용한 실무 패턴을 학습해보겠습니다.

---
*본 교안은 Windows 10/11 환경의 Docker Desktop과 VSCode PowerShell 터미널을 기준으로 작성