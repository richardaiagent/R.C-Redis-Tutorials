# Redis 초급 11번 - Bitmap 데이터 타입 실습 교안

## 📋 학습 목표
- Redis Bitmap 데이터 타입의 개념과 특징 이해
- 사용자 활동 추적 시스템 구현
- 일별 출석 체크 시스템 구현
- Bitmap 연산을 통한 통계 데이터 분석
- 메모리 효율적인 대용량 데이터 처리 방법 학습

## 🎯 Bitmap이란?
Bitmap은 Redis의 String 데이터 타입을 기반으로 하여 각 비트(0 또는 1)를 개별적으로 조작할 수 있는 특별한 데이터 구조입니다.

### 주요 특징
- **메모리 효율성**: 1개 비트로 1개 상태 표현 (TRUE/FALSE)
- **빠른 연산**: 비트 단위 연산으로 매우 빠른 처리 속도
- **대용량 처리**: 수백만 개의 사용자 ID도 효율적으로 처리
- **집합 연산**: AND, OR, XOR, NOT 연산 지원

## 🔧 사전 준비

### Docker Redis 환경 확인
```powershell
# VS Code PowerShell 터미널에서 실행
# Redis 컨테이너 상태 확인
docker ps | findstr redis

# Redis 컨테이너가 없다면 실행
docker run -d --name redis-lab -p 6379:6379 -v redis-data:/data redis:7-alpine

# Redis CLI 접속 테스트
docker exec -it redis-lab redis-cli ping
```

## 📚 기본 Bitmap 명령어

### 주요 명령어 정리
| 명령어 | 기능 | 예시 |
|--------|------|------|
| `SETBIT` | 특정 오프셋의 비트 설정 | `SETBIT key offset value` |
| `GETBIT` | 특정 오프셋의 비트 조회 | `GETBIT key offset` |
| `BITCOUNT` | 설정된 비트(1) 개수 계산 | `BITCOUNT key [start end]` |
| `BITOP` | 비트 연산 (AND, OR, XOR, NOT) | `BITOP operation destkey key1 key2` |
| `BITPOS` | 첫 번째 0 또는 1 비트 위치 찾기 | `BITPOS key bit [start]` |

## 🚀 실습 1: 기본 Bitmap 조작

### 1-1. 기본 비트 설정 및 조회
```powershell
# Redis CLI 접속
docker exec -it redis-lab redis-cli

# 기본 비트 조작 실습
# 사용자 ID 1001번이 로그인 (비트 1001 위치를 1로 설정)
SETBIT daily_login:2025-05-23 1001 1

# 사용자 ID 1005번이 로그인
SETBIT daily_login:2025-05-23 1005 1

# 사용자 ID 1010번이 로그인
SETBIT daily_login:2025-05-23 1010 1

# 특정 사용자의 로그인 상태 확인
GETBIT daily_login:2025-05-23 1001
# 결과: (integer) 1

GETBIT daily_login:2025-05-23 1002
# 결과: (integer) 0 (로그인하지 않음)

# 총 로그인 사용자 수 확인
BITCOUNT daily_login:2025-05-23
# 결과: (integer) 3
```

### 1-2. 범위별 비트 카운트
```powershell
# 더 많은 사용자 로그인 데이터 추가
SETBIT daily_login:2025-05-23 1020 1
SETBIT daily_login:2025-05-23 1025 1
SETBIT daily_login:2025-05-23 1030 1
SETBIT daily_login:2025-05-23 1035 1
SETBIT daily_login:2025-05-23 1040 1

# 전체 로그인 사용자 수
BITCOUNT daily_login:2025-05-23

# 특정 범위의 로그인 사용자 수 (바이트 단위)
# 1000~1007번 사용자 범위 확인 (바이트 125)
BITCOUNT daily_login:2025-05-23 125 125

# 첫 번째로 로그인한 사용자 찾기
BITPOS daily_login:2025-05-23 1
# 결과: 1001번 사용자
```

## 🎯 실습 2: 일별 사용자 활동 추적 시스템

