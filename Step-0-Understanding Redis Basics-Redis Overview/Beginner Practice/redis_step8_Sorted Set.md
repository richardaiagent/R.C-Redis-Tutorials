# Redis 초급 8번 - Sorted Set 데이터 타입 실습 교안

## 📋 학습 목표
- Redis Sorted Set 데이터 타입의 특성과 활용법 이해
- Sorted Set 기본 명령어 (ZADD, ZRANGE, ZREM 등) 숙지
- 점수 기반 정렬과 범위 검색 기능 활용
- 리더보드 시스템 구현을 통한 실무 패턴 학습
- 랭킹 시스템과 점수 기반 데이터 분석 구현
- 시간 기반 데이터 정렬 및 순위 매기기 활용

## 🎯 Sorted Set 데이터 타입 개념

### Sorted Set의 특징
- **순서가 있는 컬렉션**: Score(점수)에 따라 자동 정렬
- **중복 불허**: 동일한 멤버는 하나만 존재 (점수는 업데이트 가능)
- **빠른 범위 검색**: O(log N) 시간복잡도로 범위 조회
- **양방향 정렬**: 오름차순/내림차순 모두 지원
- **점수와 순위**: 각 멤버에 점수(Score)와 순위(Rank) 부여

### 활용 사례
- 게임 리더보드 (점수 순위)
- 인기 콘텐츠 랭킹 (조회수, 좋아요)
- 시간 기반 데이터 (최신 뉴스, 타임라인)
- 우선순위 큐 (작업 스케줄링)
- 지역별 순위 (거리, 평점)

## 🚀 실습 환경 준비

### VSCode PowerShell에서 Redis 컨테이너 접속
```powershell
# Redis 컨테이너 상태 확인
docker ps

# Redis 컨테이너가 없다면 실행
docker run -d --name redis-lab -p 6379:6379 -v redis-data:/data redis:7-alpine

# Redis CLI 접속
docker exec -it redis-lab redis-cli

# 연결 확인
ping
# 응답: PONG

# 기존 데이터 정리 (선택사항)
FLUSHDB
```

## 📚 Sorted Set 기본 명령어 실습

### 실습 1: Sorted Set 기본 조작

#### 1-1. Sorted Set 생성 및 멤버 추가
```redis
# 게임 점수 리더보드 생성
ZADD game_leaderboard 2500 "DragonSlayer" 1800 "ShadowNinja" 3200 "FireMage" 2100 "IceWarrior" 2900 "LightPaladin"

# 추가 플레이어 점수 입력
ZADD game_leaderboard 1500 "DarkAssassin" 3500 "StormWizard" 2700 "EarthGuardian" 1900 "WindArcher" 3100 "FlameKnight"

# 총 멤버 수 확인
ZCARD game_leaderboard

# 점수 범위 확인
ZCOUNT game_leaderboard 2000 3000
ZCOUNT game_leaderboard 3000 4000
```

#### 1-2. 정렬된 멤버 조회
```redis
# 점수 오름차순 조회 (최하위부터)
ZRANGE game_leaderboard 0 -1

# 점수와 함께 조회
ZRANGE game_leaderboard 0 -1 WITHSCORES

# 점수 내림차순 조회 (최상위부터)
ZREVRANGE game_leaderboard 0 -1 WITHSCORES

# 상위 3명만 조회
ZREVRANGE game_leaderboard 0 2 WITHSCORES

# 하위 3명만 조회
ZRANGE game_leaderboard 0 2 WITHSCORES
```

#### 1-3. 특정 멤버 정보 조회
```redis
# 특정 플레이어 점수 조회
ZSCORE game_leaderboard "FireMage"
ZSCORE game_leaderboard "ShadowNinja"

# 특정 플레이어 순위 조회 (0부터 시작)
ZRANK game_leaderboard "FireMage"     # 오름차순 순위
ZREVRANK game_leaderboard "FireMage"  # 내림차순 순위 (실제 리더보드 순위)

# 여러 플레이어 순위 비교
ZREVRANK game_leaderboard "StormWizard"
ZREVRANK game_leaderboard "FlameKnight"
ZREVRANK game_leaderboard "LightPaladin"
```

