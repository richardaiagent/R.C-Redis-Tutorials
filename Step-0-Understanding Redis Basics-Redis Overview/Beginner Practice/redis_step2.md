# Redis 초급 2단계: Redis CLI 접속 및 기본 명령 ⭐⭐⭐

## 🎯 학습 목표
Redis CLI에 접속하여 기본 명령어를 익히고 Redis 서버와의 상호작용을 실습합니다.

## 📋 사전 준비사항
- 1단계에서 구성한 Redis 컨테이너가 실행 중이어야 합니다
- 컨테이너 이름: `redis-lab` 또는 `redis-persistent`

---

## 🔧 실습 단계

### 2-1. Redis CLI 접속
```bash
# Redis 컨테이너에 접속하여 CLI 실행
docker exec -it redis-persistent redis-cli

# 성공적으로 접속되면 다음과 같은 프롬프트가 나타남
# 127.0.0.1:6379>
```

### 2-2. 기본 연결 테스트
```bash
# Redis CLI 프롬프트에서 실행
127.0.0.1:6379> ping
# 출력: PONG

127.0.0.1:6379> echo "Hello Redis!"
# 출력: "Hello Redis!"
```

### 2-3. 서버 정보 확인
```bash
# Redis 서버 정보 확인
127.0.0.1:6379> info server
# 출력: Redis 버전, 운영체제, 아키텍처 등의 정보

# 간단한 서버 상태 확인
127.0.0.1:6379> info stats
# 출력: 연결 수, 명령 처리 수 등의 통계 정보
```

### 2-4. 데이터베이스 정보 확인
```bash
# 현재 데이터베이스 확인 (기본값: 0)
127.0.0.1:6379> select 0
# 출력: OK

# 데이터베이스 크기 확인
127.0.0.1:6379> dbsize
# 출력: (integer) 0  (아직 데이터가 없음)

# 모든 키 확인
127.0.0.1:6379> keys *
# 출력: (empty list or set)  (아직 키가 없음)
```

---

## 🧪 실습 데이터 생성 및 테스트

### 2-5. 기본 데이터 입력 및 조회
```bash
# 간단한 문자열 데이터 저장
127.0.0.1:6379> set welcome "Hello Redis World!"
# 출력: OK

# 데이터 조회
127.0.0.1:6379> get welcome
# 출력: "Hello Redis World!"

# 숫자 데이터 저장
127.0.0.1:6379> set counter 100
# 출력: OK

127.0.0.1:6379> get counter
# 출력: "100"
```

### 2-6. 여러 데이터 타입 테스트
```bash
# 리스트 데이터 생성
127.0.0.1:6379> lpush fruits "apple" "banana" "orange"
# 출력: (integer) 3

# 리스트 조회
127.0.0.1:6379> lrange fruits 0 -1
# 출력:
# 1) "orange"
# 2) "banana"
# 3) "apple"

# 해시 데이터 생성
127.0.0.1:6379> hset user:1001 name "김철수" age 25 city "서울"
# 출력: (integer) 3

# 해시 데이터 조회
127.0.0.1:6379> hgetall user:1001
# 출력:
# 1) "name"
# 2) "김철수"
# 3) "age"
# 4) "25"
# 5) "city"
# 6) "서울"
```

### 2-7. 현재 저장된 모든 키 확인
```bash
# 모든 키 목록 확인
127.0.0.1:6379> keys *
# 출력:
# 1) "welcome"
# 2) "counter"
# 3) "fruits"
# 4) "user:1001"

# 데이터베이스 크기 재확인
127.0.0.1:6379> dbsize
# 출력: (integer) 4
```

---

## 🎮 CLI 명령어 연습

### 2-8. 기본 유틸리티 명령어
```bash
# 현재 시간 확인
127.0.0.1:6379> time
# 출력:
# 1) "1716454845"  (Unix timestamp)
# 2) "123456"      (마이크로초)

# 마지막 저장 시간 확인
127.0.0.1:6379> lastsave
# 출력: (integer) 1716454800

# 클라이언트 목록 확인
127.0.0.1:6379> client list
# 출력: 현재 연결된 클라이언트 정보
```

### 2-9. 도움말 및 명령어 정보
```bash
# 특정 명령어 도움말 확인
127.0.0.1:6379> help set
# 출력: SET 명령어 사용법

# 전체 명령어 그룹 확인
127.0.0.1:6379> help @string
# 출력: 문자열 관련 명령어들

# CLI 종료
127.0.0.1:6379> quit
# 또는 Ctrl+C
```

---

## 🔄 다중 터미널 접속 실습

### 2-10. 여러 CLI 세션 동시 접속
```bash
# 터미널 1에서
docker exec -it redis-persistent redis-cli

# 터미널 2에서 (새로운 PowerShell/CMD 창)
docker exec -it redis-persistent redis-cli

# 터미널 1에서 데이터 입력
127.0.0.1:6379> set shared_data "공유 데이터"

# 터미널 2에서 즉시 확인
127.0.0.1:6379> get shared_data
# 출력: "공유 데이터"
```

---

## ✅ 학습 완료 체크리스트

### 필수 체크사항
- [ ] Redis CLI에 성공적으로 접속했는가?
- [ ] `ping` 명령이 `PONG`을 반환하는가?
- [ ] 기본 `set`/`get` 명령을 사용할 수 있는가?
- [ ] `keys *` 명령으로 저장된 키를 확인할 수 있는가?
- [ ] `info` 명령으로 서버 정보를 확인할 수 있는가?

### 실습 완료 체크사항
- [ ] 문자열 데이터를 저장하고 조회했는가?
- [ ] 리스트 데이터를 생성하고 조회했는가?
- [ ] 해시 데이터를 생성하고 조회했는가?
- [ ] 여러 터미널에서 동시 접속을 테스트했는가?

---

## 🚨 문제 해결 가이드

### 문제 1: CLI 접속이 안됨
**해결방법**:
```bash
# 컨테이너 상태 확인
docker ps

# 컨테이너가 실행되지 않은 경우
docker start redis-persistent

# 컨테이너 재시작
docker restart redis-persistent
```

### 문제 2: 한글 입력/출력 문제
**해결방법**:
```bash
# Windows PowerShell에서 UTF-8 설정
chcp 65001

# 또는 Redis CLI에서 한글 대신 영문 사용 권장
```

### 문제 3: 명령어 입력 오류
**해결방법**:
- Redis 명령어는 대소문자를 구분하지 않습니다
- 문자열 값에 공백이 있는 경우 따옴표로 감싸주세요
- `help` 명령어로 정확한 문법을 확인하세요

---

## 📊 현재 저장된 실습 데이터 현황

실습을 완료하면 다음 데이터가 Redis에 저장되어 있어야 합니다:

| 키 | 타입 | 값 |
|---|---|---|
| welcome | string | "Hello Redis World!" |
| counter | string | "100" |
| fruits | list | ["orange", "banana", "apple"] |
| user:1001 | hash | {name: "김철수", age: "25", city: "서울"} |

---

## 📝 다음 단계 예고
다음 3단계에서는 String 데이터 타입에 대해 더 자세히 학습하고 다양한 문자열 조작 명령어를 실습하게 됩니다.

---

## 💡 추가 팁
- CLI에서 `tab` 키를 누르면 명령어 자동완성이 됩니다
- 위/아래 화살표로 이전 명령어를 다시 실행할 수 있습니다
- `clear` 명령으로 화면을 깨끗하게 정리할 수 있습니다
- 실습 중 실수로 데이터를 삭제했다면 `flushdb` 명령 후 다시 입력하세요