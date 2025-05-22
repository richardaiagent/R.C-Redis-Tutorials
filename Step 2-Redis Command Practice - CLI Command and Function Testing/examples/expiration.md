# Redis 만료 설정 및 세션 관리 실습

Redis는 키 만료(expiration) 기능을 통해 특정 시간이 지나면 자동으로 데이터가 삭제되도록 할 수 있습니다. 이 기능은 세션 관리, 캐시 데이터 관리 등에 유용하게 사용됩니다.

## 기본 만료 설정

```bash
# 키 생성 및 만료 시간 설정 (초 단위)
127.0.0.1:6379> SET session:user123 "user session data"
OK
127.0.0.1:6379> EXPIRE session:user123 30
(integer) 1

# 만료 시간 조회 (초 단위)
127.0.0.1:6379> TTL session:user123
(integer) 28

# 남은 시간이 줄어드는 것을 확인
127.0.0.1:6379> TTL session:user123
(integer) 25

# 키와 만료 시간을 동시에 설정
127.0.0.1:6379> SETEX cache:item456 60 "cached data"
OK

# 밀리초 단위로 만료 시간 설정
127.0.0.1:6379> SET cache:temp "temporary data"
OK
127.0.0.1:6379> PEXPIRE cache:temp 5000
(integer) 1

# 밀리초 단위로 만료 시간 조회
127.0.0.1:6379> PTTL cache:temp
(integer) 4937
```

## 만료 시간 변경 및 제거

```bash
# 이미 만료 시간이 설정된 키의 만료 시간 변경
127.0.0.1:6379> SET token:abc123 "auth token"
OK
127.0.0.1:6379> EXPIRE token:abc123 300
(integer) 1
127.0.0.1:6379> TTL token:abc123
(integer) 298
127.0.0.1:6379> EXPIRE token:abc123 600
(integer) 1
127.0.0.1:6379> TTL token:abc123
(integer) 599

# 키의 만료 시간 제거 (영구적으로 유지)
127.0.0.1:6379> PERSIST token:abc123
(integer) 1
127.0.0.1:6379> TTL token:abc123
(integer) -1  # -1은 만료 시간이 설정되지 않았음을 의미
```

## 만료 시간에 대한 주의사항

```bash
# 키가 없는 경우 TTL 결과
127.0.0.1:6379> TTL nonexistent:key
(integer) -2  # -2는 키가 존재하지 않음을 의미

# SET 명령으로 기존 키를 덮어쓰면 만료 시간도 초기화
127.0.0.1:6379> SET token:abc123 "new auth token"  # 기존 만료 시간이 제거됨
OK
127.0.0.1:6379> TTL token:abc123
(integer) -1  # 만료 시간이 설정되지 않음

# 특정 시간에 만료되도록 설정 (Unix 타임스탬프 사용)
127.0.0.1:6379> SET future:event "scheduled event"
OK
127.0.0.1:6379> EXPIREAT future:event 1735689600  # 2025년 1월 1일
(integer) 1
```