# Redis 초급 4번 - 키 관리 및 만료 시간 실습

## 🎯 학습 목표
- Redis 키 생성, 삭제, 이름 변경 방법 학습
- TTL(Time To Live) 설정과 활용법 이해
- 키 패턴 매칭과 검색 기법 숙달
- 메모리 관리를 위한 만료 정책 활용

## 🐳 실습 환경 준비

### Redis CLI 접속
```powershell
# Redis 컨테이너 접속
docker exec -it redis-lab redis-cli

# 연결 확인
ping
```

## 📝 이론 학습

### 키 관리의 중요성
- Redis는 키-값 저장소로 효율적인 키 관리가 성능에 직결
- 메모리 사용량 최적화를 위한 만료 시간 설정 필수
- 일관된 키 네이밍 규칙으로 유지보수성 향상

### 주요 명령어
- `EXPIRE` : 만료 시간 설정 (초)
- `TTL` : 남은 만료 시간 확인
- `PERSIST` : 만료 시간 제거
- `KEYS` : 패턴 매칭으로 키 검색
- `DEL` : 키 삭제
- `RENAME` : 키 이름 변경

## ⏰ 실습 1: 기본 만료 시간 설정

```redis
# 테스트 데이터 준비
SET session:user123 "active"
SET session:user456 "active"
SET session:user789 "active"

# 만료 시간 설정 (30초 후 삭제)
EXPIRE session:user123 30

# 다른 방법으로 만료 시간 설정
SETEX session:user999 60 "active"  # 60초 후 만료되는 키 생성

# 만료 시간 확인
TTL session:user123
TTL session:user456  # 만료 시간이 없으면 -1 반환
TTL session:user999

# 현재 값 확인
GET session:user123
GET session:user999
```

**실습 진행하기:**
```redis
# 10초 정도 기다린 후 다시 TTL 확인
TTL session:user123
# 값이 줄어들고 있는 것을 확인

# 만료 시간이 지난 후
GET session:user123  # (nil) 반환될 것
```

## 🕐 실습 2: 다양한 시간 단위 활용

```redis
# 밀리초 단위 만료 시간 설정
SET temp:data "temporary"
PEXPIRE temp:data 5000  # 5000ms = 5초

# Unix 타임스탬프로 만료 시간 설정
SET event:sale "50% 할인"
EXPIREAT event:sale 1716451200  # 특정 날짜/시간에 만료

# 현재 시간 확인 (Unix 타임스탬프)
TIME

# 밀리초 TTL 확인
PTTL temp:data
PTTL event:sale

# 만료 시간 제거 (영구 보존)
PERSIST session:user456
TTL session:user456  # -1 반환 (만료 시간 없음)
```

## 🔍 실습 3: 키 패턴 매칭과 검색

```redis
# 다양한 패턴의 테스트 데이터 생성
SET user:1:name "김철수"
SET user:1:email "kim@example.com"
SET user:2:name "이영희"
SET user:2:email "lee@example.com"
SET product:laptop:price 1200000
SET product:mouse:price 25000
SET order:2024:may:001 "주문정보1"
SET order:2024:may:002 "주문정보2"
SET cache:page:home "홈페이지 캐시"
SET cache:page:about "소개 페이지 캐시"

# 패턴 매칭으로 키 검색
KEYS user:*          # user:로 시작하는 모든 키
KEYS *:price         # :price로 끝나는 모든 키
KEYS product:*:*     # product:로 시작하고 최소 3개 구간인 키
KEYS order:2024:*    # 2024년 주문 관련 키
KEYS cache:*         # 캐시 관련 키

# 특정 문자 패턴
KEYS user:?:name     # user:1:name, user:2:name 등 매칭
KEYS user:[12]:*     # user:1:* 또는 user:2:* 매칭
```

**⚠️ 주의사항**: `KEYS` 명령어는 운영 환경에서 성능 문제를 일으킬 수 있으므로 개발/테스트 환경에서만 사용

## 🗑️ 실습 4: 키 삭제와 관리

```redis
# 단일 키 삭제
DEL temp:data

# 여러 키 한 번에 삭제
DEL user:1:email user:2:email

# 패턴으로 키 삭제 (Redis 4.0+)
# eval "return redis.call('del', unpack(redis.call('keys', 'cache:*')))" 0

# 키 존재 여부 확인
EXISTS user:1:name
EXISTS deleted:key

# 키 개수 확인
DBSIZE

# 키 이름 변경
RENAME user:1:name user:1:full_name
GET user:1:full_name

# 안전한 키 이름 변경 (대상 키가 존재하지 않을 때만)
RENAMENX user:2:name user:2:full_name
```

## 💾 실습 5: 세션 관리 시스템 구현

