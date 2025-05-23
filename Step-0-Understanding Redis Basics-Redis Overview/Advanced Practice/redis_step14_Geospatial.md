# Redis 중급 14번 - Geospatial 실습 교안

## 📋 학습 목표
- Redis Geospatial 데이터 타입의 개념과 활용법 이해
- 위치 기반 서비스(LBS) 구현 방법 학습
- 주변 매장 찾기 시스템 실습을 통한 실무 패턴 습득
- 지리적 거리 계산 및 반경 검색 기능 구현
- 위치 데이터의 효율적인 저장과 조회 방법 숙지

## 🗺️ Geospatial 데이터 타입 개념

### Geospatial이란?
Redis의 Geospatial 데이터 타입은 지리적 위치 정보(위도, 경도)를 저장하고 처리하는 데이터 구조입니다.

### 주요 특징
- **좌표 저장**: 위도(latitude)와 경도(longitude) 좌표 저장
- **거리 계산**: 두 지점 간의 거리 자동 계산
- **반경 검색**: 특정 지점 기준 반경 내 위치 검색
- **정렬**: 거리순으로 자동 정렬된 결과 제공
- **내부 구조**: Sorted Set 기반으로 구현되어 높은 성능 보장

### 지원하는 거리 단위
- `m` (미터)
- `km` (킬로미터) 
- `mi` (마일)
- `ft` (피트)

## 🚀 실습 환경 준비

### 1단계: Redis 컨테이너 실행 확인
```powershell
# VSCode PowerShell 터미널에서 실행
# 기존 Redis 컨테이너 상태 확인
docker ps -a --filter "name=redis"

# Redis 컨테이너가 없다면 새로 생성
docker run -d --name redis-geospatial -p 6379:6379 -v redis-geo-data:/data redis:7-alpine

# 컨테이너 실행 확인
docker ps
```

### 2단계: Redis CLI 접속
```powershell
# Redis CLI 접속
docker exec -it redis-geospatial redis-cli

# 연결 테스트
ping
# 응답: PONG
```

## 🏪 실습 1: 주요 매장 위치 데이터 등록

### 1-1. 서울 주요 상권 매장 데이터 준비
```redis
# 강남역 주변 매장들
GEOADD seoul_stores 127.0276 37.4979 "스타벅스_강남역점"
GEOADD seoul_stores 127.0284 37.4981 "맥도날드_강남역점"
GEOADD seoul_stores 127.0265 37.4975 "롯데리아_강남역점"
GEOADD seoul_stores 127.0290 37.4985 "버거킹_강남역점"
GEOADD seoul_stores 127.0258 37.4972 "투썸플레이스_강남역점"

# 홍대 주변 매장들
GEOADD seoul_stores 126.9240 37.5563 "스타벅스_홍대입구역점"
GEOADD seoul_stores 126.9235 37.5560 "맥도날드_홍대점"
GEOADD seoul_stores 126.9250 37.5570 "롯데리아_홍대점"
GEOADD seoul_stores 126.9245 37.5565 "파리바게뜨_홍대점"
GEOADD seoul_stores 126.9255 37.5575 "투썸플레이스_홍대점"

# 명동 주변 매장들
GEOADD seoul_stores 126.9849 37.5636 "스타벅스_명동점"
GEOADD seoul_stores 126.9855 37.5640 "맥도날드_명동점"
GEOADD seoul_stores 126.9845 37.5630 "롯데리아_명동점"
GEOADD seoul_stores 126.9860 37.5645 "버거킹_명동점"
GEOADD seoul_stores 126.9840 37.5625 "던킨도너츠_명동점"

# 잠실 주변 매장들
GEOADD seoul_stores 127.1000 37.5133 "스타벅스_잠실역점"
GEOADD seoul_stores 127.1010 37.5140 "맥도날드_잠실점"
GEOADD seoul_stores 127.0995 37.5130 "롯데리아_잠실점"
GEOADD seoul_stores 127.1015 37.5145 "파리바게뜨_잠실점"
GEOADD seoul_stores 127.0990 37.5125 "투썸플레이스_잠실점"
```

