# Redis 초급 6번 - List 데이터 타입 실습 교안

## 📋 학습 목표
- Redis List 데이터 타입의 개념과 특징 이해
- List 관련 주요 명령어 습득 (LPUSH, RPUSH, LPOP, RPOP 등)
- 큐(Queue)와 스택(Stack) 구현을 통한 List 활용법 학습
- 실시간 채팅 메시지 시스템과 작업 큐 시뮬레이션 구현
- List의 성능 특성 및 실무 활용 방안 이해

## 🐳 실습 환경 준비

### Redis 컨테이너 실행 확인
```powershell
# PowerShell에서 Redis 컨테이너 상태 확인
docker ps --filter "name=redis-lab"

# Redis 컨테이너가 없는 경우 실행
docker run -d --name redis-lab -p 6379:6379 -v redis-data:/data redis:7-alpine

# Redis CLI 접속
docker exec -it redis-lab redis-cli
```

## 📚 List 데이터 타입 이론

### List란?
- **정의**: 순서가 있는 문자열 컬렉션 (연결 리스트 구조)
- **특징**: 
  - 양쪽 끝에서 빠른 삽입/삭제 (O(1))
  - 인덱스 기반 접근 가능
  - 중복 값 허용
  - 최대 2^32 - 1개 요소 저장 가능
- **용도**: 큐, 스택, 타임라인, 메시지 큐, 최근 항목 목록

### List vs Array 비교
| 구분 | Redis List | 일반 Array |
|------|------------|------------|
| 구조 | 연결 리스트 | 연속 메모리 |
| 앞/뒤 삽입 | O(1) | O(n) |
| 중간 접근 | O(n) | O(1) |
| 메모리 효율성 | 낮음 | 높음 |
| 적합한 용도 | 큐/스택 | 랜덤 액세스 |

## 🛠 주요 List 명령어

### 삽입 명령어
- `LPUSH key element [element ...]` - 왼쪽(앞)에 요소 추가
- `RPUSH key element [element ...]` - 오른쪽(뒤)에 요소 추가
- `LPUSHX key element [element ...]` - 리스트가 존재할 때만 왼쪽에 추가
- `RPUSHX key element [element ...]` - 리스트가 존재할 때만 오른쪽에 추가
- `LINSERT key BEFORE|AFTER pivot element` - 특정 요소 앞/뒤에 삽입

### 조회 명령어
- `LRANGE key start stop` - 범위 내 요소들 조회
- `LINDEX key index` - 특정 인덱스 요소 조회  
- `LLEN key` - 리스트 길이 조회

### 제거 명령어
- `LPOP key [count]` - 왼쪽에서 요소 제거 및 반환
- `RPOP key [count]` - 오른쪽에서 요소 제거 및 반환
- `LREM key count element` - 특정 요소 제거
- `LTRIM key start stop` - 범위 외 요소 모두 제거

### 수정 명령어
- `LSET key index element` - 특정 인덱스 요소 값 변경

### 블로킹 명령어
- `BLPOP key [key ...] timeout` - 블로킹 왼쪽 팝
- `BRPOP key [key ...] timeout` - 블로킹 오른쪽 팝

## 💡 실습 1: List 기본 조작

### Redis CLI 접속
```powershell
docker exec -it redis-lab redis-cli
```

### 1-1. 요소 추가 및 확인
```redis
# 오른쪽(뒤)에 요소 추가
RPUSH fruits "사과"
RPUSH fruits "바나나" "오렌지" "포도"

# 리스트 전체 조회 (0부터 -1까지 = 전체)
LRANGE fruits 0 -1

# 왼쪽(앞)에 요소 추가
LPUSH fruits "딸기" "키위"

# 변경된 결과 확인
LRANGE fruits 0 -1

# 리스트 길이 확인
LLEN fruits
```

### 1-2. 인덱스 기반 접근
```redis
# 특정 인덱스 요소 조회 (0부터 시작)
LINDEX fruits 0    # 첫 번째 요소
LINDEX fruits 1    # 두 번째 요소
LINDEX fruits -1   # 마지막 요소
LINDEX fruits -2   # 마지막에서 두 번째 요소

# 범위 조회
LRANGE fruits 0 2      # 처음 3개
LRANGE fruits 2 4      # 3번째부터 5번째까지
LRANGE fruits -3 -1    # 마지막 3개
```

