# Redis Sentinel 구성 실습 교안

## 🎯 학습 목표
- Redis Sentinel의 개념과 필요성 이해
- Docker Compose를 이용한 Master-Slave-Sentinel 구성
- 고가용성 환경에서 자동 장애조치(Failover) 체험
- Sentinel을 통한 Redis 모니터링 및 관리

## 📋 사전 준비사항
- Docker Desktop for Windows 설치 완료
- Docker Compose 사용 가능
- 기본 Redis 명령어 숙지

---

## 🔍 Redis Sentinel 개념

### Sentinel이란?
- Redis의 고가용성(High Availability)을 제공하는 시스템
- Master-Slave 구조에서 Master 장애 시 자동으로 Slave를 Master로 승격
- Redis 인스턴스 모니터링 및 알림 기능 제공

### 주요 기능
1. **모니터링**: Redis 인스턴스 상태 감시
2. **알림**: 문제 발생 시 관리자에게 알림
3. **자동 장애조치**: Master 실패 시 Slave를 새로운 Master로 승격
4. **구성 제공**: 클라이언트에게 현재 Master 정보 제공

---

## 🛠 실습 환경 구성

### 1단계: Docker Compose 파일 생성

프로젝트 디렉토리를 만들고 `docker-compose.yml` 파일을 생성합니다.

```yaml
version: '3.8'

services:
  # Redis Master
  redis-master:
    image: redis:7-alpine
    container_name: redis-master
    ports:
      - "6379:6379"
    command: redis-server --port 6379
    networks:
      - redis-sentinel-net

  # Redis Slave 1
  redis-slave1:
    image: redis:7-alpine
    container_name: redis-slave1
    ports:
      - "6380:6379"
    command: redis-server --port 6379 --replicaof redis-master 6379
    depends_on:
      - redis-master
    networks:
      - redis-sentinel-net

  # Redis Slave 2
  redis-slave2:
    image: redis:7-alpine
    container_name: redis-slave2
    ports:
      - "6381:6379"
    command: redis-server --port 6379 --replicaof redis-master 6379
    depends_on:
      - redis-master
    networks:
      - redis-sentinel-net

  # Sentinel 1
  redis-sentinel1:
    image: redis:7-alpine
    container_name: redis-sentinel1
    ports:
      - "26379:26379"
    command: redis-sentinel /etc/redis/sentinel.conf
    volumes:
      - ./sentinel1.conf:/etc/redis/sentinel.conf
    depends_on:
      - redis-master
    networks:
      - redis-sentinel-net

  # Sentinel 2
  redis-sentinel2:
    image: redis:7-alpine
    container_name: redis-sentinel2
    ports:
      - "26380:26379"
    command: redis-sentinel /etc/redis/sentinel.conf
    volumes:
      - ./sentinel2.conf:/etc/redis/sentinel.conf
    depends_on:
      - redis-master
    networks:
      - redis-sentinel-net

  # Sentinel 3
  redis-sentinel3:
    image: redis:7-alpine
    container_name: redis-sentinel3
    ports:
      - "26381:26379"
    command: redis-sentinel /etc/redis/sentinel.conf
    volumes:
      - ./sentinel3.conf:/etc/redis/sentinel.conf
    depends_on:
      - redis-master
    networks:
      - redis-sentinel-net

networks:
  redis-sentinel-net:
    driver: bridge
```

### 2단계: Sentinel 설정 파일 생성

각 Sentinel의 설정 파일을 생성합니다.

**sentinel1.conf:**
```conf
port 26379
sentinel monitor mymaster redis-master 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 10000
sentinel parallel-syncs mymaster 1
```

**sentinel2.conf:**
```conf
port 26379
sentinel monitor mymaster redis-master 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 10000
sentinel parallel-syncs mymaster 1
```

**sentinel3.conf:**
```conf
port 26379
sentinel monitor mymaster redis-master 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 10000
sentinel parallel-syncs mymaster 1
```

### 3단계: 환경 실행

```bash
# Docker Compose로 전체 환경 시작
docker-compose up -d

# 컨테이너 상태 확인
docker-compose ps
```

---

## 🧪 실습 진행

### 실습 1: 기본 구성 확인

```bash
# Master에 테스트 데이터 삽입
docker exec -it redis-master redis-cli
127.0.0.1:6379> SET user:1001 "홍길동"
127.0.0.1:6379> SET user:1002 "김철수"
127.0.0.1:6379> HSET product:2001 name "노트북" price 1500000 stock 10
127.0.0.1:6379> HSET product:2002 name "마우스" price 35000 stock 50
127.0.0.1:6379> SADD tags:tech "개발" "프로그래밍" "AI" "머신러닝"
127.0.0.1:6379> ZADD leaderboard 100 "플레이어1" 85 "플레이어2" 92 "플레이어3"
127.0.0.1:6379> EXIT
```

```bash
# Slave1에서 데이터 복제 확인
docker exec -it redis-slave1 redis-cli
127.0.0.1:6379> GET user:1001
127.0.0.1:6379> HGETALL product:2001
127.0.0.1:6379> SMEMBERS tags:tech
127.0.0.1:6379> ZRANGE leaderboard 0 -1 WITHSCORES
127.0.0.1:6379> EXIT
```

