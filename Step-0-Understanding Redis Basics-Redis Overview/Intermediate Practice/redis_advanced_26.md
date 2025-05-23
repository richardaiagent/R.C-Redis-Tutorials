# Redis 고급 실습 26 - 메모리 최적화 고급

## 🎯 학습 목표
- Redis 메모리 최적화 기법 이해
- 압축 옵션 및 만료 정책 설정
- 메모리 정책별 성능 비교 테스트

## 📋 사전 준비
```bash
# Redis 컨테이너 실행 (메모리 제한 설정)
docker run -d --name redis-memory-test -p 6379:6379 -m 512m redis:7-alpine

# Redis CLI 접속
docker exec -it redis-memory-test redis-cli
```

## 🔧 1. 현재 메모리 상태 확인

### 메모리 정보 조회
```bash
# 기본 메모리 정보
INFO memory

# 메모리 사용량 요약
MEMORY USAGE

# 메모리 통계
MEMORY STATS
```

### 테스트용 초기 데이터 생성
```bash
# 대용량 문자열 데이터 생성
SET large_string_1 "$(python3 -c "print('x' * 10000)")"
SET large_string_2 "$(python3 -c "print('y' * 10000)")"
SET large_string_3 "$(python3 -c "print('z' * 10000)")"

# Hash 데이터 생성
HSET user:1000 name "김철수김철수김철수김철수김철수" email "chulsoo@example.com" age 30
HSET user:1001 name "이영희이영희이영희이영희이영희" email "younghee@example.com" age 25
HSET user:1002 name "박민수박민수박민수박민수박민수" email "minsu@example.com" age 35

# List 데이터 생성
LPUSH message_queue "긴 메시지 내용입니다. 실제 서비스에서는 이런 형태의 메시지가 큐에 저장됩니다."
LPUSH message_queue "또 다른 긴 메시지 내용입니다. JSON 형태의 복잡한 데이터일 수 있습니다."
LPUSH message_queue "세 번째 메시지입니다. 이것도 상당히 긴 내용을 담고 있습니다."

# Set 데이터 생성
SADD tags:product:1 "전자제품" "스마트폰" "최신기술" "고성능" "프리미엄"
SADD tags:product:2 "가전제품" "에어컨" "절전형" "저소음" "고효율"
```

## 🔧 2. 메모리 최적화 설정

### 압축 설정 (Hash, List, Set)
```bash
# Hash 압축 설정
CONFIG SET hash-max-ziplist-entries 1000
CONFIG SET hash-max-ziplist-value 1024

# List 압축 설정
CONFIG SET list-max-ziplist-size -2
CONFIG SET list-compress-depth 1

# Set 압축 설정
CONFIG SET set-max-intset-entries 1000

# 현재 설정 확인
CONFIG GET *ziplist*
CONFIG GET *intset*
```

### 메모리 정책 설정
```bash
# 최대 메모리 설정 (256MB)
CONFIG SET maxmemory 256mb

# 메모리 정책 설정 - LRU 방식
CONFIG SET maxmemory-policy allkeys-lru

# 현재 메모리 정책 확인
CONFIG GET maxmemory*
```

## 🔧 3. 메모리 정책 비교 테스트

### 3.1 allkeys-lru 정책 테스트
```bash
# 현재 정책 확인
CONFIG GET maxmemory-policy

# 메모리 사용량 확인
INFO memory | grep used_memory_human

# 대량 데이터 생성하여 메모리 한계 테스트
for i in {1..1000}; do
  SET test_key_$i "테스트 데이터 $i - 상당히 긴 문자열 데이터입니다."
done

# 메모리 사용량 재확인
INFO memory | grep used_memory_human

# 일부 키가 삭제되었는지 확인
EXISTS test_key_1
EXISTS test_key_500
EXISTS test_key_1000
```

### 3.2 volatile-lru 정책 테스트
```bash
# 메모리 정책 변경
CONFIG SET maxmemory-policy volatile-lru

# 기존 데이터 정리
FLUSHALL

# TTL이 있는 데이터와 없는 데이터 생성
SET permanent_key_1 "영구 데이터 1"
SET permanent_key_2 "영구 데이터 2"
SET temporary_key_1 "임시 데이터 1" EX 3600
SET temporary_key_2 "임시 데이터 2" EX 3600

# 대량 데이터 생성
for i in {1..500}; do
  SET perm_$i "영구 데이터 $i"
  SET temp_$i "임시 데이터 $i" EX 3600
done

# 메모리 사용량 확인
INFO memory | grep used_memory_human

# 어떤 키들이 삭제되었는지 확인
EXISTS permanent_key_1
EXISTS temporary_key_1
EXISTS perm_100
EXISTS temp_100
```

### 3.3 allkeys-random 정책 테스트
```bash
# 메모리 정책 변경
CONFIG SET maxmemory-policy allkeys-random

# 기존 데이터 정리
FLUSHALL

# 동일한 크기의 데이터 생성
for i in {1..800}; do
  SET random_test_$i "동일한 크기의 테스트 데이터 $i"
done

# 메모리 사용량 확인
INFO memory | grep used_memory_human

# 랜덤하게 삭제된 키 확인
EXISTS random_test_1
EXISTS random_test_400
EXISTS random_test_800
```

## 🔧 4. 데이터 구조별 메모리 사용량 분석