## 🏆 실습 2: 게임 리더보드 시스템 구현

### 2-1. 다양한 게임 모드별 리더보드
```redis
# PvP 모드 리더보드
ZADD pvp_ranking 1250 "DragonSlayer" 980 "ShadowNinja" 1650 "FireMage" 1100 "IceWarrior" 1450 "LightPaladin"
ZADD pvp_ranking 750 "DarkAssassin" 1850 "StormWizard" 1350 "EarthGuardian" 950 "WindArcher" 1550 "FlameKnight"

# PvE 모드 리더보드 (던전 클리어 시간 - 낮을수록 좋음)
ZADD pve_ranking 245 "FireMage" 267 "StormWizard" 289 "FlameKnight" 301 "LightPaladin" 325 "DragonSlayer"
ZADD pve_ranking 334 "EarthGuardian" 356 "IceWarrior" 378 "WindArcher" 401 "ShadowNinja" 423 "DarkAssassin"

# 일일 퀘스트 완료 수 랭킹
ZADD daily_quest_ranking 45 "LightPaladin" 42 "FireMage" 38 "StormWizard" 35 "FlameKnight" 33 "EarthGuardian"
ZADD daily_quest_ranking 31 "DragonSlayer" 28 "IceWarrior" 25 "WindArcher" 22 "ShadowNinja" 19 "DarkAssassin"

# 각 리더보드 상위 5명 확인
ZREVRANGE pvp_ranking 0 4 WITHSCORES
ZRANGE pve_ranking 0 4 WITHSCORES      # PvE는 시간이므로 오름차순
ZREVRANGE daily_quest_ranking 0 4 WITHSCORES
```

### 2-2. 점수 업데이트 및 순위 변동
```redis
# 플레이어 점수 업데이트 (새로운 게임 결과)
ZADD game_leaderboard 2600 "ShadowNinja"    # 1800 → 2600으로 상승
ZADD game_leaderboard 3400 "LightPaladin"   # 2900 → 3400으로 상승
ZADD game_leaderboard 2200 "WindArcher"     # 1900 → 2200으로 상승

# 업데이트된 리더보드 확인
ZREVRANGE game_leaderboard 0 -1 WITHSCORES

# 순위 변동 확인
ZREVRANK game_leaderboard "ShadowNinja"
ZREVRANK game_leaderboard "LightPaladin"
ZREVRANK game_leaderboard "WindArcher"

# 점수 증감 계산 (ZINCRBY 사용)
ZINCRBY game_leaderboard 200 "DarkAssassin"  # 1500 + 200 = 1700
ZINCRBY game_leaderboard -100 "EarthGuardian" # 2700 - 100 = 2600
ZINCRBY game_leaderboard 300 "IceWarrior"    # 2100 + 300 = 2400

# 변경된 순위 확인
ZREVRANGE game_leaderboard 0 -1 WITHSCORES
```

### 2-3. 리그별 플레이어 분류
```redis
# 점수대별 리그 분류
# 마스터 리그 (3000점 이상)
ZRANGEBYSCORE game_leaderboard 3000 +inf WITHSCORES

# 다이아 리그 (2500-2999점)
ZRANGEBYSCORE game_leaderboard 2500 2999 WITHSCORES

# 플래티넘 리그 (2000-2499점)
ZRANGEBYSCORE game_leaderboard 2000 2499 WITHSCORES

# 골드 리그 (1500-1999점)
ZRANGEBYSCORE game_leaderboard 1500 1999 WITHSCORES

# 각 리그별 플레이어 수 확인
ZCOUNT game_leaderboard 3000 +inf
ZCOUNT game_leaderboard 2500 2999
ZCOUNT game_leaderboard 2000 2499
ZCOUNT game_leaderboard 1500 1999
```

