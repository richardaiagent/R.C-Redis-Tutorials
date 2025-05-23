# Redis 중급 12강 - HyperLogLog 실습

## 🎯 학습 목표
- HyperLogLog 데이터 타입의 개념과 활용법 이해
- 대용량 고유 카운터 시스템 구현
- 일일 순 방문자 수 추정 시스템 구현

## 📚 이론 학습

### HyperLogLog란?
- 확률적 데이터 구조를 사용하여 대용량 데이터의 고유 원소 개수를 추정
- 메모리 사용량이 매우 적음 (최대 12KB)
- 표준 오차 0.81%의 정확도로 2^64개의 고유 원소까지 추정 가능

### 주요 명령어
- `PFADD key element1 element2...`: 원소 추가
- `PFCOUNT key1 key2...`: 고유 원소 개수 추정
- `PFMERGE destkey sourcekey1 sourcekey2...`: HyperLogLog 병합

## 🛠 실습 환경 준비

```bash
# Redis 컨테이너 실행 (이미 실행 중이면 생략)
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

# Redis CLI 접속
docker exec -it redis-lab redis-cli
```

## 💻 실습 1: HyperLogLog 기본 조작

```redis
# 일일 방문자 HyperLogLog 생성 및 방문자 추가
PFADD visitors:2024:01:15 user1 user2 user3 user4 user5

# 추가 방문자 등록
PFADD visitors:2024:01:15 user6 user7 user8 user9 user10

# 중복 방문자 등록 (중복은 카운트되지 않음)
PFADD visitors:2024:01:15 user1 user2 user3

# 고유 방문자 수 확인
PFCOUNT visitors:2024:01:15    # 결과: 10 (중복 제거됨)

# 새로운 방문자 추가
PFADD visitors:2024:01:15 user11 user12 user13 user14 user15
PFCOUNT visitors:2024:01:15    # 결과: 15
```

## 💻 실습 2: 일일 순 방문자 수 추정 시스템

```redis
# 1월 15일 방문자 데이터 (이미 위에서 생성)
# 추가 방문자 등록
PFADD visitors:2024:01:15 user16 user17 user18 user19 user20
PFADD visitors:2024:01:15 user21 user22 user23 user24 user25

# 1월 16일 방문자 데이터 생성
PFADD visitors:2024:01:16 user1 user3 user5 user7 user9      # 기존 사용자 재방문
PFADD visitors:2024:01:16 user26 user27 user28 user29 user30 # 새로운 사용자
PFADD visitors:2024:01:16 user31 user32 user33 user34 user35
PFADD visitors:2024:01:16 user36 user37 user38 user39 user40

# 1월 17일 방문자 데이터 생성
PFADD visitors:2024:01:17 user2 user4 user6 user8 user10     # 기존 사용자
PFADD visitors:2024:01:17 user15 user20 user25 user30 user35 # 최근 사용자
PFADD visitors:2024:01:17 user41 user42 user43 user44 user45 # 새로운 사용자
PFADD visitors:2024:01:17 user46 user47 user48 user49 user50

# 각 일별 고유 방문자 수 확인
PFCOUNT visitors:2024:01:15    # 1월 15일 방문자 수
PFCOUNT visitors:2024:01:16    # 1월 16일 방문자 수
PFCOUNT visitors:2024:01:17    # 1월 17일 방문자 수
```

## 💻 실습 3: HyperLogLog 병합을 활용한 기간별 분석

```redis
# 주간 방문자 통계 (1월 15일~17일 병합)
PFMERGE visitors:2024:week03 visitors:2024:01:15 visitors:2024:01:16 visitors:2024:01:17

# 3일간 총 고유 방문자 수 확인
PFCOUNT visitors:2024:week03   # 3일간 중복 제거된 총 방문자 수

# 1월 18일 추가 데이터
PFADD visitors:2024:01:18 user51 user52 user53 user54 user55
PFADD visitors:2024:01:18 user1 user10 user20 user30 user40  # 기존 사용자 재방문
PFADD visitors:2024:01:18 user56 user57 user58 user59 user60

# 1월 19일 추가 데이터
PFADD visitors:2024:01:19 user61 user62 user63 user64 user65
PFADD visitors:2024:01:19 user5 user15 user25 user35 user45  # 기존 사용자 재방문
PFADD visitors:2024:01:19 user66 user67 user68 user69 user70

# 5일간 총 방문자 통계
PFMERGE visitors:2024:week03_extended visitors:2024:week03 visitors:2024:01:18 visitors:2024:01:19
PFCOUNT visitors:2024:week03_extended
```

