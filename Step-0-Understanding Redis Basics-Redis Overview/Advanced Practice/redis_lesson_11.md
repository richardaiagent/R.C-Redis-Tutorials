# Redis 중급 11강 - Bitmap 데이터 타입 실습

## 🎯 학습 목표
- Bitmap 데이터 타입의 개념과 활용법 이해
- 사용자 활동 추적 시스템 구현
- 일별 사용자 로그인 상태 비트맵 구현

## 📚 이론 학습

### Bitmap이란?
- Redis에서 String 타입을 비트 단위로 조작할 수 있는 기능
- 메모리 효율적으로 대량의 boolean 값을 저장 가능
- 최대 2^32 비트(512MB) 까지 저장 가능

### 주요 명령어
- `SETBIT key offset value`: 특정 비트 설정
- `GETBIT key offset`: 특정 비트 조회
- `BITCOUNT key [start end]`: 설정된 비트 개수 계산
- `BITOP operation destkey key1 key2...`: 비트 연산 수행

## 🛠 실습 환경 준비

```bash
# Redis 컨테이너 실행 (이미 실행 중이면 생략)
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

# Redis CLI 접속
docker exec -it redis-lab redis-cli
```

## 💻 실습 1: 기본 Bitmap 조작

```redis
# 사용자 ID 1번이 1일차에 로그인 (비트 1 설정)
SETBIT user:login:day1 1 1

# 사용자 ID 5번이 1일차에 로그인
SETBIT user:login:day1 5 1

# 사용자 ID 10번이 1일차에 로그인
SETBIT user:login:day1 10 1

# 1일차 특정 사용자 로그인 상태 확인
GETBIT user:login:day1 1    # 결과: 1 (로그인함)
GETBIT user:login:day1 2    # 결과: 0 (로그인 안함)
GETBIT user:login:day1 5    # 결과: 1 (로그인함)

# 1일차 총 로그인 사용자 수
BITCOUNT user:login:day1    # 결과: 3
```

## 💻 실습 2: 일별 사용자 로그인 상태 비트맵 구현

```redis
# 2일차 로그인 데이터 생성
SETBIT user:login:day2 2 1   # 사용자 2번 로그인
SETBIT user:login:day2 5 1   # 사용자 5번 로그인 (연속 접속)
SETBIT user:login:day2 8 1   # 사용자 8번 로그인

# 3일차 로그인 데이터 생성
SETBIT user:login:day3 1 1   # 사용자 1번 로그인 (연속 접속)
SETBIT user:login:day3 3 1   # 사용자 3번 로그인
SETBIT user:login:day3 5 1   # 사용자 5번 로그인 (연속 접속)
SETBIT user:login:day3 7 1   # 사용자 7번 로그인

# 각 일차별 로그인 사용자 수 확인
BITCOUNT user:login:day1     # 결과: 3명
BITCOUNT user:login:day2     # 결과: 3명
BITCOUNT user:login:day3     # 결과: 4명
```

## 💻 실습 3: 비트 연산을 활용한 분석

```redis
# 1일차와 2일차 모두 로그인한 사용자 (AND 연산)
BITOP AND user:login:day1_and_day2 user:login:day1 user:login:day2
BITCOUNT user:login:day1_and_day2   # 결과: 1명 (사용자 5번)

# 1일차 또는 2일차에 로그인한 사용자 (OR 연산)
BITOP OR user:login:day1_or_day2 user:login:day1 user:login:day2
BITCOUNT user:login:day1_or_day2    # 결과: 5명

# 1일차에는 로그인했지만 2일차에는 안한 사용자 (XOR 연산)
BITOP XOR user:login:day1_xor_day2 user:login:day1 user:login:day2
BITCOUNT user:login:day1_xor_day2   # 결과: 4명

# 3일 연속 로그인한 사용자 찾기
BITOP AND temp1 user:login:day1 user:login:day2
BITOP AND user:login:3days_streak temp1 user:login:day3
BITCOUNT user:login:3days_streak    # 결과: 1명 (사용자 5번)
```

## 💻 실습 4: 월별 출석 체크 시스템

