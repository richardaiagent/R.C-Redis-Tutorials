# Redis 중급 12번 - HyperLogLog 실습 교안

## 📋 학습 목표
- HyperLogLog 데이터 구조의 개념과 특징 이해
- 대용량 고유 카운터 시스템 구현
- 일일 순 방문자 수 추정 시스템 구축
- HyperLogLog의 메모리 효율성과 정확도 트레이드오프 이해
- 실제 웹 서비스에서의 활용 사례 실습

## 🎯 HyperLogLog 개념 이해

### HyperLogLog란?
- **확률적 데이터 구조**로 대용량 데이터의 **고유 원소 개수(Cardinality)**를 추정
- **메모리 사용량이 일정**함 (최대 12KB)
- **정확도 약 0.81%** 오차율로 매우 높은 정확도
- **수십억 개의 고유 값**도 효율적으로 처리 가능

### 전통적인 방법과의 비교
```
전통적 방법 (Set 사용):
- 1억 개 고유 IP: 약 1.6GB 메모리 필요
- 100% 정확도

HyperLogLog:
- 데이터 개수와 무관하게 12KB 고정
- 99.19% 정확도 (0.81% 오차)
```

## 🚀 실습 환경 준비

### Redis 컨테이너 실행 (이미 실행 중이라면 생략)
```powershell
# VSCode PowerShell 터미널에서 실행
# 기존 Redis 컨테이너가 없다면 실행
docker run -d --name redis-lab -p 6379:6379 -v redis-data:/data redis:7-alpine

# 컨테이너 상태 확인
docker ps

# Redis CLI 접속
docker exec -it redis-lab redis-cli
```

## 📊 실습 1: 기본 HyperLogLog 명령어

### 1-1. 기본 명령어 실습
```bash
# Redis CLI 접속 후 실행

# HyperLogLog 생성 및 데이터 추가
PFADD visitors "user1" "user2" "user3" "user1" "user4"

# 고유 방문자 수 확인 (중복 제거됨)
PFCOUNT visitors
# 결과: (integer) 4

# 더 많은 사용자 추가
PFADD visitors "user5" "user6" "user7" "user8" "user9" "user10"

# 다시 카운트 확인
PFCOUNT visitors
# 결과: (integer) 10

# 존재하지 않는 HyperLogLog 카운트 (0 반환)
PFCOUNT nonexistent
# 결과: (integer) 0
```

### 1-2. 메모리 사용량 확인
```bash
# HyperLogLog 메모리 사용량 확인
MEMORY USAGE visitors

# 일반 Set과 비교를 위해 Set 생성
SADD visitors_set "user1" "user2" "user3" "user4" "user5" "user6" "user7" "user8" "user9" "user10"

# Set 메모리 사용량 확인
MEMORY USAGE visitors_set

# 카운트 비교
PFCOUNT visitors
SCARD visitors_set
```

## 🌐 실습 2: 일일 순 방문자 수 추정 시스템

### 2-1. 날짜별 방문자 데이터 생성
```bash
# 오늘 방문자 시뮬레이션 (2025-05-23)
PFADD visitors:2025-05-23 "ip:192.168.1.1" "ip:10.0.0.1" "ip:172.16.0.1" "ip:203.0.113.1"
PFADD visitors:2025-05-23 "ip:198.51.100.1" "ip:203.0.113.5" "ip:192.0.2.1" "ip:198.51.100.25"
PFADD visitors:2025-05-23 "ip:203.0.113.10" "ip:172.16.0.5" "ip:10.0.0.15" "ip:192.168.1.100"

# 어제 방문자 시뮬레이션 (2025-05-22)
PFADD visitors:2025-05-22 "ip:192.168.1.1" "ip:10.0.0.2" "ip:172.16.0.2" "ip:203.0.113.2"
PFADD visitors:2025-05-22 "ip:198.51.100.2" "ip:203.0.113.6" "ip:192.0.2.2" "ip:198.51.100.26"

# 그저께 방문자 시뮬레이션 (2025-05-21)
PFADD visitors:2025-05-21 "ip:192.168.1.2" "ip:10.0.0.3" "ip:172.16.0.3" "ip:203.0.113.3"
PFADD visitors:2025-05-21 "ip:198.51.100.3" "ip:203.0.113.7" "ip:192.0.2.3" "ip:198.51.100.27"
PFADD visitors:2025-05-21 "ip:203.0.113.11" "ip:172.16.0.6" "ip:10.0.0.16" "ip:192.168.1.101"
PFADD visitors:2025-05-21 "ip:203.0.113.12" "ip:172.16.0.7" "ip:10.0.0.17" "ip:192.168.1.102"

# 각 날짜별 방문자 수 확인
PFCOUNT visitors:2025-05-23
PFCOUNT visitors:2025-05-22
PFCOUNT visitors:2025-05-21
```