## 📈 실습 3: 웹사이트 인기 콘텐츠 랭킹

### 3-1. 블로그 포스트 조회수 랭킹
```redis
# 블로그 포스트 조회수 데이터
ZADD blog_views 1250 "Redis 기초 가이드" 2100 "Docker 컨테이너 관리" 1800 "JavaScript ES6 신기능" 950 "Python 데이터 분석"
ZADD blog_views 2800 "웹 개발 트렌드 2025" 1650 "클라우드 아키텍처" 3200 "AI 개발 입문" 1400 "데이터베이스 최적화"
ZADD blog_views 2350 "React 고급 패턴" 1750 "백엔드 API 설계" 2950 "머신러닝 실습" 1550 "모바일 앱 개발"

# 인기 포스트 Top 10
ZREVRANGE blog_views 0 9 WITHSCORES

# 조회수 1000 이상 포스트
ZRANGEBYSCORE blog_views 1000 +inf WITHSCORES

# 조회수 2000 이상 포스트 수
ZCOUNT blog_views 2000 +inf
```

### 3-2. 상품 평점 랭킹
```redis
# 상품 평점 데이터 (5점 만점)
ZADD product_ratings 4.8 "무선 이어폰 Pro" 4.5 "게이밍 키보드" 4.7 "스마트 워치" 4.2 "노트북 거치대"
ZADD product_ratings 4.9 "USB-C 허브" 4.3 "무선 충전기" 4.6 "블루투스 스피커" 4.4 "웹캠 HD"
ZADD product_ratings 4.1 "마우스 패드" 4.7 "모니터 암" 4.8 "기계식 키보드" 4.5 "헤드셋"

# 평점 순 베스트 상품
ZREVRANGE product_ratings 0 -1 WITHSCORES

# 평점 4.5 이상 상품
ZRANGEBYSCORE product_ratings 4.5 5.0 WITHSCORES

# 평점 4.7 이상 프리미엄 상품
ZRANGEBYSCORE product_ratings 4.7 5.0 WITHSCORES
```

### 3-3. 실시간 검색어 랭킹
```redis
# 검색어 빈도수 데이터
ZADD search_keywords 145 "Redis" 203 "Docker" 187 "JavaScript" 92 "Python" 156 "React"
ZADD search_keywords 234 "AI" 178 "머신러닝" 134 "클라우드" 189 "데이터베이스" 167 "웹개발"
ZADD search_keywords 98 "모바일" 223 "백엔드" 145 "프론트엔드" 112 "DevOps" 176 "API"

# 실시간 검색어 Top 10
ZREVRANGE search_keywords 0 9 WITHSCORES

# 검색 빈도 150 이상 인기 키워드
ZRANGEBYSCORE search_keywords 150 +inf WITHSCORES

# 검색어 빈도 업데이트 (실시간 검색 반영)
ZINCRBY search_keywords 25 "Redis"     # Redis 검색 증가
ZINCRBY search_keywords 18 "Docker"    # Docker 검색 증가
ZINCRBY search_keywords 32 "AI"        # AI 검색 급증

# 업데이트된 랭킹 확인
ZREVRANGE search_keywords 0 9 WITHSCORES
```

## ⏰ 실습 4: 시간 기반 데이터 관리

### 4-1. 최신 뉴스 타임라인
```redis
# 뉴스 발행 시간을 Unix 타임스탬프로 사용 (2025-05-23 기준)
ZADD news_timeline 1716422400 "Redis 7.2 버전 출시" 1716425000 "Docker Desktop 업데이트" 1716427600 "AI 개발 도구 발표"
ZADD news_timeline 1716430200 "클라우드 서비스 장애" 1716432800 "신규 프로그래밍 언어" 1716435400 "보안 취약점 발견"
ZADD news_timeline 1716438000 "오픈소스 프로젝트 출시" 1716440600 "기술 컨퍼런스 발표" 1716443200 "스타트업 투자 소식"

# 최신 뉴스 순서로 조회 (시간 내림차순)
ZREVRANGE news_timeline 0 -1 WITHSCORES

# 최신 5개 뉴스
ZREVRANGE news_timeline 0 4

# 특정 시간 이후 뉴스 조회
ZRANGEBYSCORE news_timeline 1716430000 +inf

# 오래된 뉴스 제거 (일주일 이상 된 뉴스)
ZREMRANGEBYSCORE news_timeline -inf 1716422400
```