```redis
# 2024년 1월 사용자별 출석 (사용자 ID를 offset으로 사용)
# 1월 1일 출석 데이터
SETBIT attendance:2024:01:01 100 1  # 사용자 100번 출석
SETBIT attendance:2024:01:01 101 1  # 사용자 101번 출석
SETBIT attendance:2024:01:01 102 1  # 사용자 102번 출석

# 1월 2일 출석 데이터
SETBIT attendance:2024:01:02 100 1  # 사용자 100번 연속 출석
SETBIT attendance:2024:01:02 103 1  # 사용자 103번 출석

# 1월 3일 출석 데이터
SETBIT attendance:2024:01:03 101 1  # 사용자 101번 출석
SETBIT attendance:2024:01:03 102 1  # 사용자 102번 출석
SETBIT attendance:2024:01:03 103 1  # 사용자 103번 출석

# 특정 사용자의 출석 확인
GETBIT attendance:2024:01:01 100    # 1월 1일 사용자 100번: 1
GETBIT attendance:2024:01:02 100    # 1월 2일 사용자 100번: 1
GETBIT attendance:2024:01:03 100    # 1월 3일 사용자 100번: 0

# 일별 출석 인원 확인
BITCOUNT attendance:2024:01:01      # 1월 1일: 3명
BITCOUNT attendance:2024:01:02      # 1월 2일: 2명
BITCOUNT attendance:2024:01:03      # 1월 3일: 3명
```

## 💻 실습 5: 활성 사용자 분석

```redis
# 주간 활성 사용자 분석을 위한 더 많은 데이터 생성
SETBIT weekly:user:activity 50 1    # 사용자 50번 활성
SETBIT weekly:user:activity 51 1    # 사용자 51번 활성
SETBIT weekly:user:activity 52 1    # 사용자 52번 활성
SETBIT weekly:user:activity 100 1   # 사용자 100번 활성
SETBIT weekly:user:activity 101 1   # 사용자 101번 활성
SETBIT weekly:user:activity 200 1   # 사용자 200번 활성
SETBIT weekly:user:activity 300 1   # 사용자 300번 활성

# 특정 범위의 활성 사용자 수 확인
BITCOUNT weekly:user:activity 0 10     # 사용자 ID 0~79 범위의 활성 사용자
BITCOUNT weekly:user:activity 10 20    # 사용자 ID 80~159 범위의 활성 사용자

# 전체 활성 사용자 수
BITCOUNT weekly:user:activity          # 전체 활성 사용자: 7명
```

## 🔍 실습 결과 확인

```redis
# 모든 키 확인
KEYS *login*
KEYS *attendance*
KEYS *activity*

# 메모리 사용량 확인
MEMORY USAGE user:login:day1
MEMORY USAGE attendance:2024:01:01
MEMORY USAGE weekly:user:activity

# 키의 타입 확인 (String으로 표시됨)
TYPE user:login:day1
```

## 📊 성능 특성 이해

### Bitmap의 장점
1. **메모리 효율성**: 1비트당 1개의 boolean 값 저장
2. **빠른 연산**: 비트 연산을 통한 고속 처리
3. **대용량 처리**: 수백만 사용자도 효율적으로 처리 가능

### 사용 사례
- 일일 활성 사용자 추적
- 출석 체크 시스템
- A/B 테스트 그룹 관리
- 권한 관리 시스템

## 🎯 응용 문제

1. **문제 1**: 한 달(30일) 동안의 사용자 출석 데이터를 생성하고, 15일 이상 출석한 사용자를 찾는 시스템을 구현해보세요.

2. **문제 2**: 요일별 로그인 패턴을 분석할 수 있는 비트맵 시스템을 설계해보세요.

## 💡 실무 연계 포인트

- **사용자 세그멘테이션**: 활성도에 따른 사용자 그룹 분류
- **리텐션 분석**: 사용자 재방문율 측정
- **실시간 대시보드**: 일일 활성 사용자 수 실시간 모니터링
- **마케팅 타겟팅**: 특정 기간 활성 사용자 대상 캠페인

## ✅ 학습 완료 체크리스트

- [ ] Bitmap 기본 개념 이해
- [ ] SETBIT, GETBIT 명령어 실습 완료
- [ ] BITCOUNT를 활용한 통계 계산 실습 완료
- [ ] BITOP를 활용한 비트 연산 실습 완료
- [ ] 일별 로그인 상태 비트맵 구현 완료
- [ ] 출석 체크 시스템 구현 완료
- [ ] 메모리 효율성 이해 완료
- [ ] 응용 문제 해결 완료