# Redis 초급 9번 - 기본 데이터 CRUD 실습 교안

## 📋 학습 목표
- Redis의 모든 기본 데이터 타입을 활용한 종합 실습
- 간단한 블로그 시스템 데이터 모델링 구현
- CRUD(Create, Read, Update, Delete) 패턴 완전 숙지
- 실무에서 사용할 수 있는 데이터 구조 설계 능력 배양
- 각 데이터 타입의 특성을 활용한 최적화된 데이터 저장 방법 학습

## 🔧 사전 준비사항

### 환경 확인
- Docker Desktop이 실행 중이어야 함
- VS Code가 설치되어 있어야 함
- PowerShell Terminal 사용 가능해야 함

### Redis 컨테이너 준비
```powershell
# VS Code에서 PowerShell Terminal 열기
# Ctrl + Shift + ` 또는 Terminal > New Terminal

# 기존 Redis 컨테이너 확인
docker ps -a

# Redis 컨테이너가 없다면 생성
docker run -d --name redis-blog-lab -p 6379:6379 -v redis-blog-data:/data redis:7-alpine

# 컨테이너 실행 확인
docker ps

# Redis CLI 접속 테스트
docker exec -it redis-blog-lab redis-cli ping
```

## 🏗️ 블로그 시스템 데이터 모델 설계

### 시스템 요구사항
우리가 구현할 간단한 블로그 시스템의 기능:
- **사용자 관리**: 회원가입, 프로필 관리
- **게시글 관리**: 글 작성, 수정, 삭제, 조회
- **댓글 시스템**: 댓글 작성, 조회
- **태그 시스템**: 글에 태그 붙이기, 태그별 검색
- **좋아요 시스템**: 글 좋아요/싫어요
- **랭킹 시스템**: 인기 글 순위
- **최근 활동**: 최신 글 목록

### 데이터 구조 설계

| 기능 | Redis 데이터 타입 | 키 패턴 | 설명 |
|------|------------------|---------|------|
| 사용자 프로필 | Hash | `user:{user_id}` | 사용자 기본 정보 |
| 게시글 내용 | Hash | `post:{post_id}` | 게시글 상세 정보 |
| 댓글 목록 | List | `comments:{post_id}` | 특정 글의 댓글들 |
| 사용자 태그 | Set | `user_tags:{user_id}` | 사용자가 사용한 태그들 |
| 태그별 글 목록 | Set | `tag_posts:{tag_name}` | 특정 태그의 글들 |
| 글 좋아요 수 | String | `likes:{post_id}` | 좋아요 카운터 |
| 인기 글 랭킹 | Sorted Set | `popular_posts` | 좋아요 수 기준 랭킹 |
| 최신 글 목록 | List | `recent_posts` | 최근 작성된 글들 |

## 🚀 실습 1: 사용자 관리 시스템

### 1-1. Redis CLI 접속
```powershell
# VS Code PowerShell Terminal에서 실행
docker exec -it redis-blog-lab redis-cli
```

### 1-2. 사용자 데이터 생성 (Hash 활용)
```redis
# 사용자 1: 김철수
HSET user:1001 name "김철수" email "kimcs@example.com" age 28 location "서울" join_date "2024-01-15" posts_count 0

# 사용자 2: 이영희
HSET user:1002 name "이영희" email "leeyh@example.com" age 25 location "부산" join_date "2024-02-20" posts_count 0

# 사용자 3: 박민수
HSET user:1003 name "박민수" email "parkms@example.com" age 32 location "대구" join_date "2024-01-30" posts_count 0

# 사용자 4: 최지원
HSET user:1004 name "최지원" email "choijw@example.com" age 29 location "인천" join_date "2024-03-01" posts_count 0

# 사용자 5: 정동혁
HSET user:1005 name "정동혁" email "jeongdh@example.com" age 26 location "광주" join_date "2024-02-10" posts_count 0
```

### 1-3. 사용자 데이터 조회 (Read)
```redis
# 특정 사용자 전체 정보 조회
HGETALL user:1001