## 💻 실습 4: 대용량 데이터로 정확도 테스트

```redis
# 대량의 사용자 데이터 시뮬레이션 (페이지별 방문자)
PFADD page:home:visitors user1001 user1002 user1003 user1004 user1005
PFADD page:home:visitors user1006 user1007 user1008 user1009 user1010
PFADD page:home:visitors user1011 user1012 user1013 user1014 user1015
PFADD page:home:visitors user1016 user1017 user1018 user1019 user1020

PFADD page:product:visitors user1001 user1003 user1005 user1007 user1009  # 일부 중복
PFADD page:product:visitors user2001 user2002 user2003 user2004 user2005  # 새로운 사용자
PFADD page:product:visitors user2006 user2007 user2008 user2009 user2010

PFADD page:cart:visitors user1001 user1005 user1010 user1015 user1020     # 일부 중복
PFADD page:cart:visitors user2001 user2005 user2010                       # 일부 중복
PFADD page:cart:visitors user3001 user3002 user3003 user3004 user3005     # 새로운 사용자

# 각 페이지별 고유 방문자 수
PFCOUNT page:home:visitors     # 홈페이지 방문자
PFCOUNT page:product:visitors  # 상품페이지 방문자  
PFCOUNT page:cart:visitors     # 장바구니페이지 방문자

# 전체 사이트 고유 방문자 수 (모든 페이지 병합)
PFMERGE site:total:visitors page:home:visitors page:product:visitors page:cart:visitors
PFCOUNT site:total:visitors
```

## 💻 실습 5: 모바일/웹 플랫폼별 분석

```redis
# 모바일 앱 방문자
PFADD platform:mobile:2024:01:20 mobile_user_001 mobile_user_002 mobile_user_003
PFADD platform:mobile:2024:01:20 mobile_user_004 mobile_user_005 mobile_user_006
PFADD platform:mobile:2024:01:20 mobile_user_007 mobile_user_008 mobile_user_009
PFADD platform:mobile:2024:01:20 mobile_user_010 mobile_user_011 mobile_user_012

# 웹 브라우저 방문자
PFADD platform:web:2024:01:20 web_user_001 web_user_002 web_user_003
PFADD platform:web:2024:01:20 web_user_004 web_user_005 web_user_006
PFADD platform:web:2024:01:20 web_user_007 web_user_008 web_user_009
PFADD platform:web:2024:01:20 web_user_010 web_user_011 web_user_012

# 크로스 플랫폼 사용자 (동일한 사용자가 두 플랫폼 모두 사용)
PFADD platform:mobile:2024:01:20 cross_user_001 cross_user_002 cross_user_003
PFADD platform:web:2024:01:20 cross_user_001 cross_user_002 cross_user_003

# 플랫폼별 고유 사용자 수
PFCOUNT platform:mobile:2024:01:20  # 모바일 고유 사용자
PFCOUNT platform:web:2024:01:20     # 웹 고유 사용자

# 전체 플랫폼 통합 고유 사용자 수
PFMERGE platform:total:2024:01:20 platform:mobile:2024:01:20 platform:web:2024:01:20
PFCOUNT platform:total:2024:01:20   # 중복 제거된 전체 고유 사용자
```

## 💻 실습 6: 시간대별 방문자 분석

