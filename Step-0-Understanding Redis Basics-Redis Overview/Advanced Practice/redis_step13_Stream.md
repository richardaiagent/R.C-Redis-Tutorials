# Redis 중급 13번 - Stream 데이터 타입 실습 교안

## 📋 학습 목표
- Redis Stream 데이터 타입의 개념과 특징 이해
- XADD, XREAD, XRANGE 등 Stream 기본 명령어 숙지
- Consumer Group을 활용한 분산 처리 구현
- 실시간 주문 처리 스트림 시스템 구축
- Stream 메시지의 영속성과 복구 메커니즘 이해
- 실무에서 활용 가능한 이벤트 스트리밍 패턴 학습

## 🔧 사전 준비사항

### 환경 확인
- Docker Desktop 실행 상태
- Redis 컨테이너 준비 (redis-persistent 사용 권장)
- VSCode PowerShell 터미널 접근 가능

### Redis 컨테이너 준비
```powershell
# 기존 컨테이너 확인
docker ps -a

# redis-persistent 컨테이너가 없다면 생성
docker run -d --name redis-persistent -p 6379:6379 -v redis-data:/data redis:7-alpine

# 컨테이너 실행 확인
docker ps

# Redis CLI 접속 테스트
docker exec -it redis-persistent redis-cli ping
```

## 📚 Redis Stream 기초 이론

### Stream이란?
Redis Stream은 **append-only 로그 데이터 구조**로, 시간순으로 정렬된 메시지들의 연속입니다. Apache Kafka와 유사한 기능을 제공하며, 다음과 같은 특징을 가집니다:

- **고유 ID**: 각 메시지는 타임스탬프 기반의 고유 ID를 가짐
- **영속성**: 메시지는 삭제되지 않고 계속 누적됨
- **Consumer Group**: 여러 소비자가 메시지를 분산해서 처리 가능
- **재처리**: 실패한 메시지를 다시 처리할 수 있음

### 주요 사용 사례
- 실시간 이벤트 스트리밍
- 주문 처리 시스템
- 로그 수집 및 모니터링
- IoT 센서 데이터 수집
- 채팅 및 알림 시스템

## 🚀 실습 1: Stream 기본 조작

### 1-1. Redis CLI 접속 및 기본 설정
```powershell
# Redis CLI 접속
docker exec -it redis-persistent redis-cli

# 기존 데이터 정리 (선택사항)
FLUSHDB
```

### 1-2. 첫 번째 Stream 생성 및 메시지 추가
```redis
# 주문 처리 스트림 생성 및 첫 메시지 추가
XADD orders * customer_id 1001 product "iPhone 15" quantity 2 price 2400000 timestamp 1684567200

# 추가 주문 메시지들 입력
XADD orders * customer_id 1002 product "Galaxy S24" quantity 1 price 1200000 timestamp 1684567260
XADD orders * customer_id 1003 product "MacBook Pro" quantity 1 price 3500000 timestamp 1684567320
XADD orders * customer_id 1001 product "AirPods Pro" quantity 1 price 350000 timestamp 1684567380
XADD orders * customer_id 1004 product "iPad Air" quantity 2 price 1600000 timestamp 1684567440

# 특정 ID로 메시지 추가 (수동 ID 지정)
XADD orders 1684567500000-0 customer_id 1005 product "Watch Series 9" quantity 1 price 600000 status "pending"
```

### 1-3. Stream 내용 확인
```redis
# 전체 메시지 조회
XRANGE orders - +

# 첫 3개 메시지만 조회
XRANGE orders - + COUNT 3

# 특정 시간 이후 메시지 조회
XRANGE orders 1684567300000 +

# 스트림 길이 확인
XLEN orders

# 스트림 정보 확인
XINFO STREAM orders
```

## 🚀 실습 2: 실시간 메시지 읽기

### 2-1. XREAD를 사용한 실시간 읽기 준비
```redis
# 현재 시점 이후의 새 메시지만 읽기 위한 준비
# 새 터미널 창을 열어서 동시 실습 진행을 위해 잠시 exit
exit
```