### 1-3. 요소 제거
```redis
# 왼쪽에서 요소 제거
LPOP fruits
LRANGE fruits 0 -1

# 오른쪽에서 요소 제거
RPOP fruits
LRANGE fruits 0 -1

# 여러 개 동시 제거 (Redis 6.2+)
RPOP fruits 2
LRANGE fruits 0 -1
```

## 💡 실습 2: 스택(Stack) 구현

### 2-1. LIFO (Last In, First Out) 스택
```redis
# 스택 초기화
DEL stack_demo

# 스택에 데이터 푸시 (LPUSH 사용)
LPUSH stack_demo "첫 번째 작업"
LPUSH stack_demo "두 번째 작업"
LPUSH stack_demo "세 번째 작업"
LPUSH stack_demo "네 번째 작업"

# 스택 상태 확인
LRANGE stack_demo 0 -1
LLEN stack_demo

# 스택에서 팝 (LPOP 사용)
LPOP stack_demo
LRANGE stack_demo 0 -1

LPOP stack_demo
LRANGE stack_demo 0 -1
```

### 2-2. 함수 호출 스택 시뮬레이션
```redis
# 함수 호출 스택 생성
DEL call_stack

# 함수 호출 시뮬레이션
LPUSH call_stack "main()"
LPUSH call_stack "calculateTotal()"
LPUSH call_stack "validateInput()"
LPUSH call_stack "parseData()"

# 현재 호출 스택 상태
LRANGE call_stack 0 -1

# 함수 실행 완료 시뮬레이션 (역순으로 제거)
LPOP call_stack  # parseData() 완료
LPOP call_stack  # validateInput() 완료
LRANGE call_stack 0 -1

LPOP call_stack  # calculateTotal() 완료
LPOP call_stack  # main() 완료
LLEN call_stack  # 스택 비어있음 확인
```

## 💡 실습 3: 큐(Queue) 구현

### 3-1. FIFO (First In, First Out) 큐
```redis
# 큐 초기화
DEL queue_demo

# 큐에 작업 추가 (RPUSH 사용 - 뒤에서 추가)
RPUSH queue_demo "작업1: 이메일 발송"
RPUSH queue_demo "작업2: 데이터 백업"
RPUSH queue_demo "작업3: 리포트 생성"
RPUSH queue_demo "작업4: 로그 정리"

# 큐 상태 확인
LRANGE queue_demo 0 -1
LLEN queue_demo

# 큐에서 작업 처리 (LPOP 사용 - 앞에서 제거)
LPOP queue_demo  # 작업1 처리
LRANGE queue_demo 0 -1

LPOP queue_demo  # 작업2 처리
LRANGE queue_demo 0 -1
```

### 3-2. 프린터 대기열 시뮬레이션
```redis
# 프린터 큐 생성
DEL printer_queue

# 인쇄 작업 대기열 추가
RPUSH printer_queue "문서1.pdf (김철수)"
RPUSH printer_queue "보고서.docx (이영희)"
RPUSH printer_queue "계약서.pdf (박민수)"
RPUSH printer_queue "프레젠테이션.pptx (정지원)"

# 현재 대기열 확인
LRANGE printer_queue 0 -1

# 인쇄 작업 처리
LPOP printer_queue  # 첫 번째 작업 인쇄 완료
LRANGE printer_queue 0 -1

# 새 작업 추가
RPUSH printer_queue "신규문서.pdf (최호영)"
LRANGE printer_queue 0 -1

# 계속 처리
LPOP printer_queue
LPOP printer_queue
LRANGE printer_queue 0 -1
```

## 💡 실습 4: 실시간 채팅 메시지 시스템

