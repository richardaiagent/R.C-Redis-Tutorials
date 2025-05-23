# Redis 초급 실습 06 - List 데이터 타입 실습

## 학습 목표
- Redis List 데이터 타입의 특징과 사용법을 이해한다
- 큐(Queue)와 스택(Stack) 구현 방법을 학습한다
- 채팅 메시지 및 작업 큐 시스템을 구현한다

## List 데이터 타입 개요
- **특징**: 순서가 있는 문자열 리스트
- **구현**: 양방향 연결 리스트 (Doubly Linked List)
- **용도**: 큐, 스택, 타임라인, 최근 항목 목록 등

## 실습 환경 준비
```bash
# Redis 컨테이너 실행 (이미 실행 중이라면 생략)
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

# Redis CLI 접속
docker exec -it redis-lab redis-cli
```

## 실습 1: 기본 List 명령어

### 1.1 리스트 생성 및 요소 추가
```redis
# 리스트 왼쪽에 요소 추가 (LPUSH)
LPUSH chat:room1 "안녕하세요!"
LPUSH chat:room1 "반갑습니다."
LPUSH chat:room1 "오늘 날씨가 좋네요."

# 리스트 오른쪽에 요소 추가 (RPUSH)
RPUSH chat:room1 "네, 맞아요!"
RPUSH chat:room1 "산책하기 좋은 날이에요."
```

### 1.2 리스트 조회
```redis
# 전체 리스트 조회
LRANGE chat:room1 0 -1

# 최근 3개 메시지 조회
LRANGE chat:room1 0 2

# 특정 인덱스 요소 조회
LINDEX chat:room1 0
LINDEX chat:room1 -1
```

### 1.3 리스트 길이 확인
```redis
# 리스트 길이 확인
LLEN chat:room1
```

## 실습 2: 채팅 메시지 시스템 구현

### 2.1 채팅방 메시지 저장
```redis
# 채팅방 1 메시지 (시간순으로 저장 - 최신이 위로)
LPUSH chat:general "홍길동: 안녕하세요! 처음 뵙겠습니다."
LPUSH chat:general "김영희: 반갑습니다!"
LPUSH chat:general "이철수: 오늘 회의는 몇 시인가요?"
LPUSH chat:general "박민수: 오후 2시입니다."
LPUSH chat:general "홍길동: 감사합니다."

# 채팅방 2 메시지
LPUSH chat:dev-team "개발자A: 새로운 기능 배포 준비됐습니다."
LPUSH chat:dev-team "개발자B: 테스트는 완료됐나요?"
LPUSH chat:dev-team "개발자A: 네, 모든 테스트 통과했습니다."
LPUSH chat:dev-team "팀장: 좋습니다. 내일 오전에 배포하겠습니다."
```

### 2.2 채팅 메시지 조회
```redis
# 최근 10개 메시지 조회 (일반 채팅방)
LRANGE chat:general 0 9

# 최근 5개 메시지 조회 (개발팀 채팅방)
LRANGE chat:dev-team 0 4

# 전체 메시지 수 확인
LLEN chat:general
LLEN chat:dev-team
```

### 2.3 실시간 메시지 추가 및 조회
```redis
# 새 메시지 추가 (실시간)
LPUSH chat:general "김영희: 점심 뭐 드실래요?"
LPUSH chat:general "이철수: 치킨은 어떠세요?"

# 최신 메시지 확인
LRANGE chat:general 0 2
```

## 실습 3: 작업 큐(Task Queue) 시스템 구현

### 3.1 작업 큐에 태스크 추가
```redis
# 이메일 발송 작업 큐
LPUSH email:queue "send:welcome@example.com:신규 회원 가입 환영"
LPUSH email:queue "send:admin@example.com:시스템 알림"
LPUSH email:queue "send:user123@example.com:주문 확인"
LPUSH email:queue "send:support@example.com:고객 문의 답변"

# 이미지 처리 작업 큐
LPUSH image:queue "resize:user_profile_123.jpg:200x200"
LPUSH image:queue "crop:product_img_456.jpg:300x300"
LPUSH image:queue "compress:banner_789.jpg:80%"
```

### 3.2 작업 큐 상태 확인
```redis
# 대기 중인 작업 수 확인
LLEN email:queue
LLEN image:queue

# 다음 처리할 작업 미리보기
LINDEX email:queue -1
LINDEX image:queue -1
```

### 3.3 작업 처리 (큐에서 제거)
```redis
# 이메일 작업 처리 (FIFO - 먼저 들어온 것 먼저 처리)
RPOP email:queue
RPOP email:queue

# 이미지 작업 처리
RPOP image:queue

# 처리 후 남은 작업 확인
LRANGE email:queue 0 -1
LRANGE image:queue 0 -1
```

## 실습 4: 스택(Stack) 구현 - 최근 방문 페이지

### 4.1 사용자 방문 기록 스택
```redis
# 사용자 홍길동의 페이지 방문 기록
LPUSH user:hongkildong:history "메인페이지"
LPUSH user:hongkildong:history "상품목록"
LPUSH user:hongkildong:history "상품상세/notebook-123"
LPUSH user:hongkildong:history "장바구니"
LPUSH user:hongkildong:history "결제페이지"

# 사용자 김영희의 페이지 방문 기록
LPUSH user:kimyounghee:history "메인페이지"
LPUSH user:kimyounghee:history "로그인"
LPUSH user:kimyounghee:history "마이페이지"
LPUSH user:kimyounghee:history "주문내역"
```