```redis
# 오전 시간대 (09:00-12:00) 방문자
PFADD hour:morning:visitors morning_001 morning_002 morning_003 morning_004
PFADD hour:morning:visitors morning_005 morning_006 morning_007 morning_008

# 오후 시간대 (12:00-18:00) 방문자
PFADD hour:afternoon:visitors afternoon_001 afternoon_002 afternoon_003
PFADD hour:afternoon:visitors morning_001 morning_003 morning_005  # 오전 사용자 일부 재방문
PFADD hour:afternoon:visitors afternoon_004 afternoon_005 afternoon_006

# 저녁 시간대 (18:00-24:00) 방문자
PFADD hour:evening:visitors evening_001 evening_002 evening_003 evening_004
PFADD hour:evening:visitors morning_002 morning_004 morning_006    # 오전 사용자 일부 재방문
PFADD hour:evening:visitors afternoon_002 afternoon_004 afternoon_006  # 오후 사용자 일부 재방문

# 시간대별 고유 방문자 수
PFCOUNT hour:morning:visitors    # 오전 방문자
PFCOUNT hour:afternoon:visitors  # 오후 방문자
PFCOUNT hour:evening:visitors    # 저녁 방문자

# 하루 전체 고유 방문자 수
PFMERGE hour:daily:visitors hour:morning:visitors hour:afternoon:visitors hour:evening:visitors
PFCOUNT hour:daily:visitors
```

## 🔍 실습 결과 확인 및 메모리 효율성 비교

```redis
# 모든 HyperLogLog 키 확인
KEYS visitors:*
KEYS page:*
KEYS platform:*
KEYS hour:*

# 메모리 사용량 확인 (HyperLogLog는 매우 적은 메모리 사용)
MEMORY USAGE visitors:2024:01:15
MEMORY USAGE visitors:2024:week03
MEMORY USAGE site:total:visitors

# 키 타입 확인
TYPE visitors:2024:01:15        # "hyperloglog"

# 기존 Set과 메모리 사용량 비교를 위한 테스트
SADD test:set:users user1 user2 user3 user4 user5 user6 user7 user8 user9 user10
PFADD test:hll:users user1 user2 user3 user4 user5 user6 user7 user8 user9 user10

MEMORY USAGE test:set:users     # Set의 메모리 사용량
MEMORY USAGE test:hll:users     # HyperLogLog의 메모리 사용량 (훨씬 적음)
```

## 📊 성능 특성 이해

### HyperLogLog의 장점
1. **극도의 메모리 효율성**: 고정된 12KB 메모리 사용
2. **대용량 처리**: 수십억 개의 고유 원소 처리 가능
3. **빠른 연산**: O(1) 시간복잡도
4. **병합 가능**: 여러 HyperLogLog를 병합하여 분석 가능

### 단점
1. **근사치**: 정확한 값이 아닌 추정값 (0.81% 오차)
2. **개별 원소 조회 불가**: 특정 원소의 존재 여부 확인 불가
3. **작은 집합에서 부정확**: 원소 수가 적을 때 상대적으로 부정확

## 🎯 응용 문제

1. **문제 1**: 월별 신규 가입자 수를 추정하는 시스템을 HyperLogLog로 구현해보세요. (기존 사용자 제외)

2. **문제 2**: 광고 캠페인별 도달 사용자 수를 추적하는 시스템을 설계해보세요.

## 💡 실무 연계 포인트

- **웹 분석**: 일일/월별 순 방문자 수 추정
- **광고 효과 측정**: 캠페인 도달률 및 중복 제거된 노출 수
- **사용자 행동 분석**: 플랫폼별, 기능별 고유 사용자 수
- **A/B 테스트**: 실험 그룹별 고유 참여자 수 측정
- **실시간 대시보드**: 메모리 효율적인 실시간 통계

## ✅ 학습 완료 체크리스트

- [ ] HyperLogLog 기본 개념 이해 완료
- [ ] PFADD, PFCOUNT 명령어 실습 완료  
- [ ] PFMERGE를 활용한 데이터 병합 실습 완료
- [ ] 일일 순 방문자 수 추정 시스템 구현 완료
- [ ] 대용량 데이터 정확도 테스트 완료
- [ ] 플랫폼별 분석 시스템 구현 완료
- [ ] 메모리 효율성 비교 분석 완료
- [ ] HyperLogLog vs Set 차이점 이해 완료
- [ ] 응용 문제 해결 완료