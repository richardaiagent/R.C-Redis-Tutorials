# Redis 초급 5번 - Hash 데이터 타입 실습 교안

## 📋 학습 목표
- Redis Hash 데이터 타입의 개념과 특징 이해
- Hash 관련 주요 명령어 습득
- 실제 회원정보 관리 시스템을 통한 Hash 활용법 학습
- Hash와 String의 차이점 및 Hash 사용 시점 파악

## 🐳 실습 환경 준비

### 1. Docker Desktop에서 Redis 컨테이너 실행
```powershell
# PowerShell에서 실행
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine
```

### 2. Redis CLI 접속 확인
```powershell
# Redis CLI 접속
docker exec -it redis-lab redis-cli

# 접속 확인
ping
# 응답: PONG
```

## 📚 Hash 데이터 타입 이론

### Hash란?
- **정의**: 키-값 쌍의 컬렉션을 저장하는 데이터 구조
- **특징**: 하나의 Redis 키 안에 여러 개의 필드-값 쌍을 저장
- **용도**: 객체나 구조체 형태의 데이터 저장에 최적화

### Hash vs String 비교
| 구분 | String | Hash |
|------|--------|------|
| 저장 방식 | 단일 값 | 필드-값 쌍의 집합 |
| 메모리 효율성 | 낮음 | 높음 (작은 해시의 경우) |
| 부분 업데이트 | 불가능 | 가능 |
| 적합한 용도 | 단순 캐싱 | 객체 데이터 저장 |

## 🛠 주요 Hash 명령어

### 기본 명령어
- `HSET key field value` - 필드에 값 설정
- `HGET key field` - 필드의 값 조회
- `HGETALL key` - 모든 필드-값 쌍 조회
- `HKEYS key` - 모든 필드명 조회
- `HVALS key` - 모든 값 조회
- `HDEL key field [field ...]` - 특정 필드 삭제
- `HEXISTS key field` - 필드 존재 여부 확인
- `HLEN key` - 필드 개수 조회

### 고급 명령어
- `HMSET key field1 value1 field2 value2 ...` - 여러 필드 동시 설정
- `HMGET key field1 field2 ...` - 여러 필드 동시 조회
- `HINCRBY key field increment` - 필드 값 증가/감소
- `HSETNX key field value` - 필드가 없을 때만 설정

## 💡 실습 1: 기본 Hash 조작

### Redis CLI 접속
```powershell
docker exec -it redis-lab redis-cli
```

### 1-1. 단일 필드 설정 및 조회
```redis
# 사용자 정보 설정
HSET user:1001 name "김철수"
HSET user:1001 age 25
HSET user:1001 email "kim@example.com"

# 개별 필드 조회
HGET user:1001 name
HGET user:1001 age
HGET user:1001 email

# 모든 필드-값 조회
HGETALL user:1001
```

### 1-2. 여러 필드 동시 설정
```redis
# 새 사용자 정보 한 번에 설정
HMSET user:1002 name "이영희" age 28 email "lee@example.com" city "서울" job "개발자"

# 여러 필드 동시 조회
HMGET user:1002 name age job

# 모든 정보 확인
HGETALL user:1002
```

### 1-3. Hash 정보 조회
```redis
# 모든 필드명 조회
HKEYS user:1001

# 모든 값 조회
HVALS user:1001

# 필드 개수 확인
HLEN user:1001

# 특정 필드 존재 여부 확인
HEXISTS user:1001 phone
HEXISTS user:1001 name
```

## 💡 실습 2: 회원정보 관리 시스템

### 2-1. 여러 회원 정보 등록
```redis
# 회원 1: 관리자
HMSET user:admin id "admin" name "관리자" role "administrator" level 10 points 1000 status "active" created_at "2024-01-01" last_login "2024-05-23"

# 회원 2: 일반 사용자
HMSET user:john id "john_doe" name "John Doe" role "member" level 5 points 350 status "active" created_at "2024-03-15" last_login "2024-05-22"

# 회원 3: VIP 사용자
HMSET user:vip001 id "vip001" name "김VIP" role "vip" level 8 points 2500 status "active" created_at "2024-01-10" last_login "2024-05-23"

# 회원 4: 정지된 사용자
HMSET user:suspended id "bad_user" name "정지된사용자" role "member" level 2 points 50 status "suspended" created_at "2024-04-01" last_login "2024-04-15"
```

### 2-2. 회원 정보 조회 및 검색
```redis
# 전체 사용자 목록 확인
KEYS user:*

# 특정 회원 상세 정보
HGETALL user:admin
HGETALL user:john
HGETALL user:vip001

# 특정 정보만 조회
HMGET user:john name level points status
HMGET user:vip001 name role points
```

### 2-3. 회원 정보 업데이트
```redis
# 포인트 증가
HINCRBY user:john points 50
HINCRBY user:vip001 points 100

# 레벨업
HINCRBY user:john level 1

# 로그인 시간 업데이트
HSET user:john last_login "2024-05-23"

# 상태 변경
HSET user:suspended status "active"

# 업데이트 결과 확인
HGETALL user:john
HMGET user:suspended name status
```

## 💡 실습 3: 고급 Hash 활용

