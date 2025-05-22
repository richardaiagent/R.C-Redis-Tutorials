# Redis 기본 명령어 실습

## Redis CLI 연결하기

```bash
# Redis CLI 연결 (비밀번호 필요)
docker exec -it redis redis-cli -a mypassword

# Redis CLI 연결 (호스트와 포트 지정)
redis-cli -h localhost -p 6379 -a mypassword
```

## 연결 테스트

```bash
# Redis 서버 연결 테스트
127.0.0.1:6379> PING
PONG
```

## 기본 키-값 명령어

```bash
# 키-값 설정
127.0.0.1:6379> SET mykey "Hello Redis"
OK

# 값 조회
127.0.0.1:6379> GET mykey
"Hello Redis"

# 다중 키-값 설정
127.0.0.1:6379> MSET key1 "value1" key2 "value2" key3 "value3"
OK

# 다중 값 조회
127.0.0.1:6379> MGET key1 key2 key3
1) "value1"
2) "value2"
3) "value3"

# 키 존재 여부 확인
127.0.0.1:6379> EXISTS mykey
(integer) 1

# 키 삭제
127.0.0.1:6379> DEL mykey
(integer) 1

# 모든 키 조회 (주의: 프로덕션 환경에서는 사용하지 말 것)
127.0.0.1:6379> KEYS *
```

## 키 만료 설정

```bash
# 키 생성 및 만료 시간 설정 (초 단위)
127.0.0.1:6379> SET tempkey "temporary value"
OK
127.0.0.1:6379> EXPIRE tempkey 10
(integer) 1

# 만료 시간 조회
127.0.0.1:6379> TTL tempkey
(integer) 8

# 만료 시간이 설정된 키 생성
127.0.0.1:6379> SETEX shortkey 5 "short-lived value"
OK

# 만료 시간 제거
127.0.0.1:6379> PERSIST tempkey
(integer) 1
```

## 데이터베이스 관리

```bash
# 데이터베이스 선택 (0-15)
127.0.0.1:6379> SELECT 1
OK

# 현재 DB의 키 개수 조회
127.0.0.1:6379[1]> DBSIZE
(integer) 0

# 모든 키 삭제 (현재 DB만)
127.0.0.1:6379[1]> FLUSHDB
OK

# 모든 DB의 모든 키 삭제 (주의: 프로덕션 환경에서는 사용하지 말 것)
127.0.0.1:6379[1]> FLUSHALL
OK
```

## 서버 정보 조회

```bash
# 서버 정보 조회
127.0.0.1:6379> INFO
# Server
redis_version:7.0.11
...

# 특정 섹션 정보 조회
127.0.0.1:6379> INFO memory
# Memory
used_memory:1015872
...
```