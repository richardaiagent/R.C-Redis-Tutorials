# Redis 초급 실습 07 - Set 데이터 타입 실습

## 학습 목표
- Redis Set 데이터 타입의 특징과 사용법을 이해한다
- 태그 시스템과 중복 제거 기능을 구현한다
- 사용자 태그 및 친구 목록 관리 시스템을 구현한다

## Set 데이터 타입 개요
- **특징**: 중복을 허용하지 않는 순서 없는 문자열 집합
- **구현**: 해시 테이블 (Hash Table)
- **용도**: 태그, 친구 목록, 권한 관리, 중복 제거 등
- **장점**: O(1) 시간 복잡도로 추가/삭제/조회 가능

## 실습 환경 준비
```bash
# Redis 컨테이너 실행 (이미 실행 중이라면 생략)
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

# Redis CLI 접속
docker exec -it redis-lab redis-cli
```

## 실습 1: 기본 Set 명령어

### 1.1 Set 생성 및 요소 추가
```redis
# Set에 요소 추가
SADD programming:languages "Python"
SADD programming:languages "Java"
SADD programming:languages "JavaScript"
SADD programming:languages "Python"  # 중복 - 추가되지 않음

# 여러 요소 한번에 추가
SADD web:technologies "HTML" "CSS" "JavaScript" "React" "Vue" "Angular"
```

### 1.2 Set 조회 및 확인
```redis
# Set의 모든 멤버 조회
SMEMBERS programming:languages
SMEMBERS web:technologies

# Set 크기 확인
SCARD programming:languages
SCARD web:technologies

# 특정 요소 존재 여부 확인
SISMEMBER programming:languages "Python"
SISMEMBER programming:languages "C++"
```

### 1.3 Set에서 요소 제거
```redis
# 특정 요소 제거
SREM programming:languages "Java"

# 결과 확인
SMEMBERS programming:languages
SCARD programming:languages
```

## 실습 2: 사용자 태그 시스템 구현

### 2.1 사용자별 관심사 태그 생성
```redis
# 홍길동의 관심사 태그
SADD user:홍길동:interests "개발" "영화" "여행" "독서" "커피"

# 김영희의 관심사 태그
SADD user:김영희:interests "디자인" "영화" "요리" "독서" "음악"

# 이철수의 관심사 태그
SADD user:이철수:interests "개발" "게임" "여행" "운동" "음악"

# 박민수의 관심사 태그
SADD user:박민수:interests "마케팅" "여행" "사진" "커피" "독서"
```

### 2.2 관심사별 사용자 그룹 생성
```redis
# 관심사별로 사용자 그룹화
SADD interest:개발 "홍길동" "이철수"
SADD interest:영화 "홍길동" "김영희"
SADD interest:여행 "홍길동" "이철수" "박민수"
SADD interest:독서 "홍길동" "김영희" "박민수"
SADD interest:커피 "홍길동" "박민수"
SADD interest:음악 "김영희" "이철수"
```

### 2.3 사용자 태그 조회 및 분석
```redis
# 각 사용자의 관심사 확인
SMEMBERS user:홍길동:interests
SMEMBERS user:김영희:interests

# 특정 관심사를 가진 사용자 목록
SMEMBERS interest:개발
SMEMBERS interest:여행

# 관심사별 사용자 수 확인
SCARD interest:개발
SCARD interest:영화
SCARD interest:여행
```

## 실습 3: 친구 관계 시스템 구현

### 3.1 친구 관계 설정
```redis
# 홍길동의 친구 목록
SADD friends:홍길동 "김영희" "이철수" "박민수" "최지원"

# 김영희의 친구 목록
SADD friends:김영희 "홍길동" "이철수" "박민수" "정하나"

# 이철수의 친구 목록
SADD friends:이철수 "홍길동" "김영희" "박민수" "강동원"

# 박민수의 친구 목록
SADD friends:박민수 "홍길동" "김영희" "이철수" "윤서연"
```

### 3.2 친구 관계 분석
```redis
# 각 사용자의 친구 수 확인
SCARD friends:홍길동
SCARD friends:김영희

# 특정 사용자가 친구인지 확인
SISMEMBER friends:홍길동 "김영희"
SISMEMBER friends:홍길동 "낯선사람"

# 모든 친구 목록 조회
SMEMBERS friends:홍길동
```

### 3.3 상호 친구 찾기 (교집합)
```redis
# 홍길동과 김영희의 공통 친구 찾기
SINTER friends:홍길동 friends:김영희

# 홍길동과 이철수의 공통 친구 찾기
SINTER friends:홍길동 friends:이철수

# 결과를 새로운 Set에 저장
SINTERSTORE common:홍길동_김영희 friends:홍길동 friends:김영희
SMEMBERS common:홍길동_김영희
```

## 실습 4: Set 집합 연산 실습

### 4.1 합집합 연산 (UNION)
```redis
# 개발자와 디자이너 그룹 생성
SADD team:developers "홍길동" "이철수" "김개발" "박프로"
SADD team:designers "김영희" "박디자인" "최크리에이터" "정아티스트"

# 개발팀과 디자인팀 전체 인원 (합집합)
SUNION team:developers team:designers

# 결과를 새로운 Set에 저장
SUNIONSTORE team:all team:developers team:designers
SMEMBERS team:all
SCARD team:all
```

