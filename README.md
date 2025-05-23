# R.C-Redis-Tutorials

Redis 튜토리얼 및 예제 코드 저장소입니다.

## 브랜치 안내
- main: 메인 브랜치 (소유자만 수정 가능)
- bridge: 개발 브랜치 (누구나 수정 가능)

# R.C-Redis-Tutorials

Redis 튜토리얼 및 예제 코드 저장소입니다. 실무에서 활용할 수 있는 Redis 기능들을 단계별로 학습할 수 있도록 구성되어 있습니다.

## 📋 프로젝트 소개

이 저장소는 Redis의 다양한 기능을 실습하고 학습할 수 있는 예제 코드와 튜토리얼을 제공합니다. 각 단계별로 구성된 실습 자료를 통해 Redis를 체계적으로 익힐 수 있습니다.

## 🚀 빠른 시작

### 필수 요구사항
- Docker Desktop 설치
- Git 설치
- 기본적인 터미널 사용법

### 저장소 복제 및 실행
```bash
# 저장소 복제
git clone https://github.com/richardaiagent/R.C-Redis-Tutorials.git
cd R.C-Redis-Tutorials

# Docker를 사용한 Redis 환경 구축
docker-compose up -d

# Redis 연결 확인
docker exec -it redis redis-cli ping
```

## 📚 현재 제공되는 튜토리얼

### Step 0: Redis 기초 이해
- Redis 개념 및 특징
- Redis 초급 중급 고습 실습 및 시험 테스트
- Docker 기반 Redis 환경 구축

### Step 1: Redis 컨테이너화
- Docker를 활용한 Redis 설치 및 설정
- 컨테이너 관리 및 데이터 영속성

### Step 2: Redis 명령어 실습
- 기본 명령어 사용법
- CLI 환경에서의 실습

> **참고**: 커리큘럼은 지속적으로 업데이트되며, 새로운 단계와 내용이 추가됩니다.

## 🛠️ 프로젝트 구조

```
R.C-Redis-Tutorials/
├── Step-0-Understanding Redis Basics/     # Redis 기초
├── Step-1-Redis Containerization/         # Docker 기반 설치
├── Step-2-Redis Command Practice/         # 명령어 실습
├── README.md                              # 프로젝트 소개
└── (추가 단계들이 지속적으로 업데이트됩니다)
```

## 🔄 프로젝트 특징

- **지속적인 업데이트**: 새로운 Redis 기능과 실습 내용이 정기적으로 추가됩니다
- **실무 중심**: 실제 개발 환경에서 사용할 수 있는 실용적인 예제 제공
- **단계별 학습**: 기초부터 고급까지 체계적인 학습 경로 제공
- **Docker 기반**: 일관된 개발 환경 제공

## 🤝 기여 및 피드백

이 프로젝트는 **오픈 소스**로 운영되며, 여러분의 기여를 환영합니다!

### 🎯 기여 방법
1. **이슈 등록**: 버그 리포트, 기능 제안, 질문 등
2. **Pull Request**: 코드 개선, 새로운 예제 추가, 문서 수정
3. **피드백 제공**: 사용 후기, 개선 아이디어 공유

### 📝 기여 가이드
자세한 기여 방법은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고해주세요.

## 📞 소통 채널

- **Issues**: 버그 리포트 및 기능 요청
- **Discussions**: 질문, 아이디어 공유, 일반적인 토론
- **Email**: s4zspace@gmail.com

## 🏷️ 브랜치 정책

- **main**: 안정화된 메인 브랜치 (소유자 관리)
- **기여 시**: Fork 후 Pull Request 방식 권장

## ⚡ 최근 업데이트

- Redis 컨테이너화 튜토리얼 추가
- CLI 명령어 실습 예제 업데이트
- Docker Compose 설정 개선

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

---

⭐ **유용하다고 생각하시면 Star를 눌러주세요!**

🔄 **Watch를 설정하면 새로운 업데이트 소식을 받을 수 있습니다.**

💬 **궁금한 점이나 제안사항이 있으시면 언제든 Issues나 Discussions를 활용해주세요.**