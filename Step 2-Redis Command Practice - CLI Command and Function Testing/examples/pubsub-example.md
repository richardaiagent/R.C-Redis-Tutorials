# Redis 발행/구독(Pub/Sub) 패턴 실습

Redis의 발행/구독(Pub/Sub) 기능은 메시지 전송 시스템으로, 발행자(Publisher)가 특정 채널에 메시지를 보내면 해당 채널을 구독하고 있는 모든 구독자(Subscriber)에게 메시지가 전달됩니다.

## 발행/구독 개념

- **채널(Channel)**: 메시지가 전송되는 통로
- **발행자(Publisher)**: 채널에 메시지를 보내는 클라이언트
- **구독자(Subscriber)**: 채널의 메시지를 받는 클라이언트

## 실습 준비

이 실습에서는 두 개의 Redis CLI 세션이 필요합니다:
1. 구독자 세션
2. 발행자 세션

## 구독자 세션 설정

```bash
# 첫 번째 터미널에서 Redis CLI 실행
docker exec -it redis redis-cli -a mypassword

# 하나 이상의 채널 구독
127.0.0.1:6379> SUBSCRIBE news updates
Reading messages... (press Ctrl-C to quit)
1) "subscribe"
2) "news"
3) (integer) 1
1) "subscribe"
2) "updates"
3) (integer) 2
```

구독 명령을 실행하면 클라이언트는 구독 모드로 전환되며, 메시지를 기다리는 상태가 됩니다.

## 발행자 세션 설정

```bash
# 두 번째 터미널에서 Redis CLI 실행
docker exec -it redis redis-cli -a mypassword

# 채널에 메시지 발행
127.0.0.1:6379> PUBLISH news "Breaking news: Redis is awesome!"
(integer) 1

# 다른 채널에 메시지 발행
127.0.0.1:6379> PUBLISH updates "System update scheduled for tomorrow"
(integer) 1
```

`PUBLISH` 명령은 해당 채널을 구독 중인 클라이언트 수를 반환합니다.

## 구독자 세션에서의 결과

구독자 세션(첫 번째 터미널)에서는 다음과 같은 메시지가 표시됩니다:

```
1) "message"
2) "news"
3) "Breaking news: Redis is awesome!"
1) "message"
2) "updates"
3) "System update scheduled for tomorrow"
```

## 패턴 구독

채널 이름 패턴을 사용하여 여러 채널을 한 번에 구독할 수 있습니다:

```bash
# 첫 번째 터미널에서 Ctrl+C로 기존 구독을 중단하고 패턴 구독 시작
127.0.0.1:6379> PSUBSCRIBE news.* user.*
Reading messages... (press Ctrl-C to quit)
1) "psubscribe"
2) "news.*"
3) (integer) 1
1) "psubscribe"
2) "user.*"
3) (integer) 2
```

## 패턴 구독에 대한 발행

```bash
# 두 번째 터미널에서 패턴에 맞는 채널에 메시지 발행
127.0.0.1:6379> PUBLISH news.sports "Sports update: New record set!"
(integer) 1
127.0.0.1:6379> PUBLISH user.login "User login detected"
(integer) 1
```

## 패턴 구독자 세션에서의 결과

```
1) "pmessage"
2) "news.*"
3) "news.sports"
4) "Sports update: New record set!"
1) "pmessage"
2) "user.*"
3) "user.login"
4) "User login detected"
```

## 구독 해제

특정 채널 구독을 중단하려면:

```bash
# 첫 번째 터미널에서 특정 채널 구독 해제
127.0.0.1:6379> UNSUBSCRIBE news
1) "unsubscribe"
2) "news"
3) (integer) 0
```

패턴 구독을 중단하려면:

```bash
# 첫 번째 터미널에서 특정 패턴 구독 해제
127.0.0.1:6379> PUNSUBSCRIBE news.*
1) "punsubscribe"
2) "news.*"
3) (integer) 0
```

## 활성 채널 및 구독자 확인

```bash
# 두 번째 터미널에서 구독자가 있는 채널 목록 확인
127.0.0.1:6379> PUBSUB CHANNELS
1) "updates"
2) "user.*"

# 특정 패턴의 채널 목록 확인
127.0.0.1:6379> PUBSUB CHANNELS news*
1) "news.sports"

# 특정 채널의 구독자 수 확인
127.0.0.1:6379> PUBSUB NUMSUB updates
1) "updates"
2) (integer) 1

# 패턴 구독자 수 확인
127.0.0.1:6379> PUBSUB NUMPAT
(integer) 1
```

## 발행/구독 패턴의 주요 특징

1. 메시지는 구독자가 없더라도 발행 가능합니다(메시지는 발행 시점에 접속한 구독자에게만 전송됨).
2. 메시지는 저장되지 않고 즉시 전달됩니다.
3. 구독자가 오프라인일 때 발행된 메시지는 유실됩니다.
4. Redis 클러스터 환경에서는 Pub/Sub 메시지가 클러스터 전체에 전파됩니다.

## 실제 사용 사례

- 실시간 알림
- 채팅 애플리케이션
- 이벤트 브로드캐스팅
- 캐시 무효화
- 분산 시스템 간 통신