### 4.2 차집합 연산 (DIFFERENCE)
```redis
# 전체 직원과 휴가자 목록
SADD company:all "홍길동" "김영희" "이철수" "박민수" "최지원" "정하나"
SADD company:vacation "김영희" "최지원"

# 출근한 직원 목록 (차집합)
SDIFF company:all company:vacation

# 결과 저장
SDIFFSTORE company:working company:all company:vacation
SMEMBERS company:working
```

### 4.3 교집합과 집합 연산 활용
```redis
# 프론트엔드와 백엔드 개발자 그룹
SADD skills:frontend "홍길동" "김영희" "박프론트" "최리액트"
SADD skills:backend "홍길동" "이철수" "박백엔드" "최노드"

# 풀스택 개발자 찾기 (교집합)
SINTER skills:frontend skills:backend

# 프론트엔드 전용 개발자 (차집합)
SDIFF skills:frontend skills:backend

# 백엔드 전용 개발자 (차집합)
SDIFF skills:backend skills:frontend
```

## 실습 5: 권한 관리 시스템

### 5.1 사용자별 권한 설정
```redis
# 관리자 권한
SADD permissions:admin "user_create" "user_delete" "user_edit" "system_config" "data_export"

# 편집자 권한
SADD permissions:editor "content_write" "content_edit" "content_delete" "media_upload"

# 일반 사용자 권한
SADD permissions:user "content_read" "profile_edit" "comment_write"

# 사용자별 역할 할당
SADD user:홍길동:roles "admin"
SADD user:김영희:roles "editor"
SADD user:이철수:roles "user"
SADD user:박민수:roles "editor" "user"
```

### 5.2 권한 확인 시스템
```redis
# 특정 사용자의 권한 확인 함수 시뮬레이션
# 홍길동이 'user_delete' 권한이 있는지 확인
SISMEMBER permissions:admin "user_delete"

# 김영희가 'content_write' 권한이 있는지 확인
SISMEMBER permissions:editor "content_write"

# 박민수의 모든 가능 권한 (editor + user 권한의 합집합)
SUNION permissions:editor permissions:user
```

## 실습 6: 온라인 사용자 추적

### 6.1 온라인 사용자 관리
```redis
# 현재 온라인 사용자 Set
SADD online:users "홍길동" "김영희" "이철수"

# 사용자 로그인 시 추가
SADD online:users "박민수"
SADD online:users "최지원"

# 현재 온라인 사용자 확인
SMEMBERS online:users
SCARD online:users

# 사용자 로그아웃 시 제거
SREM online:users "김영희"

# 업데이트된 온라인 사용자 목록
SMEMBERS online:users
```

### 6.2 활성 세션 관리
```redis
# 활성 세션 ID 관리
SADD active:sessions "sess_001" "sess_002" "sess_003" "sess_004"

# 특정 세션 만료 시 제거
SREM active:sessions "sess_002"

# 현재 활성 세션 수
SCARD active:sessions

# 랜덤 세션 하나 가져오기 (모니터링용)
SRANDMEMBER active:sessions
SRANDMEMBER active:sessions 2
```

## 실습 7: 중복 제거 시스템

### 7.1 이메일 구독자 중복 제거
```redis
# 뉴스레터 구독자 목록 (중복 포함 시나리오)
SADD newsletter:tech "user1@example.com" "user2@example.com" "user3@example.com"
SADD newsletter:tech "user1@example.com"  # 중복 시도 - 무시됨
SADD newsletter:tech "user4@example.com" "user2@example.com"  # user2 중복 무시

# 최종 구독자 목록 (중복 자동 제거됨)
SMEMBERS newsletter:tech
SCARD newsletter:tech
```

### 7.2 방문자 추적 (고유 방문자)
```redis
# 일별 고유 방문자 추적
SADD visitors:2024-01-15 "user123" "user456" "user789"
SADD visitors:2024-01-15 "user123"  # 재방문 - 중복 제거
SADD visitors:2024-01-15 "user999" "user111"

# 다음날 방문자
SADD visitors:2024-01-16 "user123" "user456" "user555" "user777"

# 각 날짜별 고유 방문자 수
SCARD visitors:2024-01-15
SCARD visitors:2024-01-16

# 두 날 모두 방문한 사용자 (교집합)
SINTER visitors:2024-01-15 visitors:2024-01-16
```

## 실습 8: 추천 시스템 기초

### 8.1 상품 좋아요 시스템
```redis
# 상품별 좋아요한 사용자
SADD likes:product_001 "홍길동" "김영희" "이철수"
SADD likes:product_002 "홍길동" "박민수" "최지원"
SADD likes:product_003 "김영희" "이철수" "박민수"

# 사용자별 좋아요한 상품
SADD user:홍길동:likes "product_001" "product_002"
SADD user:김영희:likes "product_001" "product_003"
SADD user:이철수:likes "product_001" "product_003"
```

### 8.2 유사 취향 사용자 찾기
```redis
# 홍길동과 비슷한 취향의 사용자 찾기
# (같은 상품을 좋아하는 사용자들)
SINTER user:홍길동:likes user:김영희:likes
SINTER user:홍길동:likes user:이철수:likes

# 홍길동이 좋아할 만한 상품 추천
# (비슷한 취향 사용자가 좋아하는 다른 상품)
SDIFF user:김영희:likes user:홍길동:likes
```

## 실습 9: 성능 및 메모리 최적화

###