# 특정 필드만 조회
HGET user:1001 name
HGET user:1001 email

# 여러 필드 한번에 조회
HMGET user:1001 name email location

# 모든 사용자 키 확인
KEYS user:*
```

### 1-4. 사용자 데이터 수정 (Update)
```redis
# 사용자 나이 수정
HSET user:1001 age 29

# 여러 필드 동시 수정
HMSET user:1001 location "경기도" posts_count 1

# 숫자 필드 증가
HINCRBY user:1001 posts_count 1

# 수정 결과 확인
HGETALL user:1001
```

## 🚀 실습 2: 게시글 관리 시스템

### 2-1. 게시글 데이터 생성 (Hash + List 활용)
```redis
# 게시글 1: 김철수의 Redis 학습 후기
HSET post:2001 title "Redis 학습 후기" content "Redis를 배우면서 느낀 점들을 정리해보았습니다. 특히 데이터 구조가 다양해서 좋네요!" author_id 1001 author_name "김철수" created_at "2024-05-20 14:30:00" likes 0 views 0

# 게시글 2: 이영희의 Docker 활용법
HSET post:2002 title "Docker로 개발환경 구성하기" content "Docker Desktop을 활용해서 Redis 환경을 구성하는 방법을 소개합니다." author_id 1002 author_name "이영희" created_at "2024-05-21 09:15:00" likes 0 views 0

# 게시글 3: 박민수의 프로그래밍 팁
HSET post:2003 title "효율적인 프로그래밍 습관" content "20년간 개발하면서 터득한 효율적인 코딩 습관들을 공유합니다." author_id 1003 author_name "박민수" created_at "2024-05-21 16:45:00" likes 0 views 0

# 게시글 4: 최지원의 알고리즘 설명
HSET post:2004 title "정렬 알고리즘 비교 분석" content "다양한 정렬 알고리즘의 시간복잡도와 공간복잡도를 비교 분석해보았습니다." author_id 1004 author_name "최지원" created_at "2024-05-22 11:20:00" likes 0 views 0

# 게시글 5: 정동혁의 데이터베이스 이야기
HSET post:2005 title "NoSQL vs RDBMS 선택 기준" content "프로젝트 특성에 따른 데이터베이스 선택 기준에 대해 정리했습니다." author_id 1005 author_name "정동혁" created_at "2024-05-22 18:30:00" likes 0 views 0
```

### 2-2. 최신 글 목록 관리 (List 활용)
```redis
# 최신 글 목록에 추가 (최신순으로 정렬)
LPUSH recent_posts 2001 2002 2003 2004 2005

# 최신 글 5개 조회
LRANGE recent_posts 0 4

# 최신 글 전체 조회
LRANGE recent_posts 0 -1

# 특정 인덱스의 글 ID 조회
LINDEX recent_posts 0
```

### 2-3. 게시글 조회 및 조회수 증가
```redis
# 게시글 상세 조회
HGETALL post:2001

# 조회수 증가
HINCRBY post:2001 views 1
HINCRBY post:2002 views 3
HINCRBY post:2003 views 7
HINCRBY post:2004 views 2
HINCRBY post:2005 views 5

# 조회수 확인
HGET post:2001 views
HMGET post:2001 title author_name views
```

## 🚀 실습 3: 댓글 시스템

### 3-1. 댓글 데이터 생성 (List 활용)
```redis
# 게시글 2001에 댓글 추가
RPUSH comments:2001 '{"comment_id":3001,"author":"이영희","content":"정말 유익한 글이네요! 저도 Redis 공부 중인데 도움이 많이 됐습니다.","created_at":"2024-05-20 15:30:00"}'

RPUSH comments:2001 '{"comment_id":3002,"author":"박민수","content":"실습 예제가 아주 좋습니다. 따라하기 쉽게 설명해주셔서 감사해요.","created_at":"2024-05-20 16:15:00"}'