### 4.1 String vs Hash 메모리 비교
```bash
# 데이터 정리
FLUSHALL

# String으로 사용자 데이터 저장
SET user:1:name "김철수"
SET user:1:email "chulsoo@example.com"
SET user:1:age "30"
SET user:2:name "이영희"
SET user:2:email "younghee@example.com"
SET user:2:age "25"

# 메모리 사용량 확인
INFO memory | grep used_memory_human

# Hash로 동일한 데이터 저장
DEL user:1:name user:1:email user:1:age user:2:name user:2:email user:2:age
HSET user:1 name "김철수" email "chulsoo@example.com" age 30
HSET user:2 name "이영희" email "younghee@example.com" age 25

# 메모리 사용량 재확인
INFO memory | grep used_memory_human

# 개별 키의 메모리 사용량 확인
MEMORY USAGE user:1
MEMORY USAGE user:2
```

### 4.2 List vs Set 메모리 비교
```bash
# List 데이터 생성
LPUSH test_list "데이터1" "데이터2" "데이터3" "데이터4" "데이터5"

# Set 데이터 생성
SADD test_set "데이터1" "데이터2" "데이터3" "데이터4" "데이터5"

# 메모리 사용량 비교
MEMORY USAGE test_list
MEMORY USAGE test_set

# 중복 데이터로 테스트
LPUSH test_list_dup "중복" "중복" "중복" "중복" "중복"
SADD test_set_dup "중복" "중복" "중복" "중복" "중복"

MEMORY USAGE test_list_dup
MEMORY USAGE test_set_dup
```

## 🔧 5. 압축 효과 확인

### 5.1 Hash 압축 효과
```bash
# 압축 임계값 변경
CONFIG SET hash-max-ziplist-entries 100
CONFIG SET hash-max-ziplist-value 64

# 작은 Hash 생성 (압축 적용)
HSET small_hash field1 "값1" field2 "값2" field3 "값3"

# 큰 Hash 생성 (압축 미적용)
HSET large_hash field1 "$(python3 -c "print('x' * 100)")"

# 메모리 사용량 비교
MEMORY USAGE small_hash
MEMORY USAGE large_hash

# 내부 인코딩 확인
OBJECT ENCODING small_hash
OBJECT ENCODING large_hash
```

### 5.2 List 압축 효과
```bash
# List 압축 설정
CONFIG SET list-max-ziplist-size -1

# 작은 List 생성
LPUSH small_list "item1" "item2" "item3"

# 큰 List 생성
LPUSH large_list "$(python3 -c "print('x' * 1000)")"

# 메모리 사용량 및 인코딩 확인
MEMORY USAGE small_list
MEMORY USAGE large_list
OBJECT ENCODING small_list
OBJECT ENCODING large_list
```

## 🔧 6. 메모리 모니터링 및 최적화

### 메모리 상태 모니터링
```bash
# 상세 메모리 정보
INFO memory

# 키스페이스 정보
INFO keyspace

# 메모리 조각화 정보
INFO memory | grep fragmentation

# 메모리 사용량 상위 키 조회 (개별 키 확인)
MEMORY USAGE large_string_1
MEMORY USAGE user:1000
MEMORY USAGE message_queue
```

### 메모리 최적화 명령
```bash
# 메모리 정리
MEMORY PURGE

# 데이터베이스 재구성 (조각화 해결)
DEBUG RESTART

# 설정 저장
CONFIG REWRITE
```

## 📊 성능 측정 및 분석

### 메모리 정책별 성능 비교
```bash
# 각 정책별로 redis-benchmark 실행
# 1. allkeys-lru
CONFIG SET maxmemory-policy allkeys-lru
# 외부 터미널에서: docker exec redis-memory-test redis-benchmark -n 10000 -d 100

# 2. volatile-lru  
CONFIG SET maxmemory-policy volatile-lru
# 외부 터미널에서: docker exec redis-memory-test redis-benchmark -n 10000 -d 100

# 3. allkeys-random
CONFIG SET maxmemory-policy allkeys-random
# 외부 터미널에서: docker exec redis-memory-test redis-benchmark -n 10000 -d 100
```

## 🎯 실습 완료 체크리스트

- [ ] 메모리 정보 조회 및 분석 완료
- [ ] 압축 설정 적용 및 확인 완료
- [ ] 메모리 정책별 테스트 완료
- [ ] 데이터 구조별 메모리 사용량 비교 완료
- [ ] 압축 효과 확인 완료
- [ ] 메모리 모니터링 방법 학습 완료
- [ ] 성능 측정 및 분석 완료

## 🔍 추가 학습 포인트

1. **메모리 정책 선택 기준**
   - 캐시 용도: `allkeys-lru` 권장
   - 세션 저장: `volatile-lru` 권장
   - 랜덤 삭제: `allkeys-random` (특수한 경우)

2. **데이터 구조 선택 기준**
   - 관련 필드가 많은 경우: Hash 사용
   - 단순 값 저장: String 사용
   - 중복 제거가 중요한 경우: Set 사용

3. **실무 적용 팁**
   - 메모리 사용량 정기 모니터링
   - 적절한 TTL 설정으로 메모리 관리
   - 압축 설정을 통한 메모리 효율성 향상

## 정리

이번 실습을 통해 Redis의 메모리 최적화 기법을 학습했습니다. 적절한 메모리 정책과 압축 설정을 통해 한정된 메모리를 효율적으로 사용할 수 있습니다.