```powershell
# 새 PowerShell 터미널 창에서 두 번째 Redis CLI 접속
docker exec -it redis-persistent redis-cli

# 실시간 읽기 대기 (BLOCK 5000 = 5초 대기)
XREAD BLOCK 5000 STREAMS orders $
```

### 2-2. 다른 터미널에서 메시지 추가 테스트
```powershell
# 원래 터미널로 돌아가서 Redis CLI 재접속
docker exec -it redis-persistent redis-cli

# 새 메시지 추가 (다른 터미널에서 실시간으로 확인됨)
XADD orders * customer_id 1006 product "Magic Mouse" quantity 1 price 120000 status "confirmed"
XADD orders * customer_id 1007 product "Magic Keyboard" quantity 1 price 180000 status "processing"
```

### 2-3. 다중 스트림 동시 읽기
```redis
# 결제 스트림 추가 생성
XADD payments * order_id "ORD001" customer_id 1001 amount 2400000 method "card" status "completed"
XADD payments * order_id "ORD002" customer_id 1002 amount 1200000 method "bank" status "completed"

# 두 스트림을 동시에 모니터링
XREAD BLOCK 10000 STREAMS orders payments $ $
```

## 🚀 실습 3: Consumer Group 구현

### 3-1. Consumer Group 생성 및 설정
```redis
# 주문 처리를 위한 Consumer Group 생성
XGROUP CREATE orders order-processors $ MKSTREAM

# 결제 처리를 위한 Consumer Group 생성  
XGROUP CREATE payments payment-processors $ MKSTREAM

# Consumer Group 정보 확인
XINFO GROUPS orders
XINFO GROUPS payments
```

### 3-2. Consumer 시뮬레이션 - 주문 처리 워커
```redis
# Consumer 1: 주문 처리 워커
XREADGROUP GROUP order-processors worker-1 COUNT 2 STREAMS orders >

# 처리할 메시지가 있다면 ACK 처리
# 예시: XACK orders order-processors 1684567200000-0

# 미처리 메시지 확인
XPENDING orders order-processors

# 특정 Consumer의 미처리 메시지 상세 확인
XPENDING orders order-processors - + 10 worker-1
```

### 3-3. 다중 Consumer 동시 처리 시뮬레이션
```powershell
# 새 터미널에서 두 번째 워커 시뮬레이션
docker exec -it redis-persistent redis-cli
```

```redis
# Consumer 2: 또 다른 주문 처리 워커
XREADGROUP GROUP order-processors worker-2 COUNT 3 STREAMS orders >

# Consumer 정보 확인
XINFO CONSUMERS orders order-processors
```

## 🚀 실습 4: 실무 시나리오 - 전자상거래 주문 처리 시스템

