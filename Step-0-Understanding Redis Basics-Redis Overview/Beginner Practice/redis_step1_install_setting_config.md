# Redis 초급 1번 - Docker Redis 환경 구성 실습 교안

## 📋 학습 목표
- Docker Desktop 설치 및 기본 개념 이해
- Redis Docker 컨테이너 실행 및 관리
- Windows PowerShell을 통한 Docker 명령어 숙지
- Redis 컨테이너 포트 매핑 및 네트워킹 이해
- 데이터 영속성을 위한 볼륨 마운트 설정

## 🔧 사전 준비사항

### 시스템 요구사항
- **OS**: Windows 10 Pro/Enterprise/Education (버전 2004 이상) 또는 Windows 11
- **하드웨어**: WSL 2 지원 (Hyper-V 또는 WSL 2 활성화)
- **메모리**: 최소 4GB RAM (권장 8GB 이상)
- **저장공간**: 최소 10GB 여유 공간

## 🐳 Docker Desktop 설치

### 1단계: Docker Desktop 다운로드
1. [Docker Desktop 공식 사이트](https://www.docker.com/products/docker-desktop/) 접속
2. "Download for Windows" 클릭
3. `Docker Desktop Installer.exe` 다운로드

### 2단계: Docker Desktop 설치
```powershell
# PowerShell을 관리자 권한으로 실행 후 설치 확인
# 다운로드된 설치 파일 실행
.\Docker\ Desktop\ Installer.exe
```

### 3단계: 설치 후 설정
1. **WSL 2 활성화** 체크 (권장)
2. **Add shortcut to desktop** 체크
3. 설치 완료 후 재부팅

### 4단계: Docker Desktop 실행 및 확인
```powershell
# PowerShell에서 Docker 설치 확인
docker --version
docker-compose --version

# Docker 데몬 상태 확인
docker info
```

## 🚀 Redis 컨테이너 실습

### 실습 1: 기본 Redis 컨테이너 실행

#### 1-1. Redis 이미지 다운로드 및 컨테이너 실행
```powershell
# PowerShell에서 실행
# Redis 7 Alpine 이미지로 컨테이너 실행
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

# 실행 중인 컨테이너 확인
docker ps

# 모든 컨테이너 확인 (중지된 것 포함)
docker ps -a
```

#### 1-2. 컨테이너 상태 확인
```powershell
# 컨테이너 로그 확인
docker logs redis-lab

# 컨테이너 상세 정보 확인
docker inspect redis-lab

# 컨테이너 리소스 사용량 확인
docker stats redis-lab --no-stream
```

#### 1-3. Redis 연결 테스트
```powershell
# Redis CLI 접속
docker exec -it redis-lab redis-cli

# Redis 내부에서 연결 테스트
ping
# 응답: PONG

# 기본 데이터 테스트
set test_key "Hello Redis!"
get test_key

# Redis CLI 종료
exit
```

### 실습 2: 데이터 영속성을 위한 볼륨 마운트

#### 2-1. 기존 컨테이너 정리
```powershell
# 실행 중인 컨테이너 중지
docker stop redis-lab

# 컨테이너 삭제
docker rm redis-lab

# 삭제 확인
docker ps -a
```

#### 2-2. 볼륨을 사용한 Redis 컨테이너 실행
```powershell
# 이름있는 볼륨 생성
docker volume create redis-data

# 볼륨 확인
docker volume ls

# 볼륨을 마운트한 Redis 컨테이너 실행
docker run -d --name redis-persistent -p 6379:6379 -v redis-data:/data redis:7-alpine

# 컨테이너 실행 확인
docker ps
```

#### 2-3. 데이터 영속성 테스트
```powershell
# Redis CLI 접속하여 데이터 입력
docker exec -it redis-persistent redis-cli

# 테스트 데이터 입력 (Redis CLI 내부)
set persistent_key "이 데이터는 영구 저장됩니다"
set user:1001 "김철수"
set counter 100
lpush messages "첫 번째 메시지" "두 번째 메시지" "세 번째 메시지"
sadd tags "redis" "docker" "database" "cache"

# 데이터 확인
get persistent_key
get user:1001
get counter
lrange messages 0 -1
smembers tags

# Redis CLI 종료
exit
```

#### 2-4. 컨테이너 재시작 후 데이터 확인
```powershell
# 컨테이너 중지
docker stop redis-persistent

# 컨테이너 재시작
docker start redis-persistent

# 데이터 영속성 확인
docker exec -it redis-persistent redis-cli

# 이전에 입력한 데이터 확인 (Redis CLI 내부)
get persistent_key
get user:1001
get counter
lrange messages 0 -1
smembers tags

# 모든 키 확인
keys *

exit
```

### 실습 3: 포트 매핑 및 네트워크 설정

#### 3-1. 다른 포트로 Redis 실행
```powershell
# 다른 포트(6380)로 두 번째 Redis 실행
docker run -d --name redis-secondary -p 6380:6379 redis:7-alpine

# 두 개의 Redis 인스턴스 확인
docker ps

# 포트별 접속 테스트
# 첫 번째 Redis (6379 포트)
docker exec -it redis-persistent redis-cli
ping
set primary_db "메인 데이터베이스"
exit

# 두 번째 Redis (6380 포트)
docker exec -it redis-secondary redis-cli
ping
set secondary_db "보조 데이터베이스"
exit
```

#### 3-2. 네트워크 격리 테스트
```powershell
# 각 Redis 인스턴스의 데이터 격리 확인
# 첫 번째 Redis 데이터 확인
docker exec -it redis-persistent redis-cli
get primary_db
get secondary_db  # 존재하지 않음
keys *
exit

# 두 번째 Redis 데이터 확인
docker exec -it redis-secondary redis-cli
get secondary_db
get primary_db  # 존재하지 않음
keys *
exit
```

### 실습 4: Redis 설정 파일 사용

#### 4-1. 커스텀 Redis 설정 파일 생성
```powershell
# 설정 파일 저장용 디렉토리 생성
mkdir C:\redis-config

# 설정 파일 생성 (PowerShell에서 직접 생성)
@"
# Redis 설정 파일
port 6379
bind 0.0.0.0
protected-mode yes
requirepass mypassword123

# 메모리 관련 설정
maxmemory 256mb
maxmemory-policy allkeys-lru

# 로그 설정
loglevel notice
logfile ""

# 데이터베이스 개수
databases 16

# 저장 설정
save 900 1
save 300 10
save 60 10000

# AOF 설정
appendonly yes
appendfsync everysec
"@ | Out-File -FilePath C:\redis-config\redis.conf -Encoding UTF8
```

#### 4-2. 설정 파일을 사용한 Redis 실행
```powershell
# 설정 파일을 마운트한 Redis 컨테이너 실행
docker run -d --name redis-configured -p 6381:6379 -v C:\redis-config:/usr/local/etc/redis -v redis-config-data:/data redis:7-alpine redis-server /usr/local/etc/redis/redis.conf

# 실행 확인
docker ps

# 설정이 적용되었는지 확인 (비밀번호 설정됨)
docker exec -it redis-configured redis-cli

# 비밀번호 없이 접속 시도 (실패해야 함)
ping

# 비밀번호로 인증
auth mypassword123

# 인증 후 명령 실행
ping
info server
config get maxmemory
config get databases

exit
```

## 🔧 Docker 컨테이너 관리

### 컨테이너 생명주기 관리
```powershell
# 모든 Redis 컨테이너 확인
docker ps -a --filter "ancestor=redis:7-alpine"

# 컨테이너 중지
docker stop redis-persistent redis-secondary redis-configured

# 컨테이너 시작
docker start redis-persistent redis-secondary redis-configured

# 컨테이너 재시작
docker restart redis-persistent

# 컨테이너 삭제 (중지 후)
docker stop redis-secondary
docker rm redis-secondary
```

### 이미지 및 볼륨 관리
```powershell
# Docker 이미지 확인
docker images

# 사용하지 않는 이미지 정리
docker image prune

# 볼륨 확인
docker volume ls

# 볼륨 상세 정보
docker volume inspect redis-data

# 사용하지 않는 볼륨 정리 (주의!)
# docker volume prune
```

### 컨테이너 리소스 모니터링
```powershell
# 실시간 리소스 사용량 모니터링
docker stats

# 특정 컨테이너만 모니터링
docker stats redis-persistent

# 한 번만 확인
docker stats --no-stream
```

## 🎯 실습 과제

### 과제 1: 개발/테스트/운영 환경 구성
세 개의 다른 Redis 인스턴스를 구성하세요:
- **개발환경**: 포트 6379, 비밀번호 없음
- **테스트환경**: 포트 6380, 비밀번호 "testpass"
- **운영환경**: 포트 6381, 비밀번호 "prodpass", 볼륨 마운트

### 과제 2: 데이터 백업 시뮬레이션
1. Redis에 다양한 데이터 입력
2. 컨테이너 중지
3. 볼륨 데이터 확인
4. 컨테이너 재시작 후 데이터 복구 확인

## 💡 문제 해결 가이드

### 일반적인 문제들

#### 문제 1: Docker Desktop이 시작되지 않음
```powershell
# WSL 2 상태 확인
wsl --list --verbose

# WSL 2 업데이트
wsl --update

# Docker Desktop 재시작
```

#### 문제 2: 포트 충돌
```powershell
# 포트 사용 상태 확인
netstat -an | findstr :6379

# 다른 포트 사용 또는 기존 프로세스 종료
```

#### 문제 3: 권한 문제
```powershell
# PowerShell을 관리자 권한으로 실행
# 또는 현재 사용자를 docker-users 그룹에 추가
```

#### 문제 4: 메모리 부족
```powershell
# Docker Desktop 설정에서 메모리 할당량 증가
# 설정 → Resources → Advanced → Memory
```

## 📊 환경 검증

### 최종 환경 확인 스크립트
```powershell
# 전체 환경 상태 확인
Write-Host "=== Docker 환경 확인 ===" -ForegroundColor Green
docker --version
docker info --format "{{.ServerVersion}}"

Write-Host "`n=== 실행 중인 Redis 컨테이너 ===" -ForegroundColor Green
docker ps --filter "ancestor=redis:7-alpine" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`n=== Redis 볼륨 확인 ===" -ForegroundColor Green
docker volume ls --filter "name=redis"

Write-Host "`n=== Redis 연결 테스트 ===" -ForegroundColor Green
# 각 Redis 인스턴스 연결 테스트
docker exec redis-persistent redis-cli ping
if ($?) { Write-Host "redis-persistent: OK" -ForegroundColor Green }

# 데이터 확인
Write-Host "`n=== 저장된 데이터 확인 ===" -ForegroundColor Green
docker exec redis-persistent redis-cli keys "*"
```

## ✅ 학습 완료 체크리스트

### 기본 환경 구성
- [ ] Docker Desktop 설치 완료
- [ ] PowerShell에서 Docker 명령어 실행 가능
- [ ] Redis 7-alpine 이미지 다운로드 완료
- [ ] 기본 Redis 컨테이너 실행 성공

### 고급 설정
- [ ] 볼륨 마운트를 통한 데이터 영속성 확인
- [ ] 포트 매핑 이해 및 다중 인스턴스 실행
- [ ] 커스텀 설정 파일 사용 가능
- [ ] 컨테이너 생명주기 관리 숙지

### 운영 관리
- [ ] 컨테이너 모니터링 방법 숙지
- [ ] 문제 해결 능력 확보
- [ ] 백업 및 복구 절차 이해

## 🔗 다음 단계
다음은 **초급 2번 - Redis CLI 접속 및 기본 명령**입니다. Docker 환경 구성을 완료했으니, 이제 Redis CLI를 통해 실제 Redis와 상호작용하는 방법을 학습해보겠습니다.

---
*본 교안은 Windows 10/11 환경의 Docker Desktop과 PowerShell을 기준으로 작성되었습니다.*