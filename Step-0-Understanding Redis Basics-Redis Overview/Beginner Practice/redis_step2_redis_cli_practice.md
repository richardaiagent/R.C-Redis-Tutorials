# Redis 초급 2번 - Redis CLI 접속 및 기본 명령 실습 교안

## 📋 학습 목표
- Redis CLI 접속 방법 및 기본 사용법 숙지
- Redis 기본 명령어 이해 및 실습
- Redis 데이터베이스 구조 및 키 관리 방법 학습
- Redis 서버 정보 확인 및 상태 모니터링
- CLI를 통한 Redis 디버깅 및 문제 해결 기초

## 🐳 사전 준비 - Redis 컨테이너 실행

### Docker Redis 환경 확인
```powershell
# PowerShell에서 Redis 컨테이너 상태 확인
docker ps --filter "name=redis"

# Redis 컨테이너가 없는 경우 실행
docker run -d --name redis-lab -p 6379:6379 -v redis-data:/data redis:7-alpine

# 컨테이너 실행 확인
docker ps
```

## 🔧 Redis CLI 접속 방법

### 방법 1: Docker exec를 통한 접속 (권장)
```powershell
# 가장 일반적인 접속 방법
docker exec -it redis-lab redis-cli

# 접속 확인
ping
# 응답: PONG
```

### 방법 2: 특정 호스트/포트 지정 접속
```powershell
# 컨테이너 내에서 특정 설정으로 접속
docker exec -it redis-lab redis-cli -h localhost -p 6379

# 또는 외부에서 접속 (Redis CLI가 로컬에 설치된 경우)
# redis-cli -h localhost -p 6379
```

### 방법 3: 비밀번호가 설정된 Redis 접속
```powershell
# 인증이 필요한 Redis 접속
docker exec -it redis-lab redis-cli -a mypassword

# 또는 접속 후 인증
docker exec -it redis-lab redis-cli
auth mypassword
```

## 📚 Redis CLI 기본 개념

### Redis CLI 인터페이스 이해
```redis
# Redis CLI 프롬프트
127.0.0.1:6379> 

# 명령어 입력 후 결과 확인
127.0.0.1:6379> ping
PONG

# 여러 라인 명령어 (실제로는 한 줄로 입력)
127.0.0.1:6379> set mykey "hello world"
OK
```

### 기본 명령어 구조
- **명령어**: 대소문자 구분 없음 (SET = set = Set)
- **인수**: 공백으로 구분
- **문자열**: 따옴표 사용 (공백 포함 시 필수)

## 💡 실습 1: 연결 테스트 및 기본 정보 확인

### Redis CLI 접속
```powershell
docker exec -it redis-lab redis-cli
```

### 1-1. 연결 상태 확인
```redis
# 기본 연결 테스트
ping
# 응답: PONG

# 메시지와 함께 ping
ping "안녕하세요 Redis!"
# 응답: "안녕하세요 Redis!"

# 연결 정보 확인
client list
client info
```

### 1-2. 서버 정보 확인
```redis
# Redis 서버 전체 정보
info

# 특정 섹션 정보만 확인
info server
info memory
info stats
info replication
info cpu

# Redis 버전 확인
info server | grep redis_version
```

### 1-3. 서버 설정 확인
```redis
# 모든 설정 확인
config get "*"

# 특정 설정 확인
config get "maxmemory*"
config get "save"
config get "databases"

# 실시간 설정 변경 (임시)
config set maxmemory-policy "allkeys-lru"
config get maxmemory-policy
```

## 💡 실습 2: 데이터베이스 및 키 관리

### 2-1. 데이터베이스 선택 및 관리
```redis
# 현재 데이터베이스 확인 (기본: 0번)
# Redis CLI 프롬프트에서 확인 가능: 127.0.0.1:6379[0]>

# 다른 데이터베이스로 전환
select 1
# 프롬프트 변경: 127.0.0.1:6379[1]>

select 2
select 0  # 기본 데이터베이스로 복귀

# 현재 데이터베이스의 키 개수
dbsize

# 모든 데이터베이스 정보
info keyspace
```

### 2-2. 키 관리 기본 명령어
```redis
# 테스트 데이터 생성
set user:1001 "김철수"
set user:1002 "이영희"
set counter 100
set message "안녕하세요"
set temp:session "임시세션"

# 모든 키 조회
keys *

# 패턴으로 키 검색
keys user:*
keys *session*
keys temp:*

# 키 존재 여부 확인
exists user:1001
exists user:9999

# 키 개수 확인
dbsize
```

### 2-3. 키 타입 및 상세 정보
```redis
# 키의 데이터 타입 확인
type user:1001
type counter
type message

# 키 이름 변경
rename counter old_counter
keys *counter*

# 키 삭제
del temp:session
exists temp:session

# 여러 키 동시 삭제
del user:1001 user:1002 message
keys *
```

## 💡 실습 3: 기본 데이터 조작 명령어