### 1-2. 등록된 데이터 확인
```redis
# 전체 매장 수 확인
ZCARD seoul_stores

# 모든 매장 목록 확인
ZRANGE seoul_stores 0 -1

# 특정 매장의 좌표 확인
GEOPOS seoul_stores "스타벅스_강남역점" "맥도날드_홍대점"
```

## 🔍 실습 2: 기본 Geospatial 명령어 실습

### 2-1. 거리 계산 (GEODIST)
```redis
# 강남역 스타벅스와 홍대 스타벅스 간 거리 (미터)
GEODIST seoul_stores "스타벅스_강남역점" "스타벅스_홍대입구역점" m

# 강남역 스타벅스와 명동 스타벅스 간 거리 (킬로미터)
GEODIST seoul_stores "스타벅스_강남역점" "스타벅스_명동점" km

# 홍대와 잠실 간 거리 (킬로미터)
GEODIST seoul_stores "스타벅스_홍대입구역점" "스타벅스_잠실역점" km

# 모든 스타벅스 매장 간 거리 비교
GEODIST seoul_stores "스타벅스_강남역점" "스타벅스_홍대입구역점" km
GEODIST seoul_stores "스타벅스_강남역점" "스타벅스_명동점" km
GEODIST seoul_stores "스타벅스_강남역점" "스타벅스_잠실역점" km
```

### 2-2. 위치 좌표 조회 (GEOPOS)
```redis
# 단일 매장 좌표 조회
GEOPOS seoul_stores "스타벅스_강남역점"

# 여러 매장 좌표 한번에 조회
GEOPOS seoul_stores "스타벅스_강남역점" "맥도날드_강남역점" "롯데리아_강남역점"

# 존재하지 않는 매장 조회 (null 반환)
GEOPOS seoul_stores "존재하지않는매장"
```

### 2-3. Geohash 값 조회 (GEOHASH)
```redis
# 지리적 해시값 확인
GEOHASH seoul_stores "스타벅스_강남역점" "스타벅스_홍대입구역점"

# 모든 강남역 매장의 해시값
GEOHASH seoul_stores "스타벅스_강남역점" "맥도날드_강남역점" "롯데리아_강남역점" "버거킹_강남역점" "투썸플레이스_강남역점"
```

## 🎯 실습 3: 반경 검색 (GEORADIUS/GEORADIUSBYMEMBER)

### 3-1. 특정 좌표 기준 반경 검색 (GEORADIUS)
```redis
# 강남역 좌표 (127.0276, 37.4979) 기준 1km 내 매장 검색
GEORADIUS seoul_stores 127.0276 37.4979 1 km

# 거리 정보 포함하여 검색
GEORADIUS seoul_stores 127.0276 37.4979 1 km WITHDIST

# 좌표 정보도 함께 출력
GEORADIUS seoul_stores 127.0276 37.4979 1 km WITHDIST WITHCOORD

# 거리순 정렬 (ASC: 가까운 순, DESC: 먼 순)
GEORADIUS seoul_stores 127.0276 37.4979 1 km WITHDIST ASC

# 결과 개수 제한 (가장 가까운 3개만)
GEORADIUS seoul_stores 127.0276 37.4979 1 km WITHDIST ASC COUNT 3
```

### 3-2. 기존 매장 기준 반경 검색 (GEORADIUSBYMEMBER)
```redis
# 스타벅스 강남역점 기준 500m 내 매장 검색
GEORADIUSBYMEMBER seoul_stores "스타벅스_강남역점" 500 m WITHDIST ASC

# 맥도날드 홍대점 기준 1km 내 매장 검색
GEORADIUSBYMEMBER seoul_stores "맥도날드_홍대점" 1 km WITHDIST ASC

# 명동 스타벅스 기준 2km 내 모든 정보 포함 검색
GEORADIUSBYMEMBER seoul_stores "스타벅스_명동점" 2 km WITHDIST WITHCOORD ASC

# 잠실 매장 기준 가장 가까운 5개 매장
GEORADIUSBYMEMBER seoul_stores "스타벅스_잠실역점" 10 km WITHDIST ASC COUNT 5
```