RPUSH comments:2001 '{"comment_id":3003,"author":"최지원","content":"Hash 구조 활용법이 인상적이네요. 저도 프로젝트에 적용해봐야겠어요.","created_at":"2024-05-20 17:00:00"}'

# 게시글 2002에 댓글 추가
RPUSH comments:2002 '{"comment_id":3004,"author":"김철수","content":"Docker 설명이 정말 자세하네요. 초보자도 쉽게 따라할 수 있겠어요.","created_at":"2024-05-21 10:30:00"}'

RPUSH comments:2002 '{"comment_id":3005,"author":"정동혁","content":"저도 Docker로 개발환경 구성하고 있는데, 많은 도움이 됐습니다!","created_at":"2024-05-21 14:20:00"}'

# 게시글 2003에 댓글 추가
RPUSH comments:2003 '{"comment_id":3006,"author":"이영희","content":"20년 경력의 노하우가 느껴집니다. 특히 코드 리뷰 부분이 인상적이에요.","created_at":"2024-05-21 18:30:00"}'
```

### 3-2. 댓글 조회
```redis
# 특정 게시글의 모든 댓글 조회
LRANGE comments:2001 0 -1

# 특정 게시글의 댓글 개수 확인
LLEN comments:2001
LLEN comments:2002
LLEN comments:2003

# 최신 댓글 2개만 조회
LRANGE comments:2001 -2 -1

# 가장 오래된 댓글 1개 조회
LRANGE comments:2001 0 0
```

## 🚀 실습 4: 태그 시스템

### 4-1. 태그 데이터 생성 (Set 활용)
```redis
# 각 게시글에 태그 추가
# 게시글 2001: Redis 학습 후기
SADD tag_posts:Redis 2001
SADD tag_posts:학습 2001
SADD tag_posts:후기 2001
SADD tag_posts:데이터베이스 2001

# 게시글 2002: Docker 활용법
SADD tag_posts:Docker 2002
SADD tag_posts:개발환경 2002
SADD tag_posts:DevOps 2002
SADD tag_posts:컨테이너 2002

# 게시글 2003: 프로그래밍 팁
SADD tag_posts:프로그래밍 2003
SADD tag_posts:개발 2003
SADD tag_posts:팁 2003
SADD tag_posts:경험 2003

# 게시글 2004: 알고리즘 설명
SADD tag_posts:알고리즘 2004
SADD tag_posts:정렬 2004
SADD tag_posts:자료구조 2004
SADD tag_posts:분석 2004

# 게시글 2005: 데이터베이스 비교
SADD tag_posts:데이터베이스 2005
SADD tag_posts:NoSQL 2005
SADD tag_posts:RDBMS 2005
SADD tag_posts:비교 2005

# 사용자별 태그 관리
SADD user_tags:1001 Redis 학습 후기 데이터베이스
SADD user_tags:1002 Docker 개발환경 DevOps 컨테이너
SADD user_tags:1003 프로그래밍 개발 팁 경험
SADD user_tags:1004 알고리즘 정렬 자료구조 분석
SADD user_tags:1005 데이터베이스 NoSQL RDBMS 비교
```

### 4-2. 태그 검색 및 분석
```redis
# 특정 태그로 글 검색
SMEMBERS tag_posts:데이터베이스
SMEMBERS tag_posts:Redis
SMEMBERS tag_posts:개발

# 태그별 글 개수 확인
SCARD tag_posts:데이터베이스
SCARD tag_posts:프로그래밍
SCARD tag_posts:Docker

# 사용자가 사용한 태그 확인
SMEMBERS user_tags:1001
SMEMBERS user_tags:1002

# 두 태그의 교집합 (AND 검색)
SINTER tag_posts:데이터베이스 tag_posts:Redis

# 두 태그의 합집합 (OR 검색)
SUNION tag_posts:프로그래밍 tag_posts:개발

