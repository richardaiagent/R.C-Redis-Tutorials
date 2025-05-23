# Redis 초급 7번 - Set 데이터 타입 실습 교안

## 📋 학습 목표
- Redis Set 데이터 타입의 특성과 장점 이해
- Set 기본 명령어 (SADD, SMEMBERS, SREM 등) 숙지
- 집합 연산 (합집합, 교집합, 차집합) 활용
- 태그 시스템 구현을 통한 실무 패턴 학습
- 친구 목록 관리 시스템 구현
- 중복 제거 및 유니크 데이터 관리 방법 습득

## 🎯 Set 데이터 타입 개념

### Set의 특징
- **순서가 없는 컬렉션**: 데이터의 순서를 보장하지 않음
- **중복 불허**: 동일한 값을 여러 번 저장할 수 없음
- **빠른 멤버십 검사**: O(1) 시간복잡도로 멤버 존재 확인
- **집합 연산 지원**: 합집합, 교집합, 차집합 등

### 활용 사례
- 태그 시스템 (블로그, 상품 태그)
- 사용자 친구/팔로워 목록
- 중복 제거 (방문자 추적, 고유 아이템)
- 권한 그룹 관리
- 카테고리 분류

## 🚀 실습 환경 준비

### VSCode PowerShell에서 Redis 컨테이너 접속
```powershell
# Redis 컨테이너가 실행 중인지 확인
docker ps

# Redis 컨테이너가 없다면 실행
docker run -d --name redis-lab -p 6379:6379 -v redis-data:/data redis:7-alpine

# Redis CLI 접속
docker exec -it redis-lab redis-cli

# 연결 확인
ping
# 응답: PONG
```

## 📚 Set 기본 명령어 실습

### 실습 1: Set 기본 조작

#### 1-1. Set 생성 및 멤버 추가
```redis
# 프로그래밍 언어 태그 Set 생성
SADD programming_languages "Python" "JavaScript" "Java" "Go" "Rust"

# 웹 기술 태그 Set 생성
SADD web_technologies "HTML" "CSS" "JavaScript" "React" "Vue.js" "Node.js"

# 데이터베이스 태그 Set 생성
SADD databases "MySQL" "PostgreSQL" "MongoDB" "Redis" "Elasticsearch"

# 추가된 멤버 수 확인
SCARD programming_languages
SCARD web_technologies
SCARD databases
```

#### 1-2. Set 멤버 조회 및 확인
```redis
# 모든 멤버 조회
SMEMBERS programming_languages
SMEMBERS web_technologies
SMEMBERS databases

# 특정 멤버 존재 확인
SISMEMBER programming_languages "Python"
SISMEMBER programming_languages "PHP"
SISMEMBER web_technologies "JavaScript"

# 랜덤 멤버 조회
SRANDMEMBER programming_languages
SRANDMEMBER programming_languages 2
SRANDMEMBER web_technologies 3
```

#### 1-3. Set 멤버 제거
```redis
# 특정 멤버 제거
SREM programming_languages "Java"
SREM web_technologies "Vue.js"

# 제거 확인
SMEMBERS programming_languages
SMEMBERS web_technologies

# 랜덤 멤버 제거 (POP)
SPOP databases
SPOP databases 2

# 남은 멤버 확인
SMEMBERS databases
```

## 🏷️ 실습 2: 사용자 태그 시스템 구현

### 2-1. 사용자별 관심사 태그 설정
```redis
# 사용자별 관심사 태그 등록
SADD user:1001:interests "프로그래밍" "웹개발" "데이터베이스" "클라우드" "AI"
SADD user:1002:interests "디자인" "UI/UX" "프로그래밍" "모바일앱" "게임개발"
SADD user:1003:interests "데이터분석" "머신러닝" "AI" "통계" "파이썬"
SADD user:1004:interests "웹개발" "백엔드" "데이터베이스" "API" "마이크로서비스"
SADD user:1005:interests "프론트엔드" "JavaScript" "React" "UI/UX" "웹개발"

# 각 사용자의 관심사 확인
SMEMBERS user:1001:interests
SMEMBERS user:1002:interests
SMEMBERS user:1003:interests
SMEMBERS user:1004:interests
SMEMBERS user:1005:interests

# 관심사 개수 확인
SCARD user:1001:interests
SCARD user:1002:interests
```

### 2-2. 태그별 사용자 그룹 생성
```redis
# 각 태그에 관심있는 사용자들 그룹핑
SADD tag:프로그래밍:users "user:1001" "user:1002"
SADD tag:웹개발:users "user:1001" "user:1004" "user:1005"
SADD tag:데이터베이스:users "user:1001" "user:1004"
SADD tag:AI:users "user:1001" "user:1003"
SADD tag:디자인:users "user:1002"
SADD tag:UI/UX:users "user:1002" "user:1005"
SADD tag:데이터분석:users "user:1003"
SADD tag:JavaScript:users "user:1005"
SADD tag:React:users "user:1005"

# 태그별 사용자 수 확인
SCARD tag:프로그래밍:users
SCARD tag:웹개발:users
SCARD tag:AI:users

# 특정 태그에 관심있는 사용자 목록
SMEMBERS tag:웹개발:users
SMEMBERS tag:AI:users
```