### 2-2. 대용량 데이터 시뮬레이션
```bash
# 대용량 방문자 데이터 생성 스크립트 (Redis CLI에서 실행)
# 1000명의 고유 방문자 시뮬레이션

# 루프를 통한 대량 데이터 입력 (Lua 스크립트 사용)
EVAL "
for i=1,1000 do
    redis.call('PFADD', 'visitors:large:2025-05-23', 'user:' .. i)
end
return 'OK'
" 0

# 대용량 데이터 카운트 확인
PFCOUNT visitors:large:2025-05-23

# 중복 데이터 추가해보기
EVAL "
for i=500,1500 do
    redis.call('PFADD', 'visitors:large:2025-05-23', 'user:' .. i)
end
return 'OK'
" 0

# 다시 카운트 확인 (약 1500개 근처의 값)
PFCOUNT visitors:large:2025-05-23
```

## 📈 실습 3: HyperLogLog 병합과 집계

### 3-1. 다중 HyperLogLog 병합
```bash
# 주간 방문자 집계를 위한 병합
PFMERGE visitors:week1 visitors:2025-05-21 visitors:2025-05-22 visitors:2025-05-23

# 주간 총 방문자 수 확인
PFCOUNT visitors:week1

# 개별 일자와 비교
echo "=== 일별 방문자 수 ==="
PFCOUNT visitors:2025-05-21
PFCOUNT visitors:2025-05-22  
PFCOUNT visitors:2025-05-23

echo "=== 주간 총 방문자 수 ==="
PFCOUNT visitors:week1
```

### 3-2. 월간 집계 시뮬레이션
```bash
# 추가 주차 데이터 생성
# 2주차 데이터
PFADD visitors:2025-05-24 "ip:192.168.2.1" "ip:10.0.1.1" "ip:172.17.0.1"
PFADD visitors:2025-05-25 "ip:192.168.2.2" "ip:10.0.1.2" "ip:172.17.0.2"
PFADD visitors:2025-05-26 "ip:192.168.2.3" "ip:10.0.1.3" "ip:172.17.0.3"

# 2주차 병합
PFMERGE visitors:week2 visitors:2025-05-24 visitors:2025-05-25 visitors:2025-05-26

# 월간 병합
PFMERGE visitors:2025-05 visitors:week1 visitors:week2

# 월간 총 방문자 수
PFCOUNT visitors:2025-05
```

## 🎮 실습 4: 실제 웹 서비스 시나리오

### 4-1. 다중 페이지 방문자 추적
```bash
# 홈페이지 방문자
PFADD page:home:2025-05-23 "session:abc123" "session:def456" "session:ghi789"
PFADD page:home:2025-05-23 "session:jkl012" "session:mno345" "session:pqr678"

# 상품 페이지 방문자
PFADD page:product:2025-05-23 "session:abc123" "session:stu901" "session:vwx234"
PFADD page:product:2025-05-23 "session:def456" "session:yza567" "session:bcd890"

# 결제 페이지 방문자
PFADD page:checkout:2025-05-23 "session:abc123" "session:def456" "session:efg123"

# 각 페이지별 방문자 수 확인
PFCOUNT page:home:2025-05-23
PFCOUNT page:product:2025-05-23
PFCOUNT page:checkout:2025-05-23

# 전체 사이트 방문자 (모든 페이지 병합)
PFMERGE site:total:2025-05-23 page:home:2025-05-23 page:product:2025-05-23 page:checkout:2025-05-23
PFCOUNT site:total:2025-05-23
```