# 모든 태그 확인
KEYS tag_posts:*
```

## 🚀 실습 5: 좋아요 시스템 및 랭킹

### 5-1. 좋아요 수 설정 (String + Sorted Set 활용)
```redis
# 각 게시글의 좋아요 수 설정
SET likes:2001 15
SET likes:2002 23
SET likes:2003 31
SET likes:2004 8
SET likes:2005 19

# 좋아요 수 기반 인기 글 랭킹 생성
ZADD popular_posts 15 2001 23 2002 31 2003 8 2004 19 2005

# 좋아요 수 증가 시뮬레이션
INCR likes:2001
ZINCRBY popular_posts 1 2001

INCR likes:2002
INCR likes:2002
ZINCRBY popular_posts 2 2002

INCR likes:2003
ZINCRBY popular_posts 1 2003
```

### 5-2. 랭킹 조회
```redis
# 인기 글 TOP 5 (높은 순)
ZREVRANGE popular_posts 0 4 WITHSCORES

# 인기 글 전체 랭킹
ZREVRANGE popular_posts 0 -1 WITHSCORES

# 특정 글의 랭킹 확인
ZREVRANK popular_posts 2003
ZREVRANK popular_posts 2001

# 특정 점수 범위의 글 조회 (20점 이상)
ZRANGEBYSCORE popular_posts 20 +inf WITHSCORES

# 상위 3위까지의 글 조회
ZREVRANGE popular_posts 0 2
```

## 🚀 실습 6: 종합 데이터 조회 및 분석

### 6-1. 블로그 대시보드 정보 조회
```redis
# 전체 통계 정보
EVAL "
local users = #redis.call('KEYS', 'user:*')
local posts = #redis.call('KEYS', 'post:*') 
local tags = #redis.call('KEYS', 'tag_posts:*')
return {users, posts, tags}
" 0

# 각 게시글의 상세 정보와 통계
HGETALL post:2001
HGET likes:2001
LLEN comments:2001

HGETALL post:2002
HGET likes:2002
LLEN comments:2002

HGETALL post:2003
HGET likes:2003
LLEN comments:2003
```

### 6-2. 사용자 활동 분석
```redis
# 각 사용자의 프로필과 활동 정보
HGETALL user:1001
SMEMBERS user_tags:1001

HGETALL user:1002
SMEMBERS user_tags:1002

HGETALL user:1003
SMEMBERS user_tags:1003
```

## 🚀 실습 7: 데이터 수정 및 삭제 (Update & Delete)

### 7-1. 게시글 수정
```redis
# 게시글 제목 수정
HSET post:2001 title "Redis 완전 정복 학습 후기"

# 게시글 내용 추가
HSET post:2001 content "Redis를 배우면서 느낀 점들을 정리해보았습니다. 특히 데이터 구조가 다양해서 좋네요! 추가로 실습을 통해 더 깊이 이해할 수 있었습니다."

# 수정 시간 추가
HSET post:2001 updated_at "2024-05-23 10:30:00"

# 수정 결과 확인
HGETALL post:2001
```

### 7-2. 댓글 삭제
```redis
# 특정 댓글 삭제 (예: 첫 번째 댓글 삭제)
LRANGE comments:2001 0 -1
LPOP comments:2001

# 삭제 후 댓글 목록 확인
LRANGE comments:2001 0 -1
LLEN comments:2001
```

### 7-3. 태그 관리
```redis
# 사용자 태그에서 특정 태그 제거
SREM user_tags:1001 후기

# 태그별 글 목록에서 글 제거
SREM tag_posts:후기 2001

# 새로운 태그 추가
SADD user_tags:1001 완전정복
SADD tag_posts:완전정복 2001

# 결과 확인
SMEMBERS user_tags:1001
SMEMBERS tag_posts:완전정복
```

## 🚀 실습 8: 고급 쿼리 및 데이터 분석

### 8-1. 복합 조건 검색
```redis
# 특정 작성자의 모든 글 찾기 (키 패턴 매칭)
KEYS post:*
# 수동으로 author_id가 1001인 글 찾기
HGET post:2001 author_id
HGET post:2002 author_id
HGET post:2003 author_id
HGET post:2004 author_id
HGET post:2005 author_id