## 🍔 실습 4: 실무 시나리오 - 주변 매장 찾기 시스템

### 4-1. 사용자 현재 위치 기준 검색 시스템
```redis
# 시나리오: 사용자가 "127.0280, 37.4980" (강남역 근처)에 위치

# 1단계: 현재 위치 기준 500m 내 모든 매장
GEORADIUS seoul_stores 127.0280 37.4980 500 m WITHDIST ASC

# 2단계: 브랜드별 가장 가까운 매장 찾기
# 스타벅스만 필터링 (애플리케이션에서 처리)
GEORADIUS seoul_stores 127.0280 37.4980 2 km WITHDIST ASC

# 3단계: 거리별 카테고리 분류
# 도보권 (300m 이내)
GEORADIUS seoul_stores 127.0280 37.4980 300 m WITHDIST ASC COUNT 10

# 근거리 (1km 이내)  
GEORADIUS seoul_stores 127.0280 37.4980 1 km WITHDIST ASC COUNT 10

# 중거리 (3km 이내)
GEORADIUS seoul_stores 127.0280 37.4980 3 km WITHDIST ASC COUNT 15
```

### 4-2. 매장별 경쟁 분석
```redis
# 각 스타벅스 매장 기준 500m 내 경쟁업체 분석
GEORADIUSBYMEMBER seoul_stores "스타벅스_강남역점" 500 m WITHDIST ASC
GEORADIUSBYMEMBER seoul_stores "스타벅스_홍대입구역점" 500 m WITHDIST ASC  
GEORADIUSBYMEMBER seoul_stores "스타벅스_명동점" 500 m WITHDIST ASC
GEORADIUSBYMEMBER seoul_stores "스타벅스_잠실역점" 500 m WITHDIST ASC

# 가장 경쟁이 치열한 지역 확인 (매장 밀도가 높은 곳)
GEORADIUS seoul_stores 127.0276 37.4979 300 m  # 강남역
GEORADIUS seoul_stores 126.9240 37.5563 300 m  # 홍대
GEORADIUS seoul_stores 126.9849 37.5636 300 m  # 명동
GEORADIUS seoul_stores 127.1000 37.5133 300 m  # 잠실
```

### 4-3. 배달 서비스 권역 설정
```redis
# 각 매장의 배달 가능 권역 (1.5km) 확인
GEORADIUSBYMEMBER seoul_stores "맥도날드_강남역점" 1.5 km WITHDIST COUNT 50
GEORADIUSBYMEMBER seoul_stores "맥도날드_홍대점" 1.5 km WITHDIST COUNT 50
GEORADIUSBYMEMBER seoul_stores "맥도날드_명동점" 1.5 km WITHDIST COUNT 50
GEORADIUSBYMEMBER seoul_stores "맥도날드_잠실점" 1.5 km WITHDIST COUNT 50
```

## 🏢 실습 5: 확장 데이터셋 - 다양한 업종 추가

### 5-1. 편의점 데이터 추가
```redis
# 편의점 위치 데이터 등록
GEOADD convenience_stores 127.0275 37.4977 "세븐일레븐_강남역점"
GEOADD convenience_stores 127.0285 37.4983 "CU_강남역점"
GEOADD convenience_stores 127.0268 37.4974 "GS25_강남역점"
GEOADD convenience_stores 126.9242 37.5565 "세븐일레븐_홍대점"
GEOADD convenience_stores 126.9252 37.5572 "CU_홍대점"
GEOADD convenience_stores 126.9851 37.5638 "세븐일레븐_명동점"
GEOADD convenience_stores 126.9847 37.5632 "GS25_명동점"
GEOADD convenience_stores 127.1002 37.5135 "세븐일레븐_잠실점"
GEOADD convenience_stores 127.1008 37.5142 "CU_잠실점"
```

