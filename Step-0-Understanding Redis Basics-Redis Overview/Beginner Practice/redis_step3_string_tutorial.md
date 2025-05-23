# Redis 초급 3번 - String 데이터 타입 실습

## 🎯 학습 목표
- Redis String 데이터 타입의 특징과 활용법 이해
- 문자열 저장/조회 명령어 숙달
- 숫자 연산 기능 활용
- 문자열 조작 명령어 실습

## 🐳 실습 환경 준비

### 1. Redis 컨테이너 실행 확인
```powershell
# Docker Desktop이 실행 중인지 확인
docker ps

# Redis 컨테이너가 없다면 실행
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

# Redis CLI 접속
docker exec -it redis-lab redis-cli
```

### 2. 연결 확인
```redis
# Redis 연결 테스트
ping
# 응답: PONG
```

## 📝 이론 학습

### String 데이터 타입 특징
- Redis의 가장 기본적인 데이터 타입
- 바이너리 세이프(Binary Safe) - 모든 종류의 데이터 저장 가능
- 최대 512MB까지 저장 가능
- 문자열뿐만 아니라 숫자, JSON, 이미지 등도 저장 가능

### 주요 명령어
- `SET` : 키-값 저장
- `GET` : 값 조회
- `INCR/DECR` : 숫자 증가/감소
- `APPEND` : 문자열 추가
- `STRLEN` : 문자열 길이
- `MSET/MGET` : 다중 키-값 처리

## 🔬 실습 1: 기본 문자열 저장 및 조회

```redis
# 기본 문자열 저장
SET user:1:name "김철수"
SET user:1:email "kimcs@example.com"
SET user:1:phone "010-1234-5678"

# 저장된 값 조회
GET user:1:name
GET user:1:email
GET user:1:phone

# 존재하지 않는 키 조회
GET user:999:name
# 결과: (nil)

# 키 존재 여부 확인
EXISTS user:1:name
EXISTS user:999:name
```

**예상 결과:**
```
127.0.0.1:6379> GET user:1:name
"김철수"
127.0.0.1:6379> EXISTS user:1:name
(integer) 1
```

## 🔢 실습 2: 숫자 연산 (카운터 구현)

```redis
# 페이지 방문 카운터 초기화
SET page:home:views 0
SET page:about:views 10

# 방문 카운트 증가
INCR page:home:views
INCR page:home:views
INCR page:home:views

# 특정 값만큼 증가
INCRBY page:home:views 5

# 현재 값 확인
GET page:home:views

# 감소 연산
DECR page:about:views
DECRBY page:about:views 3

# 소수점 연산
SET temperature 23.5
INCRBYFLOAT temperature 1.2
GET temperature
```

**예상 결과:**
```
127.0.0.1:6379> GET page:home:views
"8"
127.0.0.1:6379> GET temperature
"24.7"
```

## 📝 실습 3: 문자열 조작

```redis
# 문자열 추가
SET message "안녕하세요"
APPEND message " Redis 학습자분들!"
GET message

# 문자열 길이 확인
STRLEN message

# 부분 문자열 추출
GETRANGE message 0 4
GETRANGE message 6 -1

# 문자열 덮어쓰기
SETRANGE message 6 "Python"
GET message
```

**예상 결과:**
```
127.0.0.1:6379> GET message
"안녕하세요 Python학습자분들!"
```

## 🚀 실습 4: 다중 키-값 처리

```redis
# 여러 키-값 한 번에 저장
MSET product:1:name "노트북" product:1:price 1200000 product:1:stock 15

# 여러 값 한 번에 조회
MGET product:1:name product:1:price product:1:stock

# 조건부 저장 (키가 존재하지 않을 때만)
SETNX product:1:discount 10
SETNX product:1:name "데스크탑"  # 이미 존재하므로 저장되지 않음

# 확인
GET product:1:discount
GET product:1:name
```

## 🛒 실습 5: 실무 시나리오 - 간단한 장바구니 시스템

```redis
# 사용자별 장바구니 아이템 수량
SET cart:user123:item001 2
SET cart:user123:item002 1
SET cart:user123:item003 3

# 아이템 수량 변경
INCR cart:user123:item001  # 수량 1 증가
DECRBY cart:user123:item003 2  # 수량 2 감소

# 장바구니 전체 조회
MGET cart:user123:item001 cart:user123:item002 cart:user123:item003

# 총 아이템 수 계산 (실제로는 애플리케이션에서 처리)
GET cart:user123:item001
GET cart:user123:item002
GET cart:user123:item003
```

## 🎲 실습 6: 게임 점수 시스템

```redis
# 플레이어 점수 초기화
SET game:player:alice:score 0
SET game:player:bob:score 0
SET game:player:charlie:score 0

# 게임 진행 - 점수 획득
INCRBY game:player:alice:score 100
INCRBY game:player:bob:score 150
INCRBY game:player:charlie:score 80

# 보너스 점수 추가
INCRBY game:player:alice:score 50

# 최종 점수 확인
MGET game:player:alice:score game:player:bob:score game:player:charlie:score

# 게임 라운드 카운터
SET game:round:current 1
INCR game:round:current
GET game:round:current
```

## ✅ 실습 완료 체크리스트

- [ ] 기본 SET/GET 명령어로 문자열 저장/조회
- [ ] INCR/DECR로 숫자 연산 수행
- [ ] APPEND로 문자열 추가
- [ ] MSET/MGET로 다중 키-값 처리
- [ ] 실무 시나리오 (장바구니, 게임 점수) 구현
- [ ] 각 명령어의 반환값과 동작 방식 이해

## 🤔 응용 문제

1. **웹사이트 방문자 통계 시스템**
   - 일별, 월별 방문자 수를 추적하는 시스템 구현
   - 키 패턴: `visits:2024:05:23`, `visits:2024:05`

2. **사용자 세션 관리**
   - 사용자 로그인 시간을 문자열로 저장
   - 키 패턴: `session:user123:login_time`

3. **API 호출 횟수 제한**
   - 사용자별 API 호출 횟수를 추적
   - 키 패턴: `api:user123:calls:2024-05-23`

## 🔍 성능 특성

- String 연산은 O(1) 시간 복잡도
- APPEND는 O(1), 하지만 메모리 재할당이 발생할 수 있음
- INCR/DECR는 원자적(Atomic) 연산으로 동시성 안전

## 💡 실무 활용 팁

1. **키 네이밍 규칙**: `객체:ID:필드` 형태로 일관성 유지
2. **숫자 저장**: 정수는 INCR/DECR 활용, 소수는 INCRBYFLOAT 사용
3. **메모리 효율**: 짧은 키 이름과 압축된 값 사용
4. **타입 확인**: Redis는 모든 값을 문자열로 저장하므로 타입 주의

## 🔧 문제 해결

```redis
# 현재 저장된 모든 키 확인 (개발 환경에서만 사용)
KEYS *

# 특정 패턴의 키만 확인
KEYS user:*
KEYS cart:*

# 데이터 타입 확인
TYPE user:1:name

# 키 삭제
DEL user:999:name
```

---
**다음 단계**: 초급 4번 - 키 관리 및 만료 시간 실습