# 좋아요 수가 20 이상인 인기 글
ZRANGEBYSCORE popular_posts 20 +inf WITHSCORES

# 댓글이 2개 이상인 글 찾기
EVAL "
local posts = redis.call('KEYS', 'comments:*')
local result = {}
for i=1,#posts do
    local count = redis.call('LLEN', posts[i])
    if count >= 2 then
        table.insert(result, posts[i])
        table.insert(result, count)
    end
end
return result
" 0
```

### 8-2. 데이터 집계 및 통계
```redis
# 전체 좋아요 수 합계 계산
EVAL "
local total = 0
local keys = redis.call('KEYS', 'likes:*')
for i=1,#keys do
    local likes = redis.call('GET', keys[i])
    total = total + tonumber(likes)
end
return total
" 0

# 가장 활발한 태그 찾기
EVAL "
local tags = redis.call('KEYS', 'tag_posts:*')
local result = {}
for i=1,#tags do
    local count = redis.call('SCARD', tags[i])
    local tagName = string.gsub(tags[i], 'tag_posts:', '')
    table.insert(result, tagName)
    table.insert(result, count)
end
return result
" 0
```

## 🚀 실습 9: 실시간 업데이트 시뮬레이션

### 9-1. 새 글 작성 프로세스
```redis
# 새 게시글 작성 (모든 관련 데이터 업데이트)
# 1. 게시글 생성
HSET post:2006 title "Spring Boot와 Redis 연동하기" content "Spring Boot 애플리케이션에서 Redis를 캐시로 활용하는 방법을 소개합니다." author_id 1001 author_name "김철수" created_at "2024-05-23 15:00:00" likes 0 views 0

# 2. 최신 글 목록에 추가
LPUSH recent_posts 2006

# 3. 작성자 글 개수 증가
HINCRBY user:1001 posts_count 1

# 4. 태그 추가
SADD tag_posts:SpringBoot 2006
SADD tag_posts:Redis 2006
SADD tag_posts:캐시 2006
SADD tag_posts:연동 2006
SADD user_tags:1001 SpringBoot 캐시 연동

# 5. 랭킹에 추가 (초기 좋아요 0)
ZADD popular_posts 0 2006
SET likes:2006 0

# 결과 확인
LRANGE recent_posts 0 4
HGETALL user:1001
SMEMBERS tag_posts:Redis
```

### 9-2. 실시간 좋아요 증가 시뮬레이션
```redis
# 새 글에 좋아요 증가
INCR likes:2006
ZINCRBY popular_posts 1 2006

INCR likes:2006
ZINCRBY popular_posts 1 2006

INCR likes:2006
ZINCRBY popular_posts 1 2006

# 현재 상태 확인
GET likes:2006
ZREVRANGE popular_posts 0 -1 WITHSCORES
```

## 📊 실습 10: 데이터 검증 및 최종 확인

### 10-1. 전체 데이터 구조 확인
```powershell
# PowerShell에서 새 창을 열어서 확인
# 또는 Redis CLI에서 직접 실행
```

```redis
# 모든 키 패턴별 확인
KEYS user:*
KEYS post:*
KEYS comments:*
KEYS tag_posts:*
KEYS user_tags:*
KEYS likes:*
KEYS popular_posts
KEYS recent_posts