### 2-1. 일주일간 로그인 데이터 생성
```powershell
# 2025년 5월 19일 (월요일) 로그인 데이터
SETBIT daily_login:2025-05-19 1001 1
SETBIT daily_login:2025-05-19 1002 1
SETBIT daily_login:2025-05-19 1003 1
SETBIT daily_login:2025-05-19 1005 1
SETBIT daily_login:2025-05-19 1008 1

# 2025년 5월 20일 (화요일) 로그인 데이터
SETBIT daily_login:2025-05-20 1001 1
SETBIT daily_login:2025-05-20 1003 1
SETBIT daily_login:2025-05-20 1004 1
SETBIT daily_login:2025-05-20 1006 1
SETBIT daily_login:2025-05-20 1007 1
SETBIT daily_login:2025-05-20 1009 1

# 2025년 5월 21일 (수요일) 로그인 데이터
SETBIT daily_login:2025-05-21 1001 1
SETBIT daily_login:2025-05-21 1002 1
SETBIT daily_login:2025-05-21 1004 1
SETBIT daily_login:2025-05-21 1005 1
SETBIT daily_login:2025-05-21 1007 1
SETBIT daily_login:2025-05-21 1010 1

# 2025년 5월 22일 (목요일) 로그인 데이터
SETBIT daily_login:2025-05-22 1001 1
SETBIT daily_login:2025-05-22 1003 1
SETBIT daily_login:2025-05-22 1006 1
SETBIT daily_login:2025-05-22 1008 1
SETBIT daily_login:2025-05-22 1009 1

# 2025년 5월 23일 (금요일) 데이터는 이미 입력됨
```

### 2-2. 일별 통계 분석
```powershell
# 각 날짜별 로그인 사용자 수 확인
BITCOUNT daily_login:2025-05-19
BITCOUNT daily_login:2025-05-20
BITCOUNT daily_login:2025-05-21
BITCOUNT daily_login:2025-05-22
BITCOUNT daily_login:2025-05-23

# 특정 사용자의 주간 로그인 기록 확인
# 사용자 1001번의 로그인 이력
GETBIT daily_login:2025-05-19 1001
GETBIT daily_login:2025-05-20 1001
GETBIT daily_login:2025-05-21 1001
GETBIT daily_login:2025-05-22 1001
GETBIT daily_login:2025-05-23 1001
```

## 🔄 실습 3: Bitmap 연산 활용

### 3-1. 연속 로그인 사용자 찾기 (AND 연산)
```powershell
# 월요일과 화요일 모두 로그인한 사용자 찾기
BITOP AND login_mon_tue daily_login:2025-05-19 daily_login:2025-05-20

# 결과 확인
BITCOUNT login_mon_tue
# 월화 모두 로그인한 사용자: 1001, 1003

# 사용자별 확인
GETBIT login_mon_tue 1001  # 1 (월화 모두 로그인)
GETBIT login_mon_tue 1002  # 0 (화요일 로그인 안함)
GETBIT login_mon_tue 1003  # 1 (월화 모두 로그인)

# 전체 주간 매일 로그인한 사용자 찾기
BITOP AND daily_users daily_login:2025-05-19 daily_login:2025-05-20 daily_login:2025-05-21 daily_login:2025-05-22 daily_login:2025-05-23
BITCOUNT daily_users
# 결과: 1 (1001번 사용자만 매일 로그인)
```

### 3-2. 이번 주 한 번이라도 로그인한 사용자 (OR 연산)
```powershell
# 이번 주 한 번이라도 로그인한 전체 사용자
BITOP OR weekly_active daily_login:2025-05-19 daily_login:2025-05-20 daily_login:2025-05-21 daily_login:2025-05-22 daily_login:2025-05-23

# 전체 활성 사용자 수
BITCOUNT weekly_active

# 특정 사용자들의 주간 활동 여부 확인
GETBIT weekly_active 1001
GETBIT weekly_active 1015  # 로그인하지 않은 사용자
```

### 3-3. 이탈 사용자 분석 (XOR 연산)
```powershell
# 월요일에는 로그인했지만 화요일에는 로그인하지 않은 사용자
BITOP XOR login_change daily_login:2025-05-19 daily_login:2025-05-20

# 변화가 있는 사용자 수
BITCOUNT login_change

# 월요일에만 로그인한 사용자 찾기 (월요일 AND (NOT 화요일))
BITOP NOT not_tuesday daily_login:2025-05-20
BITOP AND monday_only daily_login:2025-05-19 not_tuesday
BITCOUNT monday_only
```

## 🎪 실습 4: 출석 체크 시스템 구현

