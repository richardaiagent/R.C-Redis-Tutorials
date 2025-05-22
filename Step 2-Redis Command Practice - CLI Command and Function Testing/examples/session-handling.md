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

## 세션 관리 예제

웹 애플리케이션의 사용자 세션을 Redis로 관리하는 예제:

```bash
# 세션 데이터 해시로 저장
127.0.0.1:6379> HSET session:user123 username "john" last_login "2023-05-17 10:30:00" is_active "true"
(integer) 3

# 세션에 만료 시간 설정 (30분 = 1800초)
127.0.0.1:6379> EXPIRE session:user123 1800
(integer) 1

# 세션 데이터 조회
127.0.0.1:6379> HGETALL session:user123
1) "username"
2) "john"
3) "last_login"
4) "2023-05-17 10:30:00"
5) "is_active"
6) "true"

# 사용자 활동 시 세션 갱신 (만료 시간 연장)
127.0.0.1:6379> EXPIRE session:user123 1800
(integer) 1

# 로그아웃 시 세션 즉시 삭제
127.0.0.1:6379> DEL session:user123
(integer) 1
```

## 활성 세션 관리 패턴

모든 활성 세션을 추적하는 패턴:

```bash
# 활성 세션 집합에 세션 ID 추가
127.0.0.1:6379> SADD active:sessions "user123" "user456" "user789"
(integer) 3

# 새 세션 생성 시 세션 데이터와 함께 활성 세션 집합에 추가
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379> HSET session:user999 username "alice" last_login "2023-05-17 11:45:00" is_active "true"
QUEUED
127.0.0.1:6379> EXPIRE session:user999 1800
QUEUED
127.0.0.1:6379> SADD active:sessions "user999"
QUEUED
127.0.0.1:6379> EXEC
1) (integer) 3
2) (integer) 1
3) (integer) 1

# 활성 세션 목록 조회
127.0.0.1:6379> SMEMBERS active:sessions
1) "user123"
2) "user456"
3) "user789"
4) "user999"

# 로그아웃 시 세션 삭제 및 활성 세션 목록에서 제거
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379> DEL session:user456
QUEUED
127.0.0.1:6379> SREM active:sessions "user456"
QUEUED
127.0.0.1:6379> EXEC
1) (integer) 1
2) (integer) 1
```

## 로그인 인증 및 세션 토큰 예제

인증 토큰 생성 및 관리 패턴:

```bash
# 사용자 로그인 처리
127.0.0.1:6379> SET user:token:abcdef123456 "user123"  # 토큰을 사용자 ID에 매핑
OK
127.0.0.1:6379> EXPIRE user:token:abcdef123456 86400  # 토큰 24시간 유효
(integer) 1

# 사용자별 토큰 목록 유지 (한 사용자가 여러 기기에서 로그인)
127.0.0.1:6379> SADD user:123:tokens "abcdef123456" "ghijkl789012"
(integer) 2

# 토큰으로 사용자 인증
127.0.0.1:6379> GET user:token:abcdef123456
"user123"  # 사용자 ID 반환

# 특정 사용자의 모든 세션 로그아웃 (모든 기기에서 로그아웃)
127.0.0.1:6379> SMEMBERS user:123:tokens
1) "abcdef123456"
2) "ghijkl789012"

# 스크립트를 사용하여 모든 토큰 삭제 (실제로는 Lua 스크립트나 트랜잭션으로 처리)
127.0.0.1:6379> DEL user:token:abcdef123456
(integer) 1
127.0.0.1:6379> DEL user:token:ghijkl789012
(integer) 1
127.0.0.1:6379> DEL user:123:tokens
(integer) 1
```

## 속도 제한(Rate Limiting) 구현

API 호출이나 로그인 시도 등의 속도를 제한하는 패턴:

```bash
# 사용자당 API 호출 횟수 제한 (윈도우 방식)
127.0.0.1:6379> INCR ratelimit:user123:api:minute
(integer) 1
127.0.0.1:6379> EXPIRE ratelimit:user123:api:minute 60  # 1분 후 만료
(integer) 1

# 다시 호출
127.0.0.1:6379> INCR ratelimit:user123:api:minute
(integer) 2

# 호출 횟수 확인
127.0.0.1:6379> GET ratelimit:user123:api:minute
"2"

# 호출 제한 검사 (예: 분당 최대 100회 호출)
127.0.0.1:6379> GET ratelimit:user123:api:minute
"2"  # 2 < 100이므로 허용
```

## 웹 세션 동기화 (분산 환경)

여러 웹 서버 간 세션 동기화 패턴:

```bash
# 세션 저장
127.0.0.1:6379> SETEX "session:${sessionId}" 1800 "${sessionData}"

# 세션 조회
127.0.0.1:6379> GET "session:${sessionId}"

# 세션 갱신 (활성 상태 유지)
127.0.0.1:6379> EXPIRE "session:${sessionId}" 1800

# 세션 삭제 (로그아웃)
127.0.0.1:6379> DEL "session:${sessionId}"
```

## 만료 이벤트 구독

Redis 6.0 이상에서는 키 만료 이벤트를 발행/구독할 수 있습니다:

```bash
# 키 만료 이벤트 구독 (별도 터미널에서)
127.0.0.1:6379> CONFIG SET notify-keyspace-events Ex
OK
127.0.0.1:6379> SUBSCRIBE __keyevent@0__:expired
Reading messages... (press Ctrl-C to quit)
1) "subscribe"
2) "__keyevent@0__:expired"
3) (integer) 1

# 다른 터미널에서 만료되는 키 생성
127.0.0.1:6379> SETEX test:key 5 "value"
OK

# 5초 후 첫 번째 터미널에서 다음 메시지가 표시됨
1) "message"
2) "__keyevent@0__:expired"
3) "test:key"
```