### 4-1. 완벽한 주문 처리 파이프라인 구축
```redis
# 기존 데이터 정리 후 새로운 시나리오 시작
FLUSHDB

# 1단계: 주문 접수 스트림
XADD order-received * order_id "ORD-2024-001" customer_id 2001 product_name "삼성 갤럭시 북4" quantity 1 unit_price 1800000 total_amount 1800000 customer_email "kim@example.com" shipping_address "서울시 강남구" order_time "2024-05-23T10:30:00Z"

XADD order-received * order_id "ORD-2024-002" customer_id 2002 product_name "LG 그램 17인치" quantity 2 unit_price 2200000 total_amount 4400000 customer_email "lee@example.com" shipping_address "부산시 해운대구" order_time "2024-05-23T10:32:00Z"

XADD order-received * order_id "ORD-2024-003" customer_id 2003 product_name "맥북 프로 M3" quantity 1 unit_price 3500000 total_amount 3500000 customer_email "park@example.com" shipping_address "대구시 중구" order_time "2024-05-23T10:35:00Z"

# 2단계: 재고 확인 결과 스트림
XADD inventory-check * order_id "ORD-2024-001" product_name "삼성 갤럭시 북4" requested_qty 1 available_qty 15 status "available" checked_at "2024-05-23T10:30:30Z"

XADD inventory-check * order_id "ORD-2024-002" product_name "LG 그램 17인치" requested_qty 2 available_qty 8 status "available" checked_at "2024-05-23T10:32:30Z"

XADD inventory-check * order_id "ORD-2024-003" product_name "맥북 프로 M3" requested_qty 1 available_qty 0 status "out_of_stock" checked_at "2024-05-23T10:35:30Z"

# 3단계: 결제 처리 스트림
XADD payment-processing * order_id "ORD-2024-001" payment_method "credit_card" card_number "****-****-****-1234" amount 1800000 status "processing" initiated_at "2024-05-23T10:31:00Z"

XADD payment-processing * order_id "ORD-2024-002" payment_method "bank_transfer" bank_name "KB국민은행" amount 4400000 status "processing" initiated_at "2024-05-23T10:33:00Z"

# 결제 완료 결과
XADD payment-result * order_id "ORD-2024-001" transaction_id "TXN-001-2024" status "completed" amount 1800000 completed_at "2024-05-23T10:31:45Z" fee 18000

XADD payment-result * order_id "ORD-2024-002" transaction_id "TXN-002-2024" status "completed" amount 4400000 completed_at "2024-05-23T10:33:30Z" fee 44000

# 4단계: 배송 처리 스트림
XADD shipping-dispatch * order_id "ORD-2024-001" courier "CJ대한통운" tracking_number "123456789012" estimated_delivery "2024-05-25" status "dispatched" dispatched_at "2024-05-23T15:20:00Z"

XADD shipping-dispatch * order_id "ORD-2024-002" courier "한진택배" tracking_number "987654321098" estimated_delivery "2024-05-26" status "dispatched" dispatched_at "2024-05-23T15:25:00Z"
```

### 4-2. Consumer Group으로 각 단계별 처리 워커 구성
```redis
# 각 단계별 Consumer Group 생성
XGROUP CREATE order-received order-intake-team 0 MKSTREAM
XGROUP CREATE inventory-check inventory-team 0 MKSTREAM  
XGROUP CREATE payment-processing payment-team 0 MKSTREAM
XGROUP CREATE payment-result payment-result-team 0 MKSTREAM
XGROUP CREATE shipping-dispatch shipping-team 0 MKSTREAM

# 주문 접수 팀 처리
XREADGROUP GROUP order-intake-team intake-worker-1 COUNT 5 STREAMS order-received >

# 재고 확인 팀 처리
XREADGROUP GROUP inventory-team inventory-worker-1 COUNT 5 STREAMS inventory-check >

# 결제 처리 팀 처리
XREADGROUP GROUP payment-team payment-worker-1 COUNT 5 STREAMS payment-processing >

# 결제 결과 처리 팀
XREADGROUP GROUP payment-result-team result-worker-1 COUNT 5 STREAMS payment-result >

# 배송 처리 팀
XREADGROUP GROUP shipping-team shipping-worker-1 COUNT 5 STREAMS shipping-dispatch >
```

### 4-3. 전체 주문 현황 모니터링
```redis
# 각 스트림별 메시지 수 확인
XLEN order-received
XLEN inventory-check
XLEN payment-processing
XLEN payment-result
XLEN shipping-dispatch

# 특정 주문의 전체 처리 과정 추적
XRANGE order-received - + 
XRANGE inventory-check - +
XRANGE payment-result - +
XRANGE shipping-dispatch - +

# 미처리 메시지 현황 확인
XPENDING order-received order-intake-team
XPENDING inventory-check inventory-team
XPENDING payment-processing payment-team
XPENDING payment-result payment-result-team
XPENDING shipping-dispatch shipping-team
```

## 🚀 실습 5: 장애 복구 및 메시지 재처리