### 5-2. 약국 데이터 추가
```redis
# 약국 위치 데이터 등록  
GEOADD pharmacies 127.0273 37.4976 "온누리약국_강남역점"
GEOADD pharmacies 127.0287 37.4984 "명성약국_강남역점"
GEOADD pharmacies 126.9244 37.5567 "홍대약국"
GEOADD pharmacies 126.9853 37.5641 "명동약국"
GEOADD pharmacies 127.1004 37.5137 "잠실약국"
```

### 5-3. 통합 검색 시나리오
```redis
# 현재 위치 기준 종합 생활 인프라 검색
# 위치: 강남역 (127.0280, 37.4980)

# 1. 음식점 (500m 내)
GEORADIUS seoul_stores 127.0280 37.4980 500 m WITHDIST ASC

# 2. 편의점 (300m 내)  
GEORADIUS convenience_stores 127.0280 37.4980 300 m WITHDIST ASC

# 3. 약국 (1km 내)
GEORADIUS pharmacies 127.0280 37.4980 1 km WITHDIST ASC
```

## 📊 실습 6: 성능 분석 및 최적화

### 6-1. 데이터 구조 분석
```redis
# 각 키의 메모리 사용량 확인
MEMORY USAGE seoul_stores
MEMORY USAGE convenience_stores  
MEMORY USAGE pharmacies

# 전체 키 통계
INFO keyspace

# Sorted Set으로서의 특성 확인
TYPE seoul_stores
ZCARD seoul_stores
ZRANGE seoul_stores 0 -1 WITHSCORES
```

### 6-2. 검색 성능 테스트
```redis
# 다양한 반경에서의 검색 결과 비교
GEORADIUS seoul_stores 127.0280 37.4980 100 m WITHDIST ASC
GEORADIUS seoul_stores 127.0280 37.4980 500 m WITHDIST ASC  
GEORADIUS seoul_stores 127.0280 37.4980 1 km WITHDIST ASC
GEORADIUS seoul_stores 127.0280 37.4980 5 km WITHDIST ASC
GEORADIUS seoul_stores 127.0280 37.4980 10 km WITHDIST ASC

# COUNT 제한의 효과
GEORADIUS seoul_stores 127.0280 37.4980 10 km WITHDIST ASC COUNT 5
GEORADIUS seoul_stores 127.0280 37.4980 10 km WITHDIST ASC COUNT 10  
GEORADIUS seoul_stores 127.0280 37.4980 10 km WITHDIST ASC COUNT 20
```

## 🎮 실습 7: 고급 활용 시나리오

### 7-1. 동적 위치 업데이트
```redis
# 배달원 위치 추적 시스템
GEOADD delivery_riders 127.0270 37.4975 "배달원_김철수"
GEOADD delivery_riders 127.0285 37.4985 "배달원_이영희"
GEOADD delivery_riders 126.9245 37.5570 "배달원_박민수"

# 배달원 위치 실시간 업데이트
GEOADD delivery_riders 127.0275 37.4978 "배달원_김철수"  # 이동
GEOADD delivery_riders 127.0290 37.4988 "배달원_이영희"  # 이동

# 특정 지점에서 가장 가까운 배달원 찾기
GEORADIUS delivery_riders 127.0280 37.4980 2 km WITHDIST ASC COUNT 1
```