### 4-1. 학습자 출석 데이터 생성
```powershell
# 5월 19일 수업 출석 (학번을 오프셋으로 사용)
# 학번 20241001~20241010 학생들의 출석 처리
SETBIT attendance:2025-05-19 20241001 1
SETBIT attendance:2025-05-19 20241002 1
SETBIT attendance:2025-05-19 20241003 1
SETBIT attendance:2025-05-19 20241005 1
SETBIT attendance:2025-05-19 20241007 1
SETBIT attendance:2025-05-19 20241008 1
SETBIT attendance:2025-05-19 20241010 1

# 5월 21일 수업 출석
SETBIT attendance:2025-05-21 20241001 1
SETBIT attendance:2025-05-21 20241002 1
SETBIT attendance:2025-05-21 20241004 1
SETBIT attendance:2025-05-21 20241005 1
SETBIT attendance:2025-05-21 20241006 1
SETBIT attendance:2025-05-21 20241008 1
SETBIT attendance:2025-05-21 20241009 1
SETBIT attendance:2025-05-21 20241010 1

# 5월 23일 수업 출석
SETBIT attendance:2025-05-23 20241001 1
SETBIT attendance:2025-05-23 20241003 1
SETBIT attendance:2025-05-23 20241004 1
SETBIT attendance:2025-05-23 20241006 1
SETBIT attendance:2025-05-23 20241007 1
SETBIT attendance:2025-05-23 20241009 1
SETBIT attendance:2025-05-23 20241010 1
```

### 4-2. 출석 통계 분석
```powershell
# 각 수업일별 출석률 확인
BITCOUNT attendance:2025-05-19
BITCOUNT attendance:2025-05-21
BITCOUNT attendance:2025-05-23

# 완전 출석자 찾기 (3일 모두 출석)
BITOP AND perfect_attendance attendance:2025-05-19 attendance:2025-05-21 attendance:2025-05-23
BITCOUNT perfect_attendance
# 완전 출석자 확인
GETBIT perfect_attendance 20241001
GETBIT perfect_attendance 20241010

# 한 번이라도 출석한 학생 수
BITOP OR any_attendance attendance:2025-05-19 attendance:2025-05-21 attendance:2025-05-23
BITCOUNT any_attendance

# 출석률이 저조한 학생 찾기 (1회만 출석)
# 전체 출석 가능 횟수에서 실제 출석 횟수가 1인 학생들을 찾는 복합 쿼리
```

### 4-3. 개별 학생 출석 이력 조회
```powershell
# 특정 학생의 출석 이력 조회 함수 시뮬레이션
# 학번 20241005 학생의 출석 이력
echo "학번 20241005 출석 이력:"
echo "5월 19일: $(docker exec -it redis-lab redis-cli GETBIT attendance:2025-05-19 20241005)"
echo "5월 21일: $(docker exec -it redis-lab redis-cli GETBIT attendance:2025-05-21 20241005)"
echo "5월 23일: $(docker exec -it redis-lab redis-cli GETBIT attendance:2025-05-23 20241005)"

# 여러 학생 출석 상태 배치 조회
echo "전체 학생 5월 19일 출석 현황:"
for i in {20241001..20241010}
do
    result=$(docker exec redis-lab redis-cli GETBIT attendance:2025-05-19 $i)
    echo "학번 $i: $result"
done
```

## 🔍 실습 5: 고급 Bitmap 분석

### 5-1. 사용자 세그먼트 분석
```powershell
# VIP 사용자 비트맵 생성 (가정: 1001, 1005, 1008, 1010이 VIP)
SETBIT vip_users 1001 1
SETBIT vip_users 1005 1
SETBIT vip_users 1008 1
SETBIT vip_users 1010 1

# VIP 사용자 중 오늘 로그인한 사용자
BITOP AND vip_today_login vip_users daily_login:2025-05-23
BITCOUNT vip_today_login

# VIP가 아닌 사용자 중 오늘 로그인한 사용자
BITOP NOT not_vip vip_users
BITOP AND regular_today_login not_vip daily_login:2025-05-23
BITCOUNT regular_today_login
```

### 5-2. 메모리 사용량 분석
```powershell
# 각 비트맵의 메모리 사용량 확인
MEMORY USAGE daily_login:2025-05-23
MEMORY USAGE weekly_active
MEMORY USAGE vip_users

# 전체 키 목록 확인
KEYS *login*
KEYS *attendance*

# 비트맵 키의 상세 정보
TYPE daily_login:2025-05-23
STRLEN daily_login:2025-05-23
```

## 📊 실습 6: 실시간 활동 모니터링 시뮬레이션

### 6-1. 실시간 접속자 추적
```powershell
# 현재 온라인 사용자 시뮬레이션 (매분마다 갱신된다고 가정)
SETBIT online_users:14:30 1001 1
SETBIT online_users:14:30 1005 1
SETBIT online_users:14:30 1008 1
SETBIT online_users:14:30 1012 1

SETBIT online_users:14:31 1001 1
SETBIT online_users:14:31 1003 1
SETBIT online_users:14:31 1008 1
SETBIT online_users:14:31 1015 1

# 각 시간대별 온라인 사용자 수
BITCOUNT online_users:14:30
BITCOUNT online_users:14:31

# 연속으로 온라인 상태를 유지한 사용자
BITOP AND continuous_online online_users:14:30 online_users:14:31
BITCOUNT continuous_online
```