### 실습 2: Replication 상태 확인

```bash
# Master 복제 상태 확인
docker exec -it redis-master redis-cli INFO replication

# Slave 복제 상태 확인
docker exec -it redis-slave1 redis-cli INFO replication
docker exec -it redis-slave2 redis-cli INFO replication
```

### 실습 3: Sentinel 상태 확인

```bash
# Sentinel1 상태 확인
docker exec -it redis-sentinel1 redis-cli -p 26379

# Sentinel 명령어들
127.0.0.1:26379> SENTINEL masters
127.0.0.1:26379> SENTINEL slaves mymaster
127.0.0.1:26379> SENTINEL sentinels mymaster
127.0.0.1:26379> SENTINEL get-master-addr-by-name mymaster
127.0.0.1:26379> EXIT
```

### 실습 4: 장애조치(Failover) 테스트

```bash
# 현재 Master 정보 확인
docker exec -it redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

# Master 컨테이너 중지 (장애 시뮬레이션)
docker stop redis-master

# 장애조치 과정 모니터링 (약 5-10초 대기)
docker exec -it redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

# 새로운 Master에서 데이터 확인
# (새로운 Master가 slave1 또는 slave2가 됨)
docker exec -it redis-slave1 redis-cli GET user:1001
```

### 실습 5: 장애조치 후 데이터 무결성 확인

```bash
# 새로운 Master에 추가 데이터 삽입
docker exec -it redis-slave1 redis-cli
127.0.0.1:6379> SET order:3001 "주문완료"
127.0.0.1:6379> HSET customer:4001 name "이영희" email "lee@email.com" phone "010-1234-5678"
127.0.0.1:6379> LPUSH notifications "새로운 주문이 도착했습니다" "재고가 부족합니다"
127.0.0.1:6379> EXIT

# 다른 Slave에서 복제 확인
docker exec -it redis-slave2 redis-cli
127.0.0.1:6379> GET order:3001
127.0.0.1:6379> HGETALL customer:4001
127.0.0.1:6379> LRANGE notifications 0 -1
127.0.0.1:6379> EXIT
```

### 실습 6: 원래 Master 복구

```bash
# 원래 Master 재시작
docker start redis-master

# 복구된 노드가 Slave로 동작하는지 확인
docker exec -it redis-master redis-cli INFO replication

# 데이터 동기화 확인
docker exec -it redis-master redis-cli
127.0.0.1:6379> GET order:3001
127.0.0.1:6379> HGETALL customer:4001
127.0.0.1:6379> EXIT
```

---

## 📊 모니터링 및 관리

### Sentinel 로그 확인
```bash
# Sentinel 로그 실시간 확인
docker logs -f redis-sentinel1
docker logs -f redis-sentinel2
docker logs -f redis-sentinel3
```

### Sentinel 정보 조회
```bash
# 전체 Sentinel 정보
docker exec -it redis-sentinel1 redis-cli -p 26379 INFO sentinel

# Master 상태 상세 정보
docker exec -it redis-sentinel1 redis-cli -p 26379 SENTINEL masters
```

---

## 🔧 문제 해결

### 일반적인 문제들

1. **Sentinel이 Master를 찾지 못하는 경우**
   - 네트워크 설정 확인
   - 컨테이너 간 통신 가능 여부 확인

2. **Failover가 발생하지 않는 경우**
   - Quorum 설정 확인 (최소 2개 Sentinel 필요)
   - down-after-milliseconds 설정 확인

3. **데이터 동기화 문제**
   - 네트워크 지연 확인
   - 복제 백로그 설정 확인

---

## 💡 실무 팁

1. **운영 환경 권장사항**
   - 홀수 개의 Sentinel 운영 (3개, 5개 등)
   - 서로 다른 물리적 위치에 Sentinel 배치
   - 적절한 타임아웃 값 설정

2. **성능 최적화**
   - 복제 백로그 크기 조정
   - 네트워크 대역폭 고려한 설정

3. **보안 고려사항**
   - AUTH 설정으로 인증 강화
   - 방화벽 규칙 적용

---

## 🧹 실습 정리

```bash
# 전체 환경 종료
docker-compose down

# 볼륨까지 삭제 (선택사항)
docker-compose down -v

# 네트워크 정리
docker network prune
```

---

## 📝 학습 정리

### 핵심 개념 체크
- [ ] Redis Sentinel의 역할과 필요성 이해
- [ ] Master-Slave 복제 구조 이해
- [ ] 자동 장애조치 메커니즘 이해
- [ ] Quorum 개념 이해

### 실습 완료 체크
- [ ] Docker Compose 환경 구성 완료
- [ ] 기본 복제 동작 확인 완료
- [ ] 장애조치 테스트 완료
- [ ] 데이터 무결성 확인 완료

### 다음 단계
- Redis Cluster 구성 학습
- 더 복잡한 고가용성 아키텍처 설계
- 실제 애플리케이션과의 연동 방법 학습

---

이 실습을 통해 Redis Sentinel의 고가용성 기능을 직접 체험하고, 실제 장애 상황에서의 자동 복구 과정을 이해할 수 있습니다.