### 4.2 방문 기록 조회 및 관리
```redis
# 최근 방문 페이지 확인 (스택의 top)
LINDEX user:hongkildong:history 0
LINDEX user:kimyounghee:history 0

# 방문 기록 전체 조회
LRANGE user:hongkildong:history 0 -1

# 뒤로가기 구현 (최근 방문 페이지 제거)
LPOP user:hongkildong:history

# 뒤로가기 후 현재 페이지 확인
LINDEX user:hongkildong:history 0
```

### 4.3 방문 기록 제한 (최근 10개만 유지)
```redis
# 새 페이지 방문 시 기록 추가
LPUSH user:hongkildong:history "새상품페이지"

# 10개 초과 시 오래된 기록 제거
LTRIM user:hongkildong:history 0 9

# 결과 확인
LRANGE user:hongkildong:history 0 -1
LLEN user:hongkildong:history
```

## 실습 5: 타임라인 구현 - 소셜 미디어 피드

### 5.1 사용자 타임라인 생성
```redis
# 홍길동의 타임라인
LPUSH timeline:hongkildong "2024-01-15 14:30: 점심 맛있게 먹었어요! 🍕"
LPUSH timeline:hongkildong "2024-01-15 10:20: 새로운 프로젝트 시작합니다."
LPUSH timeline:hongkildong "2024-01-14 18:45: 퇴근길 카페에서 ☕"
LPUSH timeline:hongkildong "2024-01-14 12:15: 오늘 날씨 정말 좋네요!"

# 김영희의 타임라인
LPUSH timeline:kimyounghee "2024-01-15 16:00: 새 책 구매했어요 📚"
LPUSH timeline:kimyounghee "2024-01-15 09:30: 오늘도 화이팅!"
LPUSH timeline:kimyounghee "2024-01-14 20:00: 운동 완료! 💪"
```

### 5.2 타임라인 조회
```redis
# 최근 포스트 3개 조회
LRANGE timeline:hongkildong 0 2
LRANGE timeline:kimyounghee 0 2

# 전체 포스트 수 확인
LLEN timeline:hongkildong
LLEN timeline:kimyounghee
```

## 실습 6: List 고급 기능

### 6.1 리스트 간 요소 이동
```redis
# 임시 작업 리스트 생성
LPUSH temp:tasks "작업1"
LPUSH temp:tasks "작업2"
LPUSH temp:tasks "작업3"

# 진행 중 작업 리스트 생성
LPUSH progress:tasks "기존작업A"

# 작업을 temp에서 progress로 이동
RPOPLPUSH temp:tasks progress:tasks

# 결과 확인
LRANGE temp:tasks 0 -1
LRANGE progress:tasks 0 -1
```

### 6.2 블로킹 리스트 명령어 시뮬레이션
```redis
# 작업 대기 큐 생성
LPUSH wait:queue "대기작업1"
LPUSH wait:queue "대기작업2"

# 일반 POP (즉시 반환)
RPOP wait:queue

# 큐가 비어있을 때
RPOP wait:queue
RPOP wait:queue

# 큐 상태 확인
LLEN wait:queue
```

## 실습 7: 성능 및 메모리 확인

### 7.1 대량 데이터 처리
```redis
# 많은 데이터 추가 (성능 테스트)
LPUSH performance:test "데이터1"
LPUSH performance:test "데이터2"
LPUSH performance:test "데이터3"
# ... (실제로는 반복문으로 처리)

# 메모리 사용량 확인
MEMORY USAGE performance:test
```

### 7.2 데이터 정리
```redis
# 실습 데이터 정리
DEL chat:room1 chat:general chat:dev-team
DEL email:queue image:queue
DEL user:hongkildong:history user:kimyounghee:history
DEL timeline:hongkildong timeline:kimyounghee
DEL temp:tasks progress:tasks wait:queue
DEL performance:test
```

## 주요 List 명령어 정리

| 명령어 | 설명 | 예시 |
|--------|------|------|
| LPUSH | 리스트 왼쪽에 요소 추가 | LPUSH mylist "item" |
| RPUSH | 리스트 오른쪽에 요소 추가 | RPUSH mylist "item" |
| LPOP | 리스트 왼쪽 요소 제거 후 반환 | LPOP mylist |
| RPOP | 리스트 오른쪽 요소 제거 후 반환 | RPOP mylist |
| LRANGE | 리스트 범위 조회 | LRANGE mylist 0 -1 |
| LLEN | 리스트 길이 반환 | LLEN mylist |
| LINDEX | 특정 인덱스 요소 조회 | LINDEX mylist 0 |
| LTRIM | 리스트를 지정 범위로 자르기 | LTRIM mylist 0 9 |

## 실무 활용 패턴

### 1. 최근 활동 목록
- 사용자의 최근 로그인, 구매, 조회 기록
- `LPUSH`로 추가, `LTRIM`으로 개수 제한

### 2. 메시지 큐 시스템
- 비동기 작업 처리를 위한 큐
- `LPUSH`로 추가, `RPOP`으로 처리

### 3. 알림 시스템
- 사용자별 알림 목록
- 시간순 정렬이 자동으로 유지됨

## 다음 실습 예고
다음 실습에서는 **Set 데이터 타입**을 학습하여 중복을 허용하지 않는 집합 데이터를 다루는 방법을 배워보겠습니다.

## 체크리스트
- [ ] List의 기본 개념 이해
- [ ] 채팅 메시지 시스템 구현 완료
- [ ] 작업 큐 시스템 구현 완료
- [ ] 스택 기능 구현 완료
- [ ] 타임라인 기능 구현 완료
- [ ] 주요 명령어 숙지 완료