### 7-2. 지역별 매장 밀도 분석
```redis
# 각 상권별 매장 밀도 비교
# 강남권 (반경 1km 내 매장 수)
GEORADIUS seoul_stores 127.0276 37.4979 1 km

# 홍대권
GEORADIUS seoul_stores 126.9240 37.5563 1 km

# 명동권  
GEORADIUS seoul_stores 126.9849 37.5636 1 km

# 잠실권
GEORADIUS seoul_stores 127.1000 37.5133 1 km
```

### 7-3. 매장 추천 시스템
```redis
# 브랜드별 최적 위치 추천 (경쟁업체가 적은 곳)
# 새로운 스타벅스 후보지: 127.0300, 37.5000
GEORADIUS seoul_stores 127.0300 37.5000 500 m WITHDIST ASC

# 기존 매장과의 거리 확인
GEODIST seoul_stores "스타벅스_강남역점" NONEXISTENT
# 새로운 위치 임시 등록 후 거리 측정
GEOADD temp_locations 127.0300 37.5000 "신규_후보지"
GEODIST temp_locations "신규_후보지" seoul_stores "스타벅스_강남역점"
```

## 💡 실무 팁 및 Best Practices

### 1. 데이터 모델링 팁
```redis
# 키 네이밍 전략 예시
# 업종별 분리: stores:restaurants, stores:cafes, stores:convenience
# 지역별 분리: stores:seoul, stores:busan, stores:daegu
# 하이브리드: seoul:restaurants, seoul:cafes

# 예시: 업종별 분리 구조
GEOADD restaurants:seoul 127.0276 37.4979 "맥도날드_강남역점"
GEOADD cafes:seoul 127.0276 37.4979 "스타벅스_강남역점"
GEOADD convenience:seoul 127.0275 37.4977 "세븐일레븐_강남역점"
```

### 2. 성능 최적화 전략
```redis
# 1. 적절한 반경 설정 (너무 큰 반경은 성능 저하)
# 좋은 예: 도보권 500m, 차량 이동권 5km
# 나쁜 예: 무제한 검색 (전체 도시 범위)

# 2. COUNT 제한 활용
GEORADIUS seoul_stores 127.0280 37.4980 5 km WITHDIST ASC COUNT 10

# 3. 필요한 정보만 요청
GEORADIUS seoul_stores 127.0280 37.4980 1 km  # 매장명만
# vs
GEORADIUS seoul_stores 127.0280 37.4980 1 km WITHDIST WITHCOORD  # 모든 정보
```

### 3. 에러 처리 및 예외 상황
```redis
# 존재하지 않는 매장 검색
GEORADIUSBYMEMBER seoul_stores "존재하지않는매장" 1 km

# 잘못된 좌표 (위도/경도 범위 초과)
GEOADD test_geo 200 100 "잘못된좌표"  # 에러 발생

# 올바른 좌표 범위: 경도 -180~180, 위도 -85.05112878~85.05112878
```

## 🔧 실습 8: 데이터 관리 및 유지보수

### 8-1. 매장 정보 수정 및 삭제
```redis
# 매장 이전 (좌표 업데이트)
GEOADD seoul_stores 127.0280 37.4982 "스타벅스_강남역점"  # 동일명으로 덮어쓰기

# 매장 폐점 (삭제)
ZREM seoul_stores "롯데리아_강남역점"

# 삭제 확인
GEOPOS seoul_stores "롯데리아_강남역점"  # null 반환

# 전체 데이터 초기화 (주의!)
# FLUSHALL  # 전체 Redis 데이터 삭제
# DEL seoul_stores  # 특정 키만 삭제
```

### 8-2. 데이터 백업 및 복원
```redis
# 현재 데이터 전체 조회 (백업 목적)
ZRANGE seoul_stores 0 -1 WITHSCORES
ZRANGE convenience_stores 0 -1 WITHSCORES
ZRANGE pharmacies 0 -1 WITHSCORES
ZRANGE delivery_riders 0 -1 WITHSCORES

# 메모리 사용량 모니터링
INFO memory
MEMORY USAGE seoul_stores
```

## 📋 종합 실습 과제