### 3-1. String 데이터 기본 조작
```redis
# 기본 문자열 저장/조회
set greeting "안녕하세요 Redis!"
get greeting

# 숫자 데이터 저장/조회
set score 85
get score

# 여러 키-값 동시 설정
mset name "홍길동" age 30 city "서울" job "개발자"

# 여러 키 동시 조회
mget name age city job

# 존재하지 않는 키 조회
get nonexistent_key
```

### 3-2. 숫자 연산
```redis
# 숫자 증가/감소
set counter 0
incr counter
incr counter
incr counter

get counter

# 특정 값만큼 증가/감소
incrby counter 10
decrby counter 3

get counter

# 실수 연산
set price 19.99
incrbyfloat price 5.50
get price
```

### 3-3. 문자열 조작
```redis
# 문자열 연결
set filename "document"
append filename ".txt"
get filename

append filename ".backup"
get filename

# 문자열 길이
strlen filename

# 부분 문자열 조회
set fullname "김철수입니다"
getrange fullname 0 2
getrange fullname 3 -1

# 부분 문자열 설정
setrange fullname 0 "이영희"
get fullname
```

## 💡 실습 4: 고급 키 관리

### 4-1. 키 만료 시간 설정
```redis
# 10초 후 만료되는 키 설정
set temp_key "임시 데이터"
expire temp_key 10

# 만료 시간 확인
ttl temp_key

# 5초 대기 후 다시 확인
# (실제로는 터미널에서 5초 기다린 후 실행)
ttl temp_key

# 만료 시간과 함께 키 설정
setex session_key 30 "세션 데이터"
ttl session_key

# 만료 시간 제거 (영구 보존)
persist session_key
ttl session_key
```

### 4-2. 조건부 설정
```redis
# 키가 존재하지 않을 때만 설정
set user:new "새 사용자"
setnx user:new "덮어쓰기 시도"  # 실패
get user:new

setnx user:another "다른 사용자"  # 성공
get user:another

# 키가 존재할 때만 설정 (Redis 6.0+)
set existing_key "기존 값"
set existing_key "새 값" xx  # 존재하므로 성공
set nonexistent_key "새 값" xx  # 존재하지 않으므로 실패
```

### 4-3. 키 검색 및 스캔
```redis
# 대량 데이터 생성 (테스트용)
mset product:1001 "노트북" product:1002 "마우스" product:1003 "키보드" user:admin "관리자" user:guest "게스트" config:db "localhost" config:port "3306"

# 패턴 검색
keys product:*
keys user:*
keys config:*

# SCAN을 사용한 안전한 검색 (운영 환경 권장)
scan 0
scan 0 match product:*
scan 0 match user:* count 10
```

## 💡 실습 5: Redis CLI 유용한 기능

### 5-1. 모니터링 명령어
```redis
# 실행 중인 명령어 실시간 모니터링 (별도 터미널에서)
# docker exec -it redis-lab redis-cli monitor

# 느린 쿼리 로그 확인
slowlog get
slowlog len
slowlog reset

# 실시간 통계
info stats
# 잠시 후 다시 실행하여 변화 확인
info stats
```

### 5-2. 디버깅 명령어
```redis
# 메모리 사용량 분석
memory usage greeting
memory usage product:1001

# 키 덤프 (직렬화)
dump user:admin

# Redis 내부 객체 정보
object encoding greeting
object idletime greeting
object refcount greeting

# 데이터베이스 통계
info keyspace
```

### 5-3. 일괄 처리
```redis
# 현재 데이터베이스의 모든 키 삭제 (주의!)
# 먼저 백업용 데이터 생성
mset backup:key1 "데이터1" backup:key2 "데이터2" backup:key3 "데이터3"

# 모든 키 확인
keys *

# 현재 DB 플러시 (주의! 모든 데이터 삭제)
flushdb

# 결과 확인
keys *
dbsize

# 모든 데이터베이스 플러시 (더욱 주의!)
# flushall
```

## 💡 실습 6: 실제 사용 시나리오

### 6-1. 사용자 세션 관리 시뮬레이션
```redis
# 사용자 로그인 시뮬레이션
set session:abc123 "user:1001"
expire session:abc123 1800  # 30분 세션

set session:def456 "user:1002"
expire session:def456 1800

set session:ghi789 "user:1003"
expire session:def456 1800

# 활성 세션 확인
keys session:*

# 세션 유효성 검사
ttl session:abc123
exists session:abc123

# 세션 연장
expire session:abc123 1800
```

### 6-2. 카운터 시스템 구현
```redis
# 방문자 수 카운터
set visitor_count 0

# 방문자 증가 시뮬레이션
incr visitor_count
incr visitor_count
incr visitor_count

# 일일 방문자 (날짜별)
set visitors:2024-05-23 0
incr visitors:2024-05-23
incr visitors:2024-05-23
incr visitors:2024-05-23

# 통계 확인
get visitor_count
get visitors:2024-05-23
```