### 4-1. 채팅방 메시지 저장
```redis
# 채팅방 생성 및 메시지 추가
DEL chatroom:general

# 메시지 추가 (시간순으로 RPUSH 사용)
RPUSH chatroom:general "[09:00] 김철수: 안녕하세요!"
RPUSH chatroom:general "[09:01] 이영희: 좋은 아침입니다~"
RPUSH chatroom:general "[09:02] 박민수: 오늘 회의 몇시에 시작하나요?"
RPUSH chatroom:general "[09:03] 김철수: 오전 10시입니다"
RPUSH chatroom:general "[09:04] 정지원: 준비하겠습니다"

# 전체 채팅 내역 확인
LRANGE chatroom:general 0 -1

# 최근 3개 메시지만 조회
LRANGE chatroom:general -3 -1

# 메시지 개수 확인
LLEN chatroom:general
```

### 4-2. 다중 채팅방 관리
```redis
# 개발팀 채팅방
RPUSH chatroom:dev "[09:10] 개발자A: 배포 준비 완료했습니다"
RPUSH chatroom:dev "[09:11] 개발자B: 테스트 케이스 추가했어요"
RPUSH chatroom:dev "[09:12] 팀장: 수고하셨습니다!"

# 마케팅팀 채팅방
RPUSH chatroom:marketing "[09:15] 마케터A: 캠페인 결과 나왔어요"
RPUSH chatroom:marketing "[09:16] 마케터B: 어떤 결과인가요?"
RPUSH chatroom:marketing "[09:17] 마케터A: 전환율이 15% 증가했습니다!"

# 각 채팅방 최근 메시지 확인
LRANGE chatroom:dev -2 -1
LRANGE chatroom:marketing -2 -1

# 전체 채팅방 목록 (키 패턴 검색)
KEYS chatroom:*
```

### 4-3. 메시지 히스토리 관리 (최근 100개만 유지)
```redis
# 대량 메시지 추가 시뮬레이션
RPUSH chatroom:general "[09:05] 사용자1: 메시지1"
RPUSH chatroom:general "[09:06] 사용자2: 메시지2"
RPUSH chatroom:general "[09:07] 사용자3: 메시지3"
RPUSH chatroom:general "[09:08] 사용자4: 메시지4"
RPUSH chatroom:general "[09:09] 사용자5: 메시지5"

# 현재 메시지 수 확인
LLEN chatroom:general

# 최근 5개 메시지만 유지 (LTRIM 사용)
LTRIM chatroom:general -5 -1

# 트림 결과 확인
LRANGE chatroom:general 0 -1
LLEN chatroom:general
```

## 💡 실습 5: 작업 큐 시뮬레이션

### 5-1. 이메일 발송 작업 큐
```redis
# 이메일 발송 큐 생성
DEL email_queue

# 발송할 이메일 작업 추가
RPUSH email_queue '{"to":"user1@example.com","subject":"환영합니다","type":"welcome"}'
RPUSH email_queue '{"to":"user2@example.com","subject":"비밀번호 재설정","type":"password"}'
RPUSH email_queue '{"to":"user3@example.com","subject":"주문 확인","type":"order"}'
RPUSH email_queue '{"to":"user4@example.com","subject":"프로모션 안내","type":"promotion"}'

# 대기 중인 작업 확인
LRANGE email_queue 0 -1
LLEN email_queue

# 작업 처리 (워커 프로세스 시뮬레이션)
LPOP email_queue  # 첫 번째 이메일 처리
LPOP email_queue  # 두 번째 이메일 처리

# 남은 작업 확인
LRANGE email_queue 0 -1

# 새로운 작업 추가
RPUSH email_queue '{"to":"user5@example.com","subject":"뉴스레터","type":"newsletter"}'
LRANGE email_queue 0 -1
```

### 5-2. 우선순위별 작업 큐
```redis
# 높은 우선순위 작업 큐
DEL high_priority_queue
RPUSH high_priority_queue "긴급: 서버 점검 알림"
RPUSH high_priority_queue "긴급: 보안 업데이트"

# 일반 우선순위 작업 큐  
DEL normal_priority_queue
RPUSH normal_priority_queue "일반: 월간 리포트 생성"
RPUSH normal_priority_queue "일반: 데이터 백업"
RPUSH normal_priority_queue "일반: 로그 정리"

# 우선순위별 처리 시뮬레이션
# 1. 높은 우선순위 먼저 처리
LLEN high_priority_queue
LLEN normal_priority_queue

# 높은 우선순위 작업 처리
LPOP high_priority_queue
LRANGE high_priority_queue 0 -1

# 높은 우선순위가 모두 처리되면 일반 우선순위 처리
LPOP normal_priority_queue
LRANGE normal_priority_queue 0 -1
```