### 과제 1: 완전한 주변 검색 시스템 구현
다음 요구사항을 만족하는 검색 시스템을 구현하세요:

1. **다중 업종 통합 검색**
```redis
# 현재 위치: 127.0280, 37.4980
# 요구사항: 반경 1km 내 모든 편의시설 통합 검색

# 음식점 검색
GEORADIUS seoul_stores 127.0280 37.4980 1 km WITHDIST ASC

# 편의점 검색  
GEORADIUS convenience_stores 127.0280 37.4980 1 km WITHDIST ASC

# 약국 검색
GEORADIUS pharmacies 127.0280 37.4980 1 km WITHDIST ASC
```

2. **거리별 우선순위 설정**
```redis
# 도보권 (200m): 최우선
GEORADIUS seoul_stores 127.0280 37.4980 200 m WITHDIST ASC COUNT 5

# 근거리 (500m): 우선  
GEORADIUS seoul_stores 127.0280 37.4980 500 m WITHDIST ASC COUNT 10

# 중거리 (1km): 일반
GEORADIUS seoul_stores 127.0280 37.4980 1 km WITHDIST ASC COUNT 15
```

### 과제 2: 상권 분석 시스템
각 상권의 특성을 분석하세요:

```redis
# 1. 상권별 매장 밀도 (반경 500m 기준)
GEORADIUS seoul_stores 127.0276 37.4979 500 m  # 강남역
GEORADIUS seoul_stores 126.9240 37.5563 500 m  # 홍대  
GEORADIUS seoul_stores 126.9849 37.5636 500 m  # 명동
GEORADIUS seoul_stores 127.1000 37.5133 500 m  # 잠실

# 2. 브랜드 간 경쟁 강도 분석
GEORADIUSBYMEMBER seoul_stores "스타벅스_강남역점" 300 m WITHDIST ASC
GEORADIUSBYMEMBER seoul_stores "맥도날드_강남역점" 300 m WITHDIST ASC
```

### 과제 3: 실시간 위치 서비스
배달 서비스를 위한 실시간 추적 시스템을 구현하세요:

```redis
# 1. 배달원 초기 위치 등록
GEOADD live_delivery 127.0270 37.4975 "라이더_001"
GEOADD live_delivery 127.0285 37.4985 "라이더_002"  
GEOADD live_delivery 126.9245 37.5570 "라이더_003"

# 2. 주문 위치 기준 최적 배달원 배정
GEORADIUS live_delivery 127.0280 37.4980 3 km WITHDIST ASC COUNT 1

# 3. 배달원 위치 업데이트 (이동 시뮬레이션)
GEOADD live_delivery 127.0275 37.4978 "라이더_001"  # 목적지로 이동
GEOADD live_delivery 127.0278 37.4979 "라이더_001"  # 계속 이동
```

## ✅ 학습 완료 체크리스트

### 기본 개념 이해
- [ ] Geospatial 데이터 타입의 개념과 특징 이해
- [ ] 위도/경도 좌표 시스템 이해
- [ ] Redis 내부적으로 Sorted Set 기반 구현 이해

### 핵심 명령어 숙련도
- [ ] `GEOADD`: 위치 데이터 등록
- [ ] `GEOPOS`: 좌표 조회
- [ ] `GEODIST`: 거리 계산
- [ ] `GEORADIUS`: 좌표 기준 반경 검색
- [ ] `GEORADIUSBYMEMBER`: 기존 멤버 기준 반경 검색
- [ ] `GEOHASH`: 지리적 해시값 조회

### 실무 활용 능력
- [ ] 주변 매장 찾기 시스템 구현
- [ ] 다중 업종 통합 검색 구현
- [ ] 거리별 우선순위 검색 구현
- [ ] 실시간 위치 추적 시스템 구현

---
*본 교안은 Windows 환경의 Docker Desktop과 VSCode PowerShell을 기준으로 작성되었습니다.*