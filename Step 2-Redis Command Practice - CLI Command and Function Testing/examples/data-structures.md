# Redis 데이터 구조 명령어 실습

Redis는 다양한 데이터 구조를 지원합니다. 각 데이터 구조별 주요 명령어를 살펴보겠습니다.

## 1. 문자열(String)

```bash
# 문자열 설정 및 조회
127.0.0.1:6379> SET user:1:name "John"
OK
127.0.0.1:6379> GET user:1:name
"John"

# 숫자 증가 및 감소
127.0.0.1:6379> SET counter 100
OK
127.0.0.1:6379> INCR counter
(integer) 101
127.0.0.1:6379> INCRBY counter 50
(integer) 151
127.0.0.1:6379> DECR counter
(integer) 150
127.0.0.1:6379> DECRBY counter 50
(integer) 100

# 부분 문자열 가져오기
127.0.0.1:6379> SET greeting "Hello World"
OK
127.0.0.1:6379> GETRANGE greeting 0 4
"Hello"
```

## 2. 리스트(List)

```bash
# 리스트 왼쪽에 요소 추가
127.0.0.1:6379> LPUSH mylist "world"
(integer) 1
127.0.0.1:6379> LPUSH mylist "hello"
(integer) 2

# 리스트 오른쪽에 요소 추가
127.0.0.1:6379> RPUSH mylist "!"
(integer) 3

# 리스트 범위 조회
127.0.0.1:6379> LRANGE mylist 0 -1
1) "hello"
2) "world"
3) "!"

# 리스트 길이 조회
127.0.0.1:6379> LLEN mylist
(integer) 3

# 리스트 왼쪽에서 요소 제거 및 반환
127.0.0.1:6379> LPOP mylist
"hello"

# 리스트 오른쪽에서 요소 제거 및 반환
127.0.0.1:6379> RPOP mylist
"!"

# 특정 위치에 요소 설정
127.0.0.1:6379> LSET mylist 0 "WORLD"
OK

# 특정 위치 요소 조회
127.0.0.1:6379> LINDEX mylist 0
"WORLD"
```

## 3. 해시(Hash)

```bash
# 해시 필드 설정
127.0.0.1:6379> HSET user:1 username "john" password "secret" email "john@example.com"
(integer) 3

# 해시 필드 조회
127.0.0.1:6379> HGET user:1 username
"john"

# 해시의 모든 필드와 값 조회
127.0.0.1:6379> HGETALL user:1
1) "username"
2) "john"
3) "password"
4) "secret"
5) "email"
6) "john@example.com"

# 해시의 모든 필드 조회
127.0.0.1:6379> HKEYS user:1
1) "username"
2) "password"
3) "email"

# 해시의 모든 값 조회
127.0.0.1:6379> HVALS user:1
1) "john"
2) "secret"
3) "john@example.com"

# 필드 존재 여부 확인
127.0.0.1:6379> HEXISTS user:1 username
(integer) 1

# 필드 삭제
127.0.0.1:6379> HDEL user:1 password
(integer) 1

# 필드 값 증가
127.0.0.1:6379> HSET user:1 visits 10
(integer) 1
127.0.0.1:6379> HINCRBY user:1 visits 5
(integer) 15
```

## 4. 셋(Set)

```bash
# 셋에 요소 추가
127.0.0.1:6379> SADD myset "apple" "banana" "cherry"
(integer) 3

# 셋의 모든 요소 조회
127.0.0.1:6379> SMEMBERS myset
1) "apple"
2) "banana"
3) "cherry"

# 셋의 크기 조회
127.0.0.1:6379> SCARD myset
(integer) 3

# 요소 존재 여부 확인
127.0.0.1:6379> SISMEMBER myset "apple"
(integer) 1

# 요소 제거
127.0.0.1:6379> SREM myset "banana"
(integer) 1

# 두 셋의 교집합
127.0.0.1:6379> SADD set1 "a" "b" "c"
(integer) 3
127.0.0.1:6379> SADD set2 "c" "d" "e"
(integer) 3
127.0.0.1:6379> SINTER set1 set2
1) "c"

# 두 셋의 합집합
127.0.0.1:6379> SUNION set1 set2
1) "a"
2) "b"
3) "c"
4) "d"
5) "e"

# 두 셋의 차집합
127.0.0.1:6379> SDIFF set1 set2
1) "a"
2) "b"

# 랜덤 요소 가져오기
127.0.0.1:6379> SRANDMEMBER myset 2
1) "apple"
2) "cherry"
```

## 5. 정렬된 셋(Sorted Set)

```bash
# 정렬된 셋에 요소 추가
127.0.0.1:6379> ZADD leaderboard 100 "player1" 200 "player2" 300 "player3"
(integer) 3

# 점수 범위로 요소 조회
127.0.0.1:6379> ZRANGEBYSCORE leaderboard 100 200
1) "player1"
2) "player2"

# 점수와 함께 요소 조회
127.0.0.1:6379> ZRANGE leaderboard 0 -1 WITHSCORES
1) "player1"
2) "100"
3) "player2"
4) "200"
5) "player3"
6) "300"

# 역순으로 요소 조회
127.0.0.1:6379> ZREVRANGE leaderboard 0 -1
1) "player3"
2) "player2"
3) "player1"

# 요소의 순위 조회
127.0.0.1:6379> ZRANK leaderboard "player2"
(integer) 1

# 요소의 역순 순위 조회
127.0.0.1:6379> ZREVRANK leaderboard "player2"
(integer) 1

# 요소의 점수 조회
127.0.0.1:6379> ZSCORE leaderboard "player2"
"200"

# 요소의 점수 증가
127.0.0.1:6379> ZINCRBY leaderboard 50 "player1"
"150"

# 정렬된 셋의 크기 조회
127.0.0.1:6379> ZCARD leaderboard
(integer) 3

# 특정 범위의 요소 개수 조회
127.0.0.1:6379> ZCOUNT leaderboard 100 200
(integer) 2

# 요소 제거
127.0.0.1:6379> ZREM leaderboard "player2"
(integer) 1
```