## 💡 실습 6: 소셜 미디어 타임라인

### 6-1. 사용자 타임라인 구현  
```redis
# 사용자별 타임라인 생성
DEL timeline:kim_user
DEL timeline:lee_user

# 김사용자 타임라인
RPUSH timeline:kim_user "2024-05-23 09:00 - 아침 산책 완료! 🚶‍♂️"
RPUSH timeline:kim_user "2024-05-23 09:30 - 맛있는 브런치 🥞"
RPUSH timeline:kim_user "2024-05-23 10:15 - 새로운 프로젝트 시작!"
RPUSH timeline:kim_user "2024-05-23 11:00 - 팀 회의 참석 💼"

# 이사용자 타임라인
RPUSH timeline:lee_user "2024-05-23 08:45 - 조깅 완료 🏃‍♀️"
RPUSH timeline:lee_user "2024-05-23 09:20 - 독서 시간 📚"
RPUSH timeline:lee_user "2024-05-23 10:00 - 코딩 스터디 참석"
RPUSH timeline:lee_user "2024-05-23 10:45 - 점심 메뉴 고민 중... 🤔"

# 각 사용자 타임라인 확인
LRANGE timeline:kim_user 0 -1
LRANGE timeline:lee_user 0 -1

# 최근 2개 포스트만 조회
LRANGE timeline:kim_user -2 -1
LRANGE timeline:lee_user -2 -1
```

### 6-2. 글로벌 피드 구현
```redis
# 전체 공개 피드
DEL global_feed

# 시간순으로 모든 사용자의 공개 포스트 추가
RPUSH global_feed "김사용자: 새로운 프로젝트 시작! #개발 #새시작"
RPUSH global_feed "이사용자: 코딩 스터디에서 많이 배웠어요 #학습 #성장"
RPUSH global_feed "박사용자: 오늘 날씨가 정말 좋네요 ☀️ #날씨 #행복"
RPUSH global_feed "김사용자: 점심 추천 받습니다! #음식 #추천"
RPUSH global_feed "정사용자: 새로운 책을 읽기 시작했어요 📖 #독서"

# 글로벌 피드 확인
LRANGE global_feed 0 -1

# 최신 3개 포스트만 표시
LRANGE global_feed -3 -1

# 피드 개수 확인
LLEN global_feed
```

## 💡 실습 7: 고급 List 활용

### 7-1. 특정 요소 조작
```redis
# 테스트 리스트 생성
DEL test_list
RPUSH test_list "A" "B" "C" "B" "D" "B" "E"

# 전체 확인
LRANGE test_list 0 -1

# 특정 인덱스 값 변경
LSET test_list 2 "NEW_C"
LRANGE test_list 0 -1

# 특정 값 제거 (앞에서부터 2개의 "B" 제거)
LREM test_list 2 "B"
LRANGE test_list 0 -1

# 특정 위치에 요소 삽입
LINSERT test_list BEFORE "D" "BEFORE_D"
LINSERT test_list AFTER "D" "AFTER_D"
LRANGE test_list 0 -1
```

### 7-2. 조건부 삽입
```redis
# 리스트가 존재할 때만 요소 추가
DEL conditional_list

# 리스트가 없으므로 실패
LPUSHX conditional_list "첫 번째"
LLEN conditional_list

# 먼저 리스트 생성
LPUSH conditional_list "초기값"
LRANGE conditional_list 0 -1

# 이제 성공
LPUSHX conditional_list "두 번째"
RPUSHX conditional_list "세 번째"
LRANGE conditional_list 0 -1
```

## 💡 실습 8: 블로킹 큐 (고급)

### 8-1. 블로킹 팝 기본 사용법
```redis
# 빈 큐에서 블로킹 팝 (5초 타임아웃)
# 주의: 이 명령어는 5초간 대기하므로 테스트 시 참고
DEL blocking_queue
# BLPOP blocking_queue 5  # 5초 후 타임아웃

# 다른 터미널에서 데이터 추가 후 테스트
RPUSH blocking_queue "메시지1"

# 이제 즉시 반환됨
BLPOP blocking_queue 5
```