### 4-2. 모바일/웹 플랫폼별 분석
```bash
# 모바일 앱 사용자
PFADD platform:mobile:2025-05-23 "user:mobile:1001" "user:mobile:1002" "user:mobile:1003"
PFADD platform:mobile:2025-05-23 "user:mobile:1004" "user:mobile:1005" "user:mobile:1006"
PFADD platform:mobile:2025-05-23 "user:mobile:1007" "user:mobile:1008" "user:mobile:1009"

# 웹 사용자
PFADD platform:web:2025-05-23 "user:web:2001" "user:web:2002" "user:web:2003"
PFADD platform:web:2025-05-23 "user:web:2004" "user:web:2005" "user:mobile:1001"
PFADD platform:web:2025-05-23 "user:web:2006" "user:web:2007" "user:mobile:1002"

# 플랫폼별 사용자 수
PFCOUNT platform:mobile:2025-05-23
PFCOUNT platform:web:2025-05-23

# 전체 활성 사용자 (플랫폼 교차 중복 제거)
PFMERGE users:active:2025-05-23 platform:mobile:2025-05-23 platform:web:2025-05-23
PFCOUNT users:active:2025-05-23
```

## 📊 실습 5: 성능 및 정확도 비교

### 5-1. Set vs HyperLogLog 비교
```bash
# 동일한 데이터를 Set과 HyperLogLog에 저장
EVAL "
local users = {}
for i=1,10000 do
    local user = 'user:' .. i
    redis.call('SADD', 'users_set_comparison', user)
    redis.call('PFADD', 'users_hll_comparison', user)
end
return 'Data inserted'
" 0

# 카운트 비교
SCARD users_set_comparison
PFCOUNT users_hll_comparison

# 메모리 사용량 비교
MEMORY USAGE users_set_comparison
MEMORY USAGE users_hll_comparison

# 중복 데이터로 다시 테스트
EVAL "
for i=5000,15000 do
    local user = 'user:' .. i
    redis.call('SADD', 'users_set_comparison', user)
    redis.call('PFADD', 'users_hll_comparison', user)
end
return 'Additional data inserted'
" 0

# 다시 비교
SCARD users_set_comparison
PFCOUNT users_hll_comparison
```

### 5-2. HyperLogLog 정확도 테스트
```bash
# 정확한 카운트를 위한 참조 데이터
EVAL "
local count = 0
for i=1,100000 do
    local user = 'precise:user:' .. i
    redis.call('SADD', 'users_precise', user)
    redis.call('PFADD', 'users_estimate', user)
    count = count + 1
end
return count
" 0

# 정확도 비교
SCARD users_precise
PFCOUNT users_estimate

# 오차율 계산 (수동으로 계산)
echo "정확한 값: $(SCARD users_precise)"
echo "추정 값: $(PFCOUNT users_estimate)"
```

## 🔧 실습 6: 실무 활용 시나리오

### 6-1. 실시간 대시보드 데이터
```bash
# 실시간 방문자 추적 시뮬레이션
# 매 시간별 데이터

# 오전 9시 방문자
PFADD visitors:hourly:2025-05-23:09 "ip:1.1.1.1" "ip:2.2.2.2" "ip:3.3.3.3"
PFADD visitors:hourly:2025-05-23:09 "ip:4.4.4.4" "ip:5.5.5.5" "ip:6.6.6.6"

# 오전 10시 방문자 (일부 중복)
PFADD visitors:hourly:2025-05-23:10 "ip:1.1.1.1" "ip:7.7.7.7" "ip:8.8.8.8"  
PFADD visitors:hourly:2025-05-23:10 "ip:9.9.9.9" "ip:10.10.10.10" "ip:11.11.11.11"

# 오전 11시 방문자
PFADD visitors:hourly:2025-05-23:11 "ip:12.12.12.12" "ip:13.13.13.13" "ip:1.1.1.1"
PFADD visitors:hourly:2025-05-23:11 "ip:14.14.14.14" "ip:15.15.15.15" "ip:16.16.16.16"

# 시간별 방문자 수 확인
PFCOUNT visitors:hourly:2025-05-23:09
PFCOUNT visitors:hourly:2025-05-23:10  
PFCOUNT visitors:hourly:2025-05-23:11

# 오전 시간대 전체 방문자 (9-11시)
PFMERGE visitors:morning:2025-05-23 visitors:hourly:2025-05-23:09 visitors:hourly:2025-05-23:10 visitors:hourly:2025-05-23:11
PFCOUNT visitors:morning:2025-05-23
```