# 데이터 개수 확인
EVAL "
local patterns = {'user:*', 'post:*', 'comments:*', 'tag_posts:*', 'user_tags:*', 'likes:*'}
local result = {}
for i=1,#patterns do
    local keys = redis.call('KEYS', patterns[i])
    table.insert(result, patterns[i])
    table.insert(result, #keys)
end
return result
" 0
```

### 10-2. 최종 블로그 시스템 상태 보고서
```redis
# 사용자 통계
EVAL "
local userCount = #redis.call('KEYS', 'user:*')
local postCount = #redis.call('KEYS', 'post:*')
local tagCount = #redis.call('KEYS', 'tag_posts:*')
return {
    'Users: ' .. userCount,
    'Posts: ' .. postCount, 
    'Tags: ' .. tagCount
}
" 0

# 인기 글 TOP 3
ZREVRANGE popular_posts 0 2 WITHSCORES

# 최신 글 3개
LRANGE recent_posts 0 2

# 가장 인기있는 태그들
SMEMBERS tag_posts:Redis
SMEMBERS tag_posts:데이터베이스
SMEMBERS tag_posts:프로그래밍
```

## 🎯 심화 실습 과제

### 과제 1: 검색 기능 구현
다음 조건으로 글을 검색하는 쿼리를 작성하세요:
1. 특정 작성자의 글만 조회
2. 좋아요 수 15개 이상인 글만 조회
3. 특정 태그가 포함된 글만 조회
4. 댓글이 2개 이상인 글만 조회

### 과제 2: 데이터 마이그레이션
1. 기존 사용자 데이터에 새 필드 추가 (예: 프로필 이미지 URL)
2. 모든 게시글에 조회수 랭킹 추가
3. 사용자별 활동 점수 시스템 구현

### 과제 3: 성능 최적화
1. 메모리 사용량 확인: `INFO memory`
2. 키 만료 시간 설정으로 임시 데이터 관리
3. 파이프라인을 활용한 배치 처리 구현

## 💡 실무 활용 팁

### 1. 키 네이밍 컨벤션
```redis
# 일관성 있는 키 네이밍
user:{user_id}:{field}     # user:1001:profile, user:1001:settings
post:{post_id}:{field}     # post:2001:meta, post:2001:stats
cache:{type}:{id}:{ttl}    # cache:user:1001:300
```

### 2. 메모리 효율성
```redis
# 작은 해시 사용 (ziplist 최적화)
# 필드 수가 적을 때는 Hash가 효율적

# 큰 세트는 분할하여 관리
# 예: tag_posts:Redis:2024:05 (월별 분할)
```

### 3. 데이터 일관성
```redis
# 트랜잭션으로 관련 데이터 동시 업데이트
MULTI
HINCRBY user:1001 posts_count 1
LPUSH recent_posts 2007
ZADD popular_posts 0 2007
EXEC
```

## ✅ 학습 완료 체크리스트

### 기본 CRUD 작업
- [ ] 사용자 데이터 생성/조회/수정/삭제 완료
- [ ] 게시글 데이터 생성/조회/수정/삭제 완료
- [ ] 댓글 시스템 구현 완료
- [ ] 태그 시스템 구현 완료
- [ ] 좋아요 및 랭킹 시스템 구현 완료

### 데이터 타입 활용
- [ ] String: 카운터, 캐시 데이터 관리
- [ ] Hash: 구조화된 객체 데이터 저장
- [ ] List: 순서가 있는 데이터, 큐/스택 구현
- [ ] Set: 고유한 태그, 중복 제거 기능
- [ ] Sorted Set: 랭킹, 점수 기반 정렬

### 고급 기능
- [ ] 복합 쿼리 작성 능력
- [ ] Lua 스크립트를 활용한 원자적 연산
- [ ] 트랜잭션 처리 이해
- [ ] 성능 최적화 기법 적용

## 🔗 다음 단계

### 다음 학습 주제
초급 과정을 완료하셨다면, 이제 **중급 11번 - Bitmap 데이터 타입 실습**으로 진행하시기 바랍니다.

### 추가 학습 자료
- Redis 공식 문서: https://redis.io/docs/
- Redis 명령어 참조: https://redis.io/commands/
- Redis 데이터 타입 가이드: https://redis.io/docs/data-types/

---
*본 교안은 Docker Desktop과 VSCode PowerShell 환경을 기준으로 작성되어 있습니다.*