### 2-3. 관심사 기반 사용자 매칭
```redis
# 사용자 간 공통 관심사 찾기 (교집합)
SINTER user:1001:interests user:1002:interests
SINTER user:1001:interests user:1003:interests
SINTER user:1001:interests user:1004:interests

# 결과를 새로운 Set에 저장
SINTERSTORE common:1001:1004 user:1001:interests user:1004:interests
SMEMBERS common:1001:1004

# 공통 관심사 개수 확인
SCARD common:1001:1004

# 사용자의 유니크한 관심사 찾기 (차집합)
SDIFF user:1001:interests user:1004:interests
SDIFF user:1003:interests user:1001:interests
```

## 👥 실습 3: 친구 목록 관리 시스템

### 3-1. 사용자 친구 관계 설정
```redis
# 사용자별 친구 목록 생성
SADD user:1001:friends "user:1002" "user:1003" "user:1004"
SADD user:1002:friends "user:1001" "user:1005"
SADD user:1003:friends "user:1001" "user:1004" "user:1005"
SADD user:1004:friends "user:1001" "user:1003"
SADD user:1005:friends "user:1002" "user:1003"

# 친구 목록 확인
SMEMBERS user:1001:friends
SMEMBERS user:1002:friends
SMEMBERS user:1003:friends

# 친구 수 확인
SCARD user:1001:friends
SCARD user:1003:friends
```

### 3-2. 친구 관계 분석
```redis
# 공통 친구 찾기 (두 사용자의 친구 목록 교집합)
SINTER user:1001:friends user:1003:friends
SINTER user:1002:friends user:1005:friends

# 결과를 저장
SINTERSTORE mutual:1001:1003 user:1001:friends user:1003:friends
SMEMBERS mutual:1001:1003

# 친구 추천 (친구의 친구 - 자신의 친구 - 자신)
# user:1001의 친구들의 친구 목록 합치기
SUNION user:1002:friends user:1003:friends user:1004:friends
SUNIONSTORE potential:1001 user:1002:friends user:1003:friends user:1004:friends

# user:1001과 이미 친구인 사람들과 자신을 제외
SDIFF potential:1001 user:1001:friends
SREM potential:1001 "user:1001"
SMEMBERS potential:1001
```

### 3-3. 친구 그룹 관리
```redis
# 친구 그룹 생성 (직장 동료, 학교 친구, 가족 등)
SADD user:1001:work_friends "user:1004" "user:1005"
SADD user:1001:school_friends "user:1002" "user:1003"
SADD user:1001:family "user:1006" "user:1007"

# 그룹별 친구 확인
SMEMBERS user:1001:work_friends
SMEMBERS user:1001:school_friends

# 전체 친구 목록과 비교
SUNION user:1001:work_friends user:1001:school_friends user:1001:family
```

## 🔍 실습 4: 집합 연산 활용

### 4-1. 복잡한 집합 연산 실습
```redis
# 여러 사용자의 관심사 합집합 (전체 관심사 목록)
SUNION user:1001:interests user:1002:interests user:1003:interests
SUNIONSTORE all_interests user:1001:interests user:1002:interests user:1003:interests user:1004:interests user:1005:interests

# 전체 관심사 확인
SMEMBERS all_interests
SCARD all_interests

# 가장 인기있는 관심사 찾기 (여러 사용자가 공통으로 가진 관심사)
# 프로그래밍에 관심있는 사용자들의 다른 공통 관심사
SINTER user:1001:interests user:1002:interests

# 웹개발에 관심있는 사용자들 찾기
SINTER tag:웹개발:users tag:프로그래밍:users
```

### 4-2. 동적 집합 생성 및 관리
```redis
# 온라인 사용자 추적
SADD online_users "user:1001" "user:1003" "user:1005"

# 특정 이벤트 참여자
SADD event:webinar:participants "user:1001" "user:1002" "user:1004"
SADD event:workshop:participants "user:1001" "user:1003" "user:1005"

# 이벤트 참여자 중 온라인 사용자
SINTER online_users event:webinar:participants
SINTER online_users event:workshop:participants

# 두 이벤트 모두 참여한 사용자
SINTER event:webinar:participants event:workshop:participants
```

## 📊 실습 5: 실시간 데이터 추적

### 5-1. 일일 방문자 추적
```redis
# 오늘 방문자 (중복 제거)
SADD visitors:2025-05-23 "user:1001" "user:1002" "user:1003" "user:1001" "user:1004"

# 어제 방문자
SADD visitors:2025-05-22 "user:1002" "user:1003" "user:1005" "user:1006"

# 오늘 방문자 수 (중복 제거됨)
SCARD visitors:2025-05-23
SMEMBERS visitors:2025-05-23

# 연속 방문자 (오늘과 어제 모두 방문)
SINTER visitors:2025-05-23 visitors:2025-05-22

# 신규 방문자 (오늘만 방문)
SDIFF visitors:2025-05-23 visitors:2025-05-22
```