### 5-1. 실패한 메시지 처리 시뮬레이션
```redis
# 문제가 있는 주문 시뮬레이션
XADD order-received * order_id "ORD-2024-004" customer_id 2004 product_name "문제상품" quantity 1 unit_price 1000000 total_amount 1000000 customer_email "invalid-email" shipping_address "" order_time "2024-05-23T11:00:00Z"

# 처리 시도 (실패할 것이라 가정)
XREADGROUP GROUP order-intake-team intake-worker-1 COUNT 1 STREAMS order-received >

# 메시지를 ACK 하지 않고 방치 (실패 상황 시뮬레이션)

# 미처리 메시지 상세 확인
XPENDING order-received order-intake-team - + 10

# 특정 메시지 재처리를 위한 claim
XCLAIM order-received order-intake-team intake-worker-2 60000 1684567200000-0

# 또는 IDLE 시간 기반으로 자동 claim
XAUTOCLAIM order-received order-intake-team intake-worker-2 60000 0-0 COUNT 1
```

### 5-2. 데드 레터 큐 구현
```redis
# 처리 실패한 메시지를 별도 스트림으로 이동
XADD failed-orders * order_id "ORD-2024-004" reason "invalid_email_format" failed_at "2024-05-23T11:05:00Z" retry_count 3 original_stream "order-received"

# 실패한 주문 조회
XRANGE failed-orders - +

# 실패 통계
XLEN failed-orders
```

## 📊 실습 6: 성능 측정 및 최적화

### 6-1. Stream 성능 측정
```redis
# 메모리 사용량 확인
INFO memory

# 특정 키의 메모리 사용량 (Redis 4.0+)
MEMORY USAGE order-received
MEMORY USAGE inventory-check
MEMORY USAGE payment-processing

# 스트림 상태 요약
XINFO STREAM order-received
XINFO STREAM inventory-check
XINFO STREAM payment-processing
```

### 6-2. 대용량 데이터 시뮬레이션
```redis
# 대량 주문 데이터 생성 스크립트 시뮬레이션
# (실제로는 애플리케이션에서 처리)

# 성능 테스트를 위한 추가 데이터
XADD order-received * order_id "ORD-2024-005" customer_id 2005 product_name "테스트상품1" quantity 1 unit_price 100000 total_amount 100000
XADD order-received * order_id "ORD-2024-006" customer_id 2006 product_name "테스트상품2" quantity 2 unit_price 200000 total_amount 400000
XADD order-received * order_id "ORD-2024-007" customer_id 2007 product_name "테스트상품3" quantity 1 unit_price 300000 total_amount 300000
XADD order-received * order_id "ORD-2024-008" customer_id 2008 product_name "테스트상품4" quantity 3 unit_price 150000 total_amount 450000
XADD order-received * order_id "ORD-2024-009" customer_id 2009 product_name "테스트상품5" quantity 1 unit_price 250000 total_amount 250000

# 배치 처리 테스트
XREADGROUP GROUP order-intake-team intake-worker-batch COUNT 10 STREAMS order-received >
```

## 🔧 고급 활용법

### 7-1. Stream Trimming (메모리 관리)
```redis
# 스트림 크기 제한 (최대 1000개 메시지)
XTRIM order-received MAXLEN 1000

# 근사 크기 제한 (성능 최적화)
XTRIM order-received MAXLEN ~ 1000

# 특정 ID 이전 메시지 삭제
XDEL order-received 1684567200000-0
```

### 7-2. 복합 조건 검색 및 필터링
```redis
# 특정 고객의 모든 주문 검색 (애플리케이션 레벨에서 필터링)
XRANGE order-received - + COUNT 100

# 특정 시간 범위의 주문
XRANGE order-received 1684567200000 1684567400000

# 역순 조회
XREVRANGE order-received + - COUNT 5
```

## 🎯 실습 과제

### 과제 1: 실시간 알림 시스템
다음 요구사항을 만족하는 알림 시스템을 구현하세요:
- 주문 상태 변경 시 고객에게 알림 발송
- 재고 부족 시 관리자에게 알림
- 결제 실패 시 즉시 알림

### 과제 2: 이벤트 소싱 패턴
주문의 모든 상태 변경을 이벤트로 기록하고, 특정 시점의 주문 상태를 재구성하는 시스템을 구현하세요.

### 과제 3: 성능 최적화
1000개 이상의 메시지가 있는 상황에서 Consumer Group의 처리 성능을 최적화하세요.