### 6-2. 마케팅 캠페인 효과 측정
```bash
# 캠페인별 고유 사용자 추적
# 구글 광고 캠페인
PFADD campaign:google:2025-05-23 "user:g001" "user:g002" "user:g003" "user:g004"
PFADD campaign:google:2025-05-23 "user:g005" "user:g006" "user:g007" "user:g008"

# 페이스북 광고 캠페인  
PFADD campaign:facebook:2025-05-23 "user:f001" "user:f002" "user:f003" "user:g001"
PFADD campaign:facebook:2025-05-23 "user:f004" "user:f005" "user:g002" "user:f006"

# 이메일 마케팅
PFADD campaign:email:2025-05-23 "user:e001" "user:e002" "user:g001" "user:f001"
PFADD campaign:email:2025-05-23 "user:e003" "user:e004" "user:e005" "user:e006"

# 캠페인별 도달 사용자 수
PFCOUNT campaign:google:2025-05-23
PFCOUNT campaign:facebook:2025-05-23
PFCOUNT campaign:email:2025-05-23

# 전체 마케팅 도달 사용자 (중복 제거)
PFMERGE campaign:total:2025-05-23 campaign:google:2025-05-23 campaign:facebook:2025-05-23 campaign:email:2025-05-23
PFCOUNT campaign:total:2025-05-23
```

## 📈 실습 7: 고급 분석 및 최적화

### 7-1. 지역별 사용자 분석
```bash
# 지역별 사용자 데이터
# 서울 사용자
PFADD region:seoul:2025-05-23 "user:seoul:1001" "user:seoul:1002" "user:seoul:1003"
PFADD region:seoul:2025-05-23 "user:seoul:1004" "user:seoul:1005" "user:seoul:1006"

# 부산 사용자
PFADD region:busan:2025-05-23 "user:busan:2001" "user:busan:2002" "user:busan:2003"
PFADD region:busan:2025-05-23 "user:seoul:1001" "user:busan:2004" "user:busan:2005"

# 대구 사용자  
PFADD region:daegu:2025-05-23 "user:daegu:3001" "user:daegu:3002" "user:seoul:1002"
PFADD region:daegu:2025-05-23 "user:daegu:3003" "user:daegu:3004" "user:busan:2001"

# 지역별 고유 사용자 수
PFCOUNT region:seoul:2025-05-23
PFCOUNT region:busan:2025-05-23  
PFCOUNT region:daegu:2025-05-23

# 전국 사용자 (지역간 이동 고려)
PFMERGE region:korea:2025-05-23 region:seoul:2025-05-23 region:busan:2025-05-23 region:daegu:2025-05-23
PFCOUNT region:korea:2025-05-23
```

### 7-2. 사용자 세그먼트 분석
```bash
# 연령대별 사용자
PFADD segment:age20s:2025-05-23 "user:20s:101" "user:20s:102" "user:20s:103" "user:20s:104"
PFADD segment:age30s:2025-05-23 "user:30s:201" "user:30s:202" "user:20s:101" "user:30s:203"  
PFADD segment:age40s:2025-05-23 "user:40s:301" "user:40s:302" "user:30s:201" "user:40s:303"

# 성별 사용자
PFADD segment:male:2025-05-23 "user:20s:101" "user:30s:201" "user:40s:301" "user:male:401"
PFADD segment:female:2025-05-23 "user:20s:102" "user:30s:202" "user:40s:302" "user:female:501"

# 세그먼트별 분석
PFCOUNT segment:age20s:2025-05-23
PFCOUNT segment:age30s:2025-05-23
PFCOUNT segment:age40s:2025-05-23
PFCOUNT segment:male:2025-05-23
PFCOUNT segment:female:2025-05-23

# 교차 분석 (예: 20대 남성)
PFMERGE segment:male20s:2025-05-23 segment:age20s:2025-05-23 segment:male:2025-05-23
PFCOUNT segment:male20s:2025-05-23
```

## 🎯 실습 과제