### 5-2. 상품 태그 시스템
```redis
# 상품별 태그 설정
SADD product:laptop:001:tags "전자제품" "컴퓨터" "업무용" "고성능" "휴대용"
SADD product:smartphone:002:tags "전자제품" "모바일" "통신" "카메라" "휴대용"
SADD product:tablet:003:tags "전자제품" "모바일" "미디어" "휴대용" "터치스크린"

# 태그별 상품 그룹
SADD tag:전자제품:products "product:laptop:001" "product:smartphone:002" "product:tablet:003"
SADD tag:휴대용:products "product:laptop:001" "product:smartphone:002" "product:tablet:003"
SADD tag:모바일:products "product:smartphone:002" "product:tablet:003"

# 특정 태그 조합으로 상품 검색
SINTER tag:전자제품:products tag:휴대용:products
SINTER tag:모바일:products tag:휴대용:products

# 상품의 유니크한 태그 (다른 상품과 구분되는 태그)
SDIFF product:laptop:001:tags product:smartphone:002:tags
```

## 🔧 Set 성능 최적화 및 모니터링

### 성능 측정
```redis
# Set 크기별 성능 비교
# 큰 Set 생성 (성능 테스트용)
SADD large_set {1..10000}  # 이 명령은 실제로는 루프로 실행해야 함

# 멤버 존재 확인 속도 테스트
SISMEMBER large_set "5000"
SISMEMBER large_set "15000"

# 메모리 사용량 확인
MEMORY USAGE programming_languages
MEMORY USAGE user:1001:interests
MEMORY USAGE large_set
```

### 데이터 정리 및 관리
```redis
# 빈 Set 정리
SCARD empty_set  # 0이면 빈 Set

# Set 백업 (다른 키로 복사)
SUNIONSTORE backup:user:1001:interests user:1001:interests

# Set 통계 정보
SCARD user:1001:interests
SRANDMEMBER user:1001:interests 1
```

## 🎯 종합 실습 과제

### 과제 1: 소셜 네트워크 분석
다음 요구사항을 만족하는 시스템을 구현하세요:
1. 5명의 사용자와 각각의 관심사 설정 (최소 3개씩)
2. 사용자 간 친구 관계 설정
3. 공통 관심사를 가진 사용자 매칭
4. 친구 추천 시스템 구현

### 과제 2: 태그 기반 콘텐츠 관리
블로그 시스템의 태그 관리 기능 구현:
1. 10개의 블로그 포스트와 각각의 태그 설정
2. 태그별 포스트 그룹핑
3. 인기 태그 분석 (여러 포스트에서 사용되는 태그)
4. 관련 포스트 추천 (비슷한 태그를 가진 포스트)

### 과제 3: 실시간 활동 추적
사용자 활동 추적 시스템 구현:
1. 일주일간의 일일 방문자 데이터 생성
2. 연속 방문자 분석
3. 신규/재방문자 구분
4. 활성 사용자 정의 및 추출

## 💡 실무 응용 팁

### Set 사용 시 고려사항
1. **메모리 효율성**: Set은 해시테이블 기반으로 메모리를 많이 사용
2. **집합 연산 비용**: 큰 Set 간의 연산은 시간이 오래 걸림
3. **데이터 타입**: Set 멤버는 문자열만 가능
4. **순서 보장 없음**: 순서가 중요하다면 Sorted Set 사용

### 성능 최적화 방법
```redis
# 대용량 Set 처리 시 SCAN 사용
SSCAN large_set 0 COUNT 100

# 임시 Set 생성 후 정리
SUNIONSTORE temp_result set1 set2 set3
# 작업 완료 후
DEL temp_result

# Set 크기 제한 설정 (설정 파일에서)
# set-max-intset-entries 512
```

## ✅ 학습 완료 체크리스트

### 기본 개념 이해
- [ ] Set 데이터 타입의 특성 이해
- [ ] 기본 Set 명령어 숙지 (SADD, SMEMBERS, SREM, SCARD 등)
- [ ] 멤버십 검사 방법 이해 (SISMEMBER)

### 집합 연산 활용
- [ ] 합집합(SUNION) 연산 활용
- [ ] 교집합(SINTER) 연산 활용  
- [ ] 차집합(SDIFF) 연산 활용
- [ ] 집합 연산 결과 저장 방법 숙지

### 실무 패턴 구현
- [ ] 태그 시스템 구현 가능
- [ ] 친구 목록 관리 시스템 구현
- [ ] 중복 제거 시스템 구현
- [ ] 실시간 데이터 추적 구현

### 성능 및 최적화
- [ ] Set 성능 특성 이해
- [ ] 메모리 사용량 모니터링 방법 숙지
- [ ] 대용량 Set 처리 방법 이해

## 🔗 다음 단계
다음은 **초급 8번 - Sorted Set 데이터 타입 실습**입니다. Set에서 순서와 점수 개념이 추가된 Sorted Set을 활용하여 리더보드와 랭킹 시스템을 구현해보겠습니다.

---
*본 교안은 Docker Desktop과 VSCode PowerShell 환경을 기준으로 작성되었습니다.*