### 3-1. 조건부 설정
```redis
# 새 필드만 추가 (이미 존재하면 실패)
HSETNX user:john phone "010-1234-5678"
HSETNX user:john name "이미 존재하는 이름"  # 실패

# 결과 확인
HGET user:john phone
```

### 3-2. 필드 삭제
```redis
# 특정 필드 삭제
HDEL user:suspended created_at last_login

# 여러 필드 동시 삭제
HDEL user:admin level points

# 삭제 결과 확인
HGETALL user:suspended
HGETALL user:admin
```

### 3-3. 통계 정보 생성
```redis
# 시스템 통계를 위한 Hash 생성
HMSET system:stats total_users 4 active_users 4 vip_users 1 suspended_users 0 total_points 4000

# 사용자 활동 시 통계 업데이트
HINCRBY system:stats total_points 150
HINCRBY system:stats active_users 1

# 통계 확인
HGETALL system:stats
```

## 💡 실습 4: 실제 시나리오 - 사용자 세션 관리

### 4-1. 세션 정보 저장
```redis
# 로그인 세션 생성
HMSET session:abc123 user_id "john" ip_address "192.168.1.100" user_agent "Chrome/91.0" login_time "2024-05-23 09:00:00" last_activity "2024-05-23 09:00:00"

HMSET session:def456 user_id "vip001" ip_address "192.168.1.101" user_agent "Firefox/89.0" login_time "2024-05-23 09:15:00" last_activity "2024-05-23 09:15:00"

# 세션 만료 시간 설정 (30분)
EXPIRE session:abc123 1800
EXPIRE session:def456 1800
```

### 4-2. 세션 활동 업데이트
```redis
# 사용자 활동 시 세션 정보 업데이트
HSET session:abc123 last_activity "2024-05-23 09:30:00"
HINCRBY session:abc123 page_views 1

# 세션 정보 확인
HGETALL session:abc123
TTL session:abc123
```

### 4-3. 활성 세션 관리
```redis
# 모든 활성 세션 조회
KEYS session:*

# 특정 사용자의 모든 세션 찾기 (실제로는 보조 인덱스 필요)
HGETALL session:abc123
HGETALL session:def456
```

## 📊 성능 비교 실습

### String vs Hash 메모리 사용량 비교
```redis
# String 방식으로 사용자 정보 저장
SET user:1001:name "김철수"
SET user:1001:age "25"
SET user:1001:email "kim@example.com"
SET user:1001:city "서울"
SET user:1001:job "개발자"

# Hash 방식으로 사용자 정보 저장
HMSET user:2001 name "김철수" age 25 email "kim@example.com" city "서울" job "개발자"

# 메모리 사용량 확인
MEMORY USAGE user:1001:name
MEMORY USAGE user:1001:age
MEMORY USAGE user:1001:email
MEMORY USAGE user:1001:city
MEMORY USAGE user:1001:job

MEMORY USAGE user:2001
```

## 🔍 실습 결과 확인

### 최종 데이터 상태 점검
```redis
# 생성된 모든 키 확인
KEYS *

# 각 사용자 정보 최종 상태
HGETALL user:admin
HGETALL user:john
HGETALL user:vip001
HGETALL user:suspended

# 시스템 통계
HGETALL system:stats

# 활성 세션
KEYS session:*
```

## 🎯 심화 학습 과제

### 과제 1: 상품 정보 관리
다음 요구사항에 맞는 Hash 구조를 설계하고 구현하세요:
- 상품 ID, 이름, 가격, 재고, 카테고리, 설명
- 가격 변경 이력 추적
- 재고 증감 기능

### 과제 2: 게시판 시스템
게시글 정보를 Hash로 저장하는 시스템을 구현하세요:
- 제목, 내용, 작성자, 작성일, 조회수, 좋아요 수
- 조회수 증가 기능
- 좋아요 토글 기능

## 💡 실무 팁

### 1. Hash 사용 시점
- **적합한 경우**: 관련된 데이터를 그룹화할 때, 객체 형태의 데이터
- **부적합한 경우**: 단일 값만 저장할 때, 매우 큰 Hash (메모리 효율성 저하)

### 2. 성능 최적화
- 작은 Hash는 메모리 효율적
- 필드 수가 많으면 일반 키-값으로 분산 고려
- 자주 함께 조회되는 데이터는 Hash로 그룹화

### 3. 명명 규칙
- `객체타입:ID` 형태 권장 (예: `user:1001`, `product:5432`)
- 일관된 필드명 사용
- 예약어 피하기

## ✅ 학습 완료 체크리스트

- [ ] Hash 기본 개념 이해
- [ ] HSET, HGET, HGETALL 명령어 숙지
- [ ] 여러 필드 동시 조작 (HMSET, HMGET)
- [ ] 회원정보 관리 시스템 구현 완료
- [ ] 세션 관리 시스템 구현 완료
- [ ] String vs Hash 성능 비교 이해
- [ ] 실무 활용 방안 정리

## 🔗 다음 단계
다음은 **초급 6번 - List 데이터 타입 실습**입니다. Hash를 활용한 구조화된 데이터 저장 방법을 익혔으니, 이제 순서가 있는 데이터 컬렉션인 List를 학습해보겠습니다.

---
*본 교안은 Docker Desktop 환경의 Redis 7 Alpine 버전을 기준으로 작성되었습니다.*