### 6-2. 이벤트 참여 추적
```powershell
# 특별 이벤트 참여자 비트맵
SETBIT event_participation:weekend_sale 1001 1
SETBIT event_participation:weekend_sale 1003 1
SETBIT event_participation:weekend_sale 1005 1
SETBIT event_participation:weekend_sale 1007 1
SETBIT event_participation:weekend_sale 1009 1

# 이벤트에 참여하면서 오늘 로그인한 사용자
BITOP AND event_and_active event_participation:weekend_sale daily_login:2025-05-23
BITCOUNT event_and_active

# 이벤트 참여자 중 VIP 사용자
BITOP AND event_vip event_participation:weekend_sale vip_users
BITCOUNT event_vip
```

## 💡 성능 최적화 팁

### Bitmap 사용 시 고려사항
```powershell
# 메모리 효율성 확인
# 1000만 사용자 ID까지의 비트맵 메모리 사용량
SETBIT large_bitmap 10000000 1
MEMORY USAGE large_bitmap
# 약 1.25MB (10,000,000 비트 ÷ 8 = 1,250,000 바이트)

# 비트 위치 최적화 예시
# 잘못된 예: 사용자 ID를 그대로 사용 (10억 사용자면 125MB)
# 올바른 예: 연속된 인덱스 매핑 테이블 사용

# 비트맵 압축 확인
DEBUG OBJECT daily_login:2025-05-23
```

## 🎯 실습 과제

### 과제 1: 월간 활성 사용자 분석 시스템
다음 요구사항을 만족하는 시스템을 구현하세요:
1. 일별 로그인 사용자 추적 (30일간)
2. 월간 활성 사용자 (MAU) 계산
3. 주간 활성 사용자 (WAU) 계산
4. 일간 활성 사용자 (DAU) 평균 계산

### 과제 2: 학습 진도 관리 시스템
다음 기능을 구현하세요:
1. 각 강의별 수강생 출석 체크
2. 과제 제출 여부 추적
3. 시험 응시 여부 추적
4. 수료 조건 달성 학생 자동 계산

## 🔧 문제 해결 가이드

### 일반적인 문제들

#### 문제 1: 오프셋이 너무 큰 경우
```powershell
# 큰 오프셋 사용 시 메모리 사용량 급증
# 해결: 사용자 ID 매핑 테이블 사용
HSET user_id_mapping "user_12345678" 1
HSET user_id_mapping "user_87654321" 2
# 매핑된 작은 번호로 비트맵 사용
SETBIT daily_login:2025-05-23 1 1
```

#### 문제 2: 비트맵 연산 결과 키 관리
```powershell
# 임시 키에 TTL 설정으로 자동 정리
BITOP AND temp_result key1 key2
EXPIRE temp_result 3600  # 1시간 후 자동 삭제
```

## 📊 성능 벤치마킹

### 비트맵 vs 다른 데이터 구조 비교
```powershell
# Set을 사용한 방법과 비교
# 1000만 사용자 중 100만 활성 사용자를 저장할 때:
# Set: 약 50MB (사용자 ID당 평균 50바이트)
# Bitmap: 약 1.25MB (전체 사용자 수 기준)

# 성능 테스트 예시
# 100만 사용자 로그인 상태 확인 시간 측정
```

## ✅ 학습 완료 체크리스트

### 기본 개념 이해
- [ ] Bitmap의 메모리 효율성 이해
- [ ] SETBIT, GETBIT 명령어 숙지
- [ ] BITCOUNT로 통계 산출 가능
- [ ] 오프셋 개념 이해

### 고급 활용
- [ ] BITOP 연산 (AND, OR, XOR, NOT) 활용
- [ ] 다중 비트맵 연산으로 복합 조건 분석
- [ ] 대용량 사용자 데이터 효율적 처리
- [ ] 실시간 활동 추적 시스템 구현

### 실무 응용
- [ ] 사용자 세그먼트 분석 구현
- [ ] 출석/참여 관리 시스템 구현
- [ ] 메모리 최적화 기법 적용
- [ ] 성능 모니터링 및 튜닝

## 🔗 다음 단계
다음은 **초급 12번 - HyperLogLog 실습**입니다. Bitmap으로 정확한 카운팅을 학습했으니, 이제 대용량 데이터에서 근사치 카운팅을 효율적으로 수행하는 HyperLogLog를 학습해보겠습니다.

---
*본 교안은 Windows Docker Desktop 환경에서 VS Code PowerShell 터미널을 사용하여 실습하도록 구성되었습니다.*