## 💡 문제 해결 가이드

### 일반적인 문제들

#### 문제 1: Consumer Group 생성 실패
```redis
# 스트림이 존재하지 않는 경우
XGROUP CREATE orders order-processors $ MKSTREAM

# 이미 존재하는 Group인 경우
XGROUP DESTROY orders order-processors
XGROUP CREATE orders order-processors $
```

#### 문제 2: 메시지가 계속 PENDING 상태
```redis
# 강제로 ACK 처리
XACK orders order-processors 1684567200000-0

# 또는 Consumer Group 리셋
XGROUP SETID orders order-processors $
```

#### 문제 3: 메모리 사용량 급증
```redis
# 스트림 크기 확인
XLEN orders

# 메모리 사용량 확인
MEMORY USAGE orders

# 오래된 메시지 정리
XTRIM orders MAXLEN 1000
```

## 📈 실무 활용 패턴

### 마이크로서비스 간 이벤트 통신
```redis
# 서비스 A에서 이벤트 발행
XADD user-events * event_type "user_created" user_id 1001 email "user@example.com" created_at "2024-05-23T12:00:00Z"

# 서비스 B, C, D가 각각 Consumer Group으로 구독
XGROUP CREATE user-events email-service $ MKSTREAM
XGROUP CREATE user-events analytics-service $ MKSTREAM
XGROUP CREATE user-events recommendation-service $ MKSTREAM
```

### 로그 수집 시스템
```redis
# 애플리케이션 로그 스트림
XADD app-logs * level "ERROR" message "Database connection failed" service "order-api" timestamp "2024-05-23T12:30:00Z" trace_id "abc123"

# 로그 분석 시스템에서 소비
XREADGROUP GROUP log-analyzer analyzer-1 BLOCK 1000 STREAMS app-logs >
```

## ✅ 학습 완료 체크리스트

### 기본 개념
- [ ] Redis Stream의 특징과 용도 이해
- [ ] XADD, XREAD, XRANGE 명령어 숙지
- [ ] Stream ID 생성 규칙 이해
- [ ] 메시지 영속성 개념 파악

### Consumer Group 패턴
- [ ] Consumer Group 생성 및 관리
- [ ] 여러 Consumer 간 메시지 분산 처리
- [ ] XPENDING을 통한 미처리 메시지 추적
- [ ] XACK를 통한 메시지 확인 처리

### 실무 응용
- [ ] 실시간 주문 처리 시스템 구현
- [ ] 장애 복구 및 메시지 재처리 메커니즘
- [ ] 성능 최적화 및 메모리 관리
- [ ] 이벤트 소싱 패턴 적용

### 고급 기능
- [ ] Stream Trimming을 통한 메모리 관리
- [ ] 복합 조건 검색 및 필터링
- [ ] 마이크로서비스 이벤트 통신 패턴
- [ ] 실시간 로그 수집 시스템 구현

## 🔗 다음 단계
다음은 **중급 14번 - Geospatial 실습 (주변 매장 찾기 시스템 구현)**입니다. Stream을 통한 이벤트 스트리밍을 마스터했으니, 이제 위치 기반 서비스 구현을 학습해보겠습니다.

## 📋 요약
Redis Stream은 현대적인 이벤트 기반 아키텍처의 핵심 구성 요소입니다. 이번 실습을 통해 다음을 학습했습니다:

- **기본 조작**: XADD, XREAD, XRANGE를 통한 메시지 추가/조회
- **실시간 처리**: BLOCK 옵션을 통한 실시간 메시지 소비
- **분산 처리**: Consumer Group을 통한 메시지 분산 처리
- **장애 복구**: XPENDING, XCLAIM을 통한 실패 메시지 복구
- **실무 응용**: 전자상거래 주문 처리 파이프라인 구현

Redis Stream은 **Apache Kafka 대비 가벼우면서도 강력한 기능**을 제공하여, 중소규모 실시간 시스템에서 매우 유용합니다.

---
*본 교안은 Windows 환경의 Docker Desktop과 VSCode PowerShell을 기준으로 작성되었습니다.*