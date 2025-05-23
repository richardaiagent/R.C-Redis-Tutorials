# Redis 초급 1단계: Docker Redis 환경 구성 ⭐⭐⭐

## 🎯 학습 목표
Docker Desktop을 사용하여 Redis 컨테이너를 실행하고 기본 환경을 구성합니다.

## 🐳 사전 준비사항
- **OS**: Windows 10/11
- **도구**: Docker Desktop for Windows 설치 완료
- **권한**: 관리자 권한으로 PowerShell 또는 CMD 실행

---

## 📋 실습 단계

### 1-1. Docker Desktop 실행 확인
```bash
# Docker 버전 확인
docker --version

# Docker 실행 상태 확인
docker info
```

### 1-2. Redis 컨테이너 실행 (기본 버전)
```bash
# 기본 Redis 컨테이너 실행
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

# 실행 결과 예시
# a1b2c3d4e5f6... (컨테이너 ID가 출력됨)
```

### 1-3. 컨테이너 실행 상태 확인
```bash
# 실행 중인 컨테이너 확인
docker ps

# 예상 출력 결과
# CONTAINER ID   IMAGE           COMMAND                  CREATED         STATUS         PORTS                    NAMES
# a1b2c3d4e5f6   redis:7-alpine  "docker-entrypoint.s…"   2 minutes ago   Up 2 minutes   0.0.0.0:6379->6379/tcp   redis-lab
```

### 1-4. Redis 컨테이너 로그 확인
```bash
# Redis 서버 로그 확인
docker logs redis-lab

# 예상 출력 결과
# 1:C 23 May 2025 10:30:45.123 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
# 1:C 23 May 2025 10:30:45.123 # Redis version=7.0.11, bits=64, commit=00000000, modified=0, pid=1, just started
# 1:M 23 May 2025 10:30:45.124 * Ready to accept connections
```

### 1-5. 포트 바인딩 확인
```bash
# Windows에서 포트 확인
netstat -an | findstr 6379

# 예상 출력 결과
# TCP    0.0.0.0:6379           0.0.0.0:0              LISTENING
```

---

## 🔧 데이터 영속성을 위한 고급 설정 (선택사항)

### 1-6. 볼륨 마운트 버전으로 재실행
```bash
# 기존 컨테이너 정지 및 삭제
docker stop redis-lab
docker rm redis-lab

# 데이터 영속성을 위한 볼륨 마운트 버전 실행
docker run -d --name redis-persistent -p 6379:6379 -v redis-data:/data redis:7-alpine --appendonly yes

# 볼륨 생성 확인
docker volume ls
```

---

## 🧪 실습 데이터 준비

### 1-7. 테스트 연결 확인
```bash
# Redis CLI로 간단한 연결 테스트
docker exec -it redis-persistent redis-cli ping

# 예상 출력 결과
# PONG
```

---

## ✅ 학습 완료 체크리스트

### 필수 체크사항
- [ ] Docker Desktop이 정상적으로 실행되고 있는가?
- [ ] Redis 컨테이너가 성공적으로 실행되었는가?
- [ ] `docker ps` 명령으로 컨테이너가 실행 중인 것을 확인했는가?
- [ ] 6379 포트가 정상적으로 바인딩되었는가?
- [ ] `redis-cli ping` 명령이 PONG을 반환하는가?

### 선택 체크사항
- [ ] 볼륨 마운트를 통한 데이터 영속성 설정을 완료했는가?
- [ ] Redis 서버 로그를 확인하여 정상 기동을 확인했는가?

---

## 🚨 문제 해결 가이드

### 문제 1: Docker Desktop이 실행되지 않음
**해결방법**: 
- Windows 기능에서 "Linux용 Windows 하위 시스템" 활성화
- 시스템 재부팅 후 Docker Desktop 재실행

### 문제 2: 포트 6379가 이미 사용 중
**해결방법**:
```bash
# 포트를 사용하는 프로세스 확인
netstat -ano | findstr 6379

# 다른 포트로 실행
docker run -d --name redis-lab -p 6380:6379 redis:7-alpine
```

### 문제 3: 컨테이너 실행 실패
**해결방법**:
```bash
# 기존 컨테이너 확인 및 정리
docker ps -a
docker rm redis-lab

# 이미지 다시 다운로드
docker pull redis:7-alpine
```

---

## 📝 다음 단계 예고
다음 2단계에서는 Redis CLI에 접속하여 기본 명령어를 실습하게 됩니다.

---

## 💡 추가 팁
- 컨테이너 이름은 `redis-lab` 대신 원하는 이름으로 변경 가능합니다
- 운영 환경에서는 반드시 볼륨 마운트를 사용하여 데이터 영속성을 보장하세요
- Redis 컨테이너 메모리 사용량을 제한하려면 `--memory=512m` 옵션을 추가하세요