### 과제 1: 전자상거래 분석 시스템
```bash
# 다음 데이터를 생성하고 분석하세요:
# 1. 상품 카테고리별 조회자 수
# 2. 결제 완료 사용자 수  
# 3. 장바구니 추가 사용자 수
# 4. 전환율 계산 (조회 → 장바구니 → 결제)

# 예시 시작 코드:
PFADD product:electronics:viewers "user:101" "user:102" "user:103"
PFADD product:electronics:cart "user:101" "user:104"  
PFADD product:electronics:purchase "user:101"

# 과제: 의류, 도서, 스포츠 카테고리도 추가하여 완성하세요
```

### 과제 2: 소셜 미디어 참여도 분석
```bash
# 다음 항목들의 고유 사용자 수를 추적하세요:
# 1. 게시물 조회자
# 2. 좋아요 누른 사용자  
# 3. 댓글 작성자
# 4. 공유한 사용자
# 5. 전체 참여도 계산

# 힌트: PFMERGE를 활용하여 중복 제거된 참여자 수 계산
```

## 💡 성능 최적화 팁

### HyperLogLog 사용 시 고려사항
```bash
# 1. 키 이름 규칙 설정
# 날짜:기능:세부사항 형태로 일관성 있게 명명
# 예: visitors:2025-05-23, campaign:google:2025-05-23

# 2. 만료 시간 설정 (30일 후 자동 삭제)
EXPIRE visitors:2025-05-23 2592000

# 3. 메모리 사용량 모니터링
INFO memory
MEMORY USAGE visitors:2025-05-23

# 4. 배치 처리로 성능 최적화
# 여러 값을 한 번에 추가
PFADD visitors:batch "user1" "user2" "user3" "user4" "user5"
```

## 📊 환경 검증 및 정리

### 최종 상태 확인
```bash
# 생성된 모든 HyperLogLog 키 확인
KEYS *visitors*
KEYS *campaign*  
KEYS *segment*

# 주요 HyperLogLog 카운트 요약
echo "=== 일별 방문자 통계 ==="
PFCOUNT visitors:2025-05-21
PFCOUNT visitors:2025-05-22
PFCOUNT visitors:2025-05-23

echo "=== 플랫폼별 사용자 ==="
PFCOUNT platform:mobile:2025-05-23
PFCOUNT platform:web:2025-05-23
PFCOUNT users:active:2025-05-23

echo "=== 메모리 효율성 비교 ==="
MEMORY USAGE users_set_comparison
MEMORY USAGE users_hll_comparison
```

### 실습 정리
```bash
# 실습용 데이터 정리 (선택사항)
# 주의: 실제 운영 환경에서는 신중하게 실행

# 테스트 키들 삭제
DEL users_set_comparison users_hll_comparison users_precise users_estimate

# 또는 특정 패턴 키들만 삭제 (주의 필요)
# EVAL "return redis.call('del', unpack(redis.call('keys', 'visitors:*')))" 0
```

## ✅ 학습 완료 체크리스트

### 기본 개념
- [ ] HyperLogLog의 확률적 특성 이해
- [ ] 메모리 효율성 확인 (12KB 고정)
- [ ] 정확도 트레이드오프 이해 (0.81% 오차)

### 핵심 명령어
- [ ] PFADD로 데이터 추가
- [ ] PFCOUNT로 카디널리티 계산  
- [ ] PFMERGE로 다중 HLL 병합

### 실무 활용
- [ ] 일일 순 방문자 수 시스템 구현
- [ ] 다중 플랫폼/페이지 분석 구현
- [ ] 마케팅 캠페인 효과 측정 구현
- [ ] Set 대비 메모리 효율성 확인

### 고급 기능
- [ ] 시간별/날짜별 집계 구조 설계
- [ ] 사용자 세그먼트 교차 분석
- [ ] 성능 최적화 기법 적용

## 🔗 다음 단계
다음은 **중급 13번 - Stream 데이터 타입 실습**입니다. HyperLogLog를 통해 대용량 고유 카운터를 다뤄봤으니, 이제 실시간 이벤트 스트리밍과 로그 수집 시스템을 학습해보겠습니다.

---
*본 교안은 Windows 환경의 Docker Redis와 VSCode PowerShell을 기준으로 작성되었습니다.*