### 4-2. 사용자 활동 점수 시스템
```redis
# 사용자별 활동 점수 (로그인, 포스팅, 댓글 등)
ZADD user_activity_score 85 "user:1001" 92 "user:1002" 78 "user:1003" 67 "user:1004" 94 "user:1005"
ZADD user_activity_score 73 "user:1006" 88 "user:1007" 81 "user:1008" 96 "user:1009" 69 "user:1010"

# 활동 점수별 사용자 랭킹
ZREVRANGE user_activity_score 0 -1 WITHSCORES

# 상위 20% 활성 사용자 (상위 2명)
ZREVRANGE user_activity_score 0 1 WITHSCORES

# 점수 80 이상 활성 사용자
ZRANGEBYSCORE user_activity_score 80 100 WITHSCORES

# 활동 점수 업데이트 (새로운 활동 반영)
ZINCRBY user_activity_score 5 "user:1003"   # 댓글 작성 (+5점)
ZINCRBY user_activity_score 10 "user:1004"  # 포스트 작성 (+10점)
ZINCRBY user_activity_score 3 "user:1006"   # 좋아요 (+3점)

# 업데이트된 랭킹 확인
ZREVRANGE user_activity_score 0 -1 WITHSCORES
```

### 4-3. 우선순위 작업 큐
```redis
# 작업 우선순위 큐 (높은 숫자 = 높은 우선순위)
ZADD task_queue 1 "데이터베이스 백업" 5 "보안 패치 적용" 3 "로그 파일 정리" 8 "서버 점검"
ZADD task_queue 2 "문서 업데이트" 7 "성능 모니터링" 4 "사용자 알림 발송" 6 "캐시 정리" 9 "긴급 버그 수정"

# 우선순위 순서로 작업 조회 (높은 우선순위부터)
ZREVRANGE task_queue 0 -1 WITHSCORES

# 가장 우선순위 높은 작업 3개
ZREVRANGE task_queue 0 2

# 우선순위 5 이상 중요 작업
ZRANGEBYSCORE task_queue 5 +inf WITHSCORES

# 작업 완료 처리 (큐에서 제거)
ZREM task_queue "긴급 버그 수정"
ZREM task_queue "서버 점검"

# 남은 작업 확인
ZREVRANGE task_queue 0 -1 WITHSCORES
```

## 🔍 실습 5: 고급 Sorted Set 연산

### 5-1. 범위 기반 데이터 분석
```redis
# 월별 매출 데이터 (점수: 매출액, 멤버: 월)
ZADD monthly_sales 450000 "2025-01" 520000 "2025-02" 680000 "2025-03" 590000 "2025-04" 720000 "2025-05"

# 매출 상위 3개월
ZREVRANGE monthly_sales 0 2 WITHSCORES

# 매출 500만원 이상 달성 월
ZRANGEBYSCORE monthly_sales 500000 +inf WITHSCORES

# 특정 매출 범위 분석 (50만원 ~ 60만원)
ZRANGEBYSCORE monthly_sales 500000 600000 WITHSCORES

# 매출 증가율 계산을 위한 데이터 조회
ZSCORE monthly_sales "2025-04"
ZSCORE monthly_sales "2025-05"
```