```redis
# 사용자 로그인 세션 생성 (30분 후 만료)
SETEX session:abc123 1800 '{"user_id": 101, "login_time": "2024-05-23T10:00:00"}'
SETEX session:def456 1800 '{"user_id": 102, "login_time": "2024-05-23T10:15:00"}'
SETEX session:ghi789 1800 '{"user_id": 103, "login_time": "2024-05-23T10:30:00"}'

# 세션 연장 (활동이 있을 때마다)
EXPIRE session:abc123 1800  # 30분 연장

# 현재 활성 세션 확인
KEYS session:*

# 세션 정보 조회
GET session:abc123

# 세션 남은 시간 확인
TTL session:abc123
TTL session:def456

# 로그아웃 (세션 즉시 삭제)
DEL session:ghi789
```

## 🛍️ 실습 6: 쇼핑몰 캐시 시스템

```redis
# 상품 정보 캐시 (10분간 유효)
SETEX cache:product:1001 600 '{"name": "노트북", "price": 1200000, "stock": 15}'
SETEX cache:product:1002 600 '{"name": "마우스", "price": 25000, "stock": 100}'

# 인기 상품 랭킹 캐시 (1시간간 유효)
SETEX cache:ranking:popular 3600 '["1001", "1002", "1003", "1004", "1005"]'

# 사용자별 추천 상품 (6시간간 유효)
SETEX cache:recommend:user101 21600 '["1001", "1005", "1010"]'
SETEX cache:recommend:user102 21600 '["1002", "1006", "1008"]'

# 캐시 상태 확인
KEYS cache:product:*
TTL cache:product:1001
TTL cache:ranking:popular

# 특정 상품 캐시 갱신 (기존 TTL은 유지하면서 값만 업데이트)
GET cache:product:1001
TTL cache:product:1001
SET cache:product:1001 '{"name": "노트북", "price": 1100000, "stock": 12}'
EXPIRE cache:product:1001 600  # TTL 재설정
```

## 📊 실습 7: 데이터 분석 및 모니터링

```redis
# 일별 방문자 수 저장 (1주일간 보관)
SETEX stats:visits:2024-05-23 604800 "15420"  # 7일 = 604800초
SETEX stats:visits:2024-05-22 604800 "14830"
SETEX stats:visits:2024-05-21 604800 "16200"

# API 호출 제한 (1시간당 1000회)
SETEX ratelimit:api:user101 3600 "1"
INCR ratelimit:api:user101
INCR ratelimit:api:user101
GET ratelimit:api:user101
TTL ratelimit:api:user101

# 임시 토큰 관리 (15분간 유효)
SETEX token:reset:abc123 900 "user101"
SETEX token:verify:def456 900 "user102"

# 통계 데이터 확인
KEYS stats:*
KEYS token:*
MGET stats:visits:2024-05-23 stats:visits:2024-05-22
```

## ✅ 실습 완료 체크리스트

- [ ] EXPIRE, SETEX로 만료 시간 설정
- [ ] TTL, PTTL으로 남은 시간 확인
- [ ] KEYS 패턴 매칭으로 키 검색
- [ ] DEL, RENAME으로 키 관리
- [ ] 세션 관리 시스템 구현
- [ ] 캐시 시스템 구현
- [ ] 다양한 시간 단위 활용

## 🤔 응용 문제

1. **이메일 인증 시스템**
   - 인증 코드를 5분간만 유효하도록 설정
   - 키 패턴: `verify:email:사용자이메일`

2. **게임 버프 시스템**
   - 다양한 지속시간의 버프 효과 관리
   - 키 패턴: `buff:user123:speed`, `buff:user123:strength`

3. **프로모션 코드 관리**
   - 할인 쿠폰의 유효기간 설정
   - 키 패턴: `coupon:SAVE20:user456`

## ⚠️ 주의사항 및 모범 사례

### 성능 최적화
```redis
# 대량 키 삭제 시 KEYS 대신 SCAN 사용 (운영 환경)
SCAN 0 MATCH cache:* COUNT 100

# 키 개수가 많을 때는 DBSIZE보다 INFO keyspace 사용
INFO keyspace
```

### 메모리 관리
```redis
# 메모리 사용량 확인
INFO memory

# 만료된 키 강제 정리
# Redis는 자동으로 만료된 키를 정리하지만, 수동으로도 가능
```

## 🔧 문제 해결

```redis
# 만료 시간 설정 실패 시 확인사항
TYPE session:user123  # 키의 타입 확인
EXISTS session:user123  # 키 존재 여부 확인

# 키가 사라지지 않는 경우
TTL session:user123  # -1이면 만료 시간 없음, -2면 키 없음

# 패턴 매칭 결과가 없는 경우
KEYS *  # 전체 키 확인으로 디버깅
```

## 💡 실무 활용 팁

1. **키 네이밍 규칙**
   - 일관된 구분자 사용 (콜론 권장)
   - 계층적 구조로 조직화
   - 너무 긴 키 이름은 메모리 낭비

2. **만료 시간 설정**
   - 캐시 데이터는 반드시 TTL 설정
   - 세션 데이터는 적절한 만료 시간 설정
   - 배치 작업 시 임시 키는 자동 정리 설정

3. **메모리 효율성**
   - 불필요한 키는 즉시 삭제
   - 대량 데이터는 적절한 만료 시간 설정
   - 정기적인 메모리 사용량 모니터링

---
**다음 단계**: 초급 5번 - Hash 데이터 타입 실습