### 6-3. 캐시 시뮬레이션
```redis
# 상품 정보 캐싱 (5분 캐시)
setex product:cache:1001 300 '{"name":"노트북","price":1500000,"stock":10}'
setex product:cache:1002 300 '{"name":"마우스","price":25000,"stock":50}'

# 캐시 확인
get product:cache:1001
ttl product:cache:1001

# 캐시 갱신
setex product:cache:1001 300 '{"name":"노트북","price":1400000,"stock":8}'
```

## 🔧 Redis CLI 고급 기능

### 명령어 히스토리
```redis
# Redis CLI는 명령어 히스토리를 지원
# 위/아래 화살표로 이전 명령어 탐색 가능
# Ctrl+R로 히스토리 검색
```

### 배치 모드 실행
```powershell
# PowerShell에서 명령어 파이프라인으로 실행
echo "ping" | docker exec -i redis-lab redis-cli

# 여러 명령어 실행
@"
ping
set test_batch "배치 실행"
get test_batch
"@ | docker exec -i redis-lab redis-cli
```

### 출력 형식 지정
```powershell
# JSON 형식으로 출력
docker exec -it redis-lab redis-cli --json

# CSV 형식으로 출력
docker exec -it redis-lab redis-cli --csv

# 원시 출력
docker exec -it redis-lab redis-cli --raw
```

## 🎯 실습 과제

### 과제 1: 게시판 시스템 기본 구조
Redis CLI를 사용하여 다음을 구현하세요:
1. 게시글 카운터 (post:count)
2. 게시글 제목 저장 (post:1:title, post:2:title, ...)
3. 게시글 조회수 (post:1:views, post:2:views, ...)
4. 게시글 목록 조회

### 과제 2: 실시간 통계 시스템
다음 통계를 Redis CLI로 구현하세요:
1. 일일 활성 사용자 수
2. 페이지별 방문 횟수
3. 실시간 온라인 사용자 수 (TTL 활용)

## 💡 문제 해결 가이드

### 일반적인 CLI 문제들

#### 문제 1: 한글 입력/출력 문제
```powershell
# PowerShell 인코딩 설정
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Redis CLI에서 한글 처리
docker exec -it redis-lab redis-cli --raw
```

#### 문제 2: 명령어 실행 안됨
```redis
# 오타 확인
ping  # 정확한 명령어
pong  # 잘못된 명령어

# 인수 개수 확인
set key  # 잘못됨 (값 누락)
set key value  # 정확함
```

#### 문제 3: 연결 끊김
```powershell
# 컨테이너 상태 확인
docker ps

# 컨테이너 재시작
docker restart redis-lab

# 재연결
docker exec -it redis-lab redis-cli
```

### 성능 관련 주의사항
```redis
# KEYS 명령어는 운영환경에서 사용 금지 (블로킹)
keys *  # 개발/테스트에서만 사용

# 대신 SCAN 사용
scan 0

# 대량 데이터 삭제 시 주의
# flushall  # 전체 삭제 (위험)
# flushdb   # 현재 DB만 삭제 (주의)
```

## 📊 학습 성과 확인

### 최종 실습 데이터 점검
```redis
# 현재 저장된 모든 데이터 확인
info keyspace
dbsize
keys *

# 각 데이터 타입별 키 확인
keys user:*
keys product:*
keys session:*
keys visitors:*

# 메모리 사용량 확인
info memory
memory usage product:cache:1001
```

### CLI 숙련도 체크
```redis
# 다음 작업을 CLI로 수행할 수 있는지 확인:
# 1. 키 생성/조회/삭제
# 2. 만료 시간 설정/확인
# 3. 숫자 증감 연산
# 4. 패턴 검색
# 5. 서버 정보 확인
# 6. 메모리 사용량 분석
```

## ✅ 학습 완료 체크리스트

### 기본 CLI 조작
- [ ] Redis CLI 접속 및 종료
- [ ] ping/pong 연결 테스트
- [ ] 기본 정보 조회 (info, config)
- [ ] 데이터베이스 선택 및 관리

### 키 관리
- [ ] 키 생성, 조회, 삭제
- [ ] 키 패턴 검색 (keys, scan)
- [ ] 키 타입 확인 및 변환
- [ ] 만료 시간 설정 및 관리

### 데이터 조작
- [ ] String 데이터 저장/조회
- [ ] 숫자 연산 (incr, decr)
- [ ] 문자열 조작 (append, strlen)
- [ ] 조건부 설정 (setnx)

### 고급 기능
- [ ] 모니터링 명령어 사용
- [ ] 메모리 사용량 분석
- [ ] 배치 처리 및 스크립팅
- [ ] 성능 최적화 고려사항 이해

## 🔗 다음 단계
다음은 **초급 3번 - String 데이터 타입 실습**입니다. Redis CLI 사용법을 익혔으니, 이제 Redis의 가장 기본적인 데이터 타입인 String을 심도 있게 학습해보겠습니다.

---
*본 교안은 Docker Redis 7 Alpine 환경과 Windows PowerShell을 기준으로 작성되었습니다.*