### 8-2. 다중 큐 블로킹
```redis
# 여러 큐 생성
DEL queue1 queue2 queue3
RPUSH queue2 "queue2의 메시지"
RPUSH queue3 "queue3의 메시지"

# 여러 큐 중 데이터가 있는 첫 번째 큐에서 팝
BLPOP queue1 queue2 queue3 10

# 결과: queue2에서 메시지 반환
LRANGE queue2 0 -1
```

## 📊 성능 및 메모리 분석

### List vs Hash vs Set 메모리 비교
```redis
# 동일한 데이터를 다른 타입으로 저장하고 메모리 사용량 비교
DEL list_data hash_data set_data

# List로 저장
RPUSH list_data "data1" "data2" "data3" "data4" "data5"

# Hash로 저장
HMSET hash_data field1 "data1" field2 "data2" field3 "data3" field4 "data4" field5 "data5"

# Set으로 저장
SADD set_data "data1" "data2" "data3" "data4" "data5"

# 메모리 사용량 비교
MEMORY USAGE list_data
MEMORY USAGE hash_data  
MEMORY USAGE set_data

# 각 타입별 특성 확인
TYPE list_data
TYPE hash_data
TYPE set_data
```

## 🎯 심화 학습 과제

### 과제 1: 게시판 댓글 시스템
다음 요구사항을 List로 구현하세요:
- 게시글별 댓글 저장 (post:1:comments)
- 댓글 추가/삭제 기능
- 최신 댓글 우선 표시
- 댓글 페이징 기능

### 과제 2: 실시간 알림 시스템
사용자별 알림 큐를 구현하세요:
- 사용자별 알림 저장
- 읽지 않은 알림 카운트
- 알림 만료 처리
- 알림 우선순위 관리

### 과제 3: 로그 수집 시스템
애플리케이션 로그를 List로 관리하세요:
- 로그 레벨별 분류 (ERROR, WARN, INFO)
- 최근 1000개 로그만 유지
- 로그 검색 기능
- 통계 정보 제공

## 💡 실무 팁

### 1. List 사용 시점
- **적합한 경우**: 순서가 중요한 데이터, 큐/스택 구현, 타임라인
- **부적합한 경우**: 중간 요소 검색이 빈번한 경우, 정렬이 필요한 경우

### 2. 성능 최적화
- 리스트 크기를 적절히 제한 (LTRIM 활용)
- 중간 인덱스 접근보다 양 끝 접근 활용
- 대용량 리스트는 분할 고려

### 3. 메모리 관리
- 불필요한 요소 정기적 제거
- 리스트 크기 모니터링
- 압축 가능한 데이터는 압축 후 저장

## ✅ 학습 완료 체크리스트

### 기본 List 조작
- [ ] LPUSH, RPUSH를 통한 요소 추가
- [ ] LPOP, RPOP를 통한 요소 제거  
- [ ] LRANGE를 통한 범위 조회
- [ ] LLEN을 통한 길이 확인

### 응용 구현
- [ ] 스택(Stack) 구현 (LIFO)
- [ ] 큐(Queue) 구현 (FIFO)
- [ ] 채팅 메시지 시스템 구현
- [ ] 작업 큐 시스템 구현

### 고급 기능
- [ ] LSET, LREM을 통한 요소 수정/삭제
- [ ] LINSERT를 통한 특정 위치 삽입
- [ ] LTRIM을 통한 리스트 크기 관리
- [ ] 블로킹 명령어 이해 (BLPOP, BRPOP)

### 실무 활용
- [ ] 소셜 미디어 타임라인 구현
- [ ] 다중 우선순위 큐 관리
- [ ] 메모리 사용량 분석 및 최적화
- [ ] 성능 특성 이해

## 🔗 다음 단계
다음은 **초급 7번 - Set 데이터 타입 실습**입니다. List를 통해 순서가 있는 컬렉션을 익혔으니, 이제 중복을 허용하지 않는 집합 데이터인 Set을 학습해보겠습니다.

---
*본 교안은 Docker Redis 7 Alpine 환경과 Windows PowerShell을 기준으로 작성되었습니다.*