### 5-2. 복합 랭킹 시스템
```redis
# 종합 점수 계산 (게임 점수 + PvP 점수 가중합)
# 임시로 종합 점수 생성
ZADD overall_ranking 4750 "StormWizard" 4550 "LightPaladin" 4700 "FireMage" 4200 "FlameKnight" 3950 "EarthGuardian"
ZADD overall_ranking 3750 "DragonSlayer" 3850 "ShadowNinja" 3600 "IceWarrior" 3150 "WindArcher" 2450 "DarkAssassin"

# 종합 랭킹 Top 5
ZREVRANGE overall_ranking 0 4 WITHSCORES

# 점수대별 등급 분류
ZCOUNT overall_ranking 4000 +inf    # S등급
ZCOUNT overall_ranking 3500 3999    # A등급
ZCOUNT overall_ranking 3000 3499    # B등급
ZCOUNT overall_ranking 2000 2999    # C등급
```

### 5-3. 데이터 정리 및 관리
```redis
# 특정 점수 이하 데이터 제거
ZREMRANGEBYSCORE game_leaderboard -inf 1000

# 하위 N개 데이터 제거 (최하위 2명 제거)
ZREMRANGEBYRANK game_leaderboard 0 1

# 상위 N개만 유지 (Top 10만 유지)
ZREMRANGEBYRANK overall_ranking 10 -1

# 데이터 백업 (다른 키로 복사)
# 전체 데이터를 새로운 Sorted Set에 복사
ZUNIONSTORE backup_leaderboard 1 game_leaderboard

# 백업 데이터 확인
ZREVRANGE backup_leaderboard 0 -1 WITHSCORES
```

## 📊 실습 6: Sorted Set 집합 연산

### 6-1. 여러 리더보드 통합
```redis
# 두 게임 모드의 점수를 합산하여 통합 랭킹 생성
ZUNIONSTORE combined_ranking 2 game_leaderboard pvp_ranking

# 통합 랭킹 확인
ZREVRANGE combined_ranking 0 -1 WITHSCORES

# 가중 평균으로 통합 (게임 점수 70%, PvP 점수 30%)
ZUNIONSTORE weighted_ranking 2 game_leaderboard pvp_ranking WEIGHTS 0.7 0.3

# 가중 통합 랭킹 확인
ZREVRANGE weighted_ranking 0 -1 WITHSCORES
```

### 6-2. 공통 멤버 분석
```redis
# 두 리더보드에 모두 존재하는 플레이어 (교집합)
ZINTERSTORE active_players 2 game_leaderboard pvp_ranking

# 활성 플레이어 확인
ZREVRANGE active_players 0 -1 WITHSCORES

# 교집합에서 점수 합산 방식
ZINTERSTORE sum_intersection 2 game_leaderboard pvp_ranking AGGREGATE SUM
ZINTERSTORE max_intersection 2 game_leaderboard pvp_ranking AGGREGATE MAX
ZINTERSTORE min_intersection 2 game_leaderboard pvp_ranking AGGREGATE MIN

# 각각의 결과 비교
ZREVRANGE sum_intersection 0 -1 WITHSCORES
ZREVRANGE max_intersection 0 -1 WITHSCORES
```

## 🔧 Sorted Set 성능 최적화

### 성능 측정 및 모니터링
```redis
# 메모리 사용량 확인
MEMORY USAGE game_leaderboard
MEMORY USAGE blog_views
MEMORY USAGE monthly_sales

# 대용량 Sorted Set 처리 (SCAN 사용)
ZSCAN game_leaderboard 0 COUNT 5

# Sorted Set 통계 정보
ZCARD game_leaderboard
ZCOUNT game_leaderboard -inf +inf
```

### 데이터 관리 최적화
```redis
# 정기적인 데이터 정리 예제
# 오래된 뉴스 삭제 (일주일 이상)
ZREMRANGEBYSCORE news_timeline -inf 1716000000

# 하위 성과 데이터 정리 (하위 10% 제거)
ZCARD user_activity_score  # 전체 개수 확인
ZREMRANGEBYRANK user_activity_score 0 0  # 최하위 1명 제거

# 메모리 효율적인 점수 업데이트
ZINCRBY game_leaderboard 100 "NewPlayer"  # 없으면 생성, 있으면 증가
```

## 🎯 종합 실습 과제

### 과제 1: 전자상거래 랭킹 시스템
다음 요구사항을 만족하는 시스템을 구현하세요:
1. 상품별 판매량, 평점, 리뷰 수를 기반으로 한 종합 랭킹
2. 카테고리별 베스트셀러 랭킹 (전자제품, 의류, 도서 등)
3. 시간대별 실시간 판매 랭킹
4. 사용자 구매 이력 기반 개인화 추천 점수

### 과제 2: 학습 관리 시스템
온라인 교육 플랫폼의 랭킹 시스템 구현:
1. 학생별 학습 진도율 랭킹
2. 과목별 성적 랭킹
3. 학습 시간 기반 활동 점수
4. 퀴즈/시험 점수 통합 랭킹

### 과제 3: 소셜 미디어 콘텐츠 랭킹
소셜 플랫폼의 콘텐츠 순위 시스템:
1. 좋아요, 댓글, 공유 수를 종합한 인기도 점수
2. 시간 가중치를 적용한 트렌딩 콘텐츠 랭킹
3. 사용자별 팔로워 영향력 점수
4. 해시태그별 인기 콘텐츠 순위

## 💡 실무 응용 팁

### Sorted Set 사용 시 주의사항
1. **메모리 사용량**: 큰 Sorted Set은 상당한 메모리 소모
2. **점수 정밀도**: 부동소수점 연산 시 정밀도 고려
3. **성능 특성**: 범위 조회는 빠르지만 전체 스캔은 비용이 큼
4. **동시성 처리**: 고빈도 업데이트 시 경합 조건 고려

### 성능 최적화 전략
```redis
# 배치 처리로 다중 업데이트
MULTI
ZADD game_leaderboard 100 "Player1"
ZADD game_leaderboard 200 "Player2"
ZADD game_leaderboard 150 "Player3"
EXEC

# 불필요한 데이터 주기적 정리
# 예: 상위 100명만 유지
ZREMRANGEBYRANK game_leaderboard 100 -1

# 메모리 효율적인 점수 저장
# 정수 점수 사용 (부동소수점 대신)
ZADD integer_scores 1000 "user1" 2000 "user2"
```

## ✅ 학습 완료 체크리스트

### 기본 개념 이해
- [ ] Sorted Set 데이터 타입 특성 이해
- [ ] 점수(Score)와 순위(Rank) 개념 이해
- [ ] 기본 명령어 숙지 (ZADD, ZRANGE, ZREVRANGE, ZSCORE 등)

### 정렬 및 조회 기능
- [ ] 점수 기반 정렬 조회 (오름차순/내림차순)
- [ ] 범위 조회 (ZRANGEBYSCORE, ZREVRANGEBYSCORE)
- [ ] 순위 조회 (ZRANK, ZREVRANK)
- [ ] 개수 조회 (ZCARD, ZCOUNT)

### 실무 패턴 구현
- [ ] 리더보드 시스템 구현
- [ ] 랭킹 시스템 구현
- [ ] 시간 기반 데이터 관리
- [ ] 우선순위 큐 구현

### 고급 기능 활용
- [ ] 집합 연산 (ZUNIONSTORE, ZINTERSTORE)
- [ ] 점수 증감 (ZINCRBY)
- [ ] 범위 삭제 (ZREMRANGEBYSCORE, ZREMRANGEBYRANK)
- [ ] 성능 최적화 방법 이해

## 🔗 다음 단계
다음은 **초급 9번 - 기본 데이터 CRUD 실습**입니다. 지금까지 학습한 모든 데이터 타입을 종합하여 실제 애플리케이션과 같은 복합적인 데이터 모델링을 구현해보겠습니다.

---
*본 교안은 Docker Desktop과 VSCode PowerShell 환경을 기준으로 작성되