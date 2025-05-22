# 기여 가이드 (Contributing Guide)

R.C-Redis-Tutorials 프로젝트에 기여해주셔서 감사합니다! 🎉

이 문서는 프로젝트에 효과적으로 기여하는 방법을 안내합니다.

## 🤝 기여 방법

### 1. 이슈 기반 기여
- **버그 리포트**: 발견한 문제점 신고
- **기능 제안**: 새로운 Redis 튜토리얼이나 예제 아이디어 제안
- **질문**: Redis 사용법이나 프로젝트 관련 질문

### 2. 코드 기여
- **새로운 튜토리얼 추가**: 새로운 Step 추가
- **기존 코드 개선**: 더 나은 예제나 설명 제공
- **문서 업데이트**: README, 주석, 설명 개선

### 3. 리뷰 및 피드백
- **코드 리뷰**: Pull Request 검토 및 피드백
- **사용 후기**: 실제 사용 경험 공유
- **개선 제안**: 더 나은 학습 경험을 위한 아이디어

## 🔄 기여 프로세스

### 방법 1: 이슈를 통한 기여
```bash
1. GitHub Issues에서 새 이슈 생성
2. 문제점, 제안사항, 질문 등을 자세히 작성
3. 라벨 선택 (bug, enhancement, question 등)
4. 제출 후 논의 참여
```

### 방법 2: Pull Request를 통한 기여
```bash
# 1. 저장소 Fork
GitHub에서 "Fork" 버튼 클릭

# 2. 로컬에 복제
git clone https://github.com/YOUR-USERNAME/R.C-Redis-Tutorials.git
cd R.C-Redis-Tutorials

# 3. 새 브랜치 생성
git checkout -b feature/your-feature-name
# 예: git checkout -b tutorial/redis-clustering

# 4. 변경사항 작업
# 새로운 튜토리얼 추가, 코드 개선 등

# 5. 커밋
git add .
git commit -m "Add Redis clustering tutorial"

# 6. Fork한 저장소에 푸시
git push origin feature/your-feature-name

# 7. GitHub에서 Pull Request 생성
```

## 📋 기여 가이드라인

### 💻 코드 스타일
- **명확한 주석**: 코드에 한글 또는 영어 주석 추가
- **일관된 형식**: 기존 파일 구조와 일치하는 형식 사용
- **실행 가능한 예제**: 모든 예제는 실제로 동작해야 함

### 📁 파일 구조
```
Step-X-Tutorial-Name/
├── README.md              # 튜토리얼 설명
├── docker-compose.yml     # Docker 설정 (필요시)
├── examples/              # 실습 코드
├── scripts/               # 실행 스크립트
└── docs/                  # 추가 문서
```

### 📝 문서 작성
- **명확한 제목**: 무엇을 다루는지 명확히 표현
- **단계별 설명**: 초보자도 따라할 수 있는 상세한 설명
- **실행 결과**: 예상되는 출력 결과 포함
- **문제 해결**: 자주 발생하는 오류와 해결법

## 🎯 기여 아이디어

### 새로운 튜토리얼 주제
- Redis 데이터 타입별 심화 학습
- Redis Pub/Sub 실습
- Redis Cluster 구성
- Redis와 다른 DB 연동
- Redis 성능 모니터링
- Redis 보안 설정
- Redis Sentinel 구성

### 개선 가능한 영역
- 기존 예제 코드 최적화
- 더 나은 Docker 설정
- 시각화 자료 추가
- 다국어 문서 지원
- 자동화 스크립트 개선

## ✅ Pull Request 체크리스트

Pull Request를 제출하기 전에 다음 사항을 확인해주세요:

- [ ] 모든 예제 코드가 정상 동작함
- [ ] README.md에 새로운 내용 설명 추가
- [ ] Docker 관련 파일이 올바르게 작성됨
- [ ] 코드에 적절한 주석 추가
- [ ] 기존 코드와 일관된 스타일 유지
- [ ] 커밋 메시지가 명확함

## 📞 소통하기

### 어디서 도움을 받을 수 있나요?
- **GitHub Issues**: 버그나 문제점 신고
- **GitHub Discussions**: 아이디어 공유, 질문
- **Email**: s4zspace@gmail.com (긴급하지 않은 문의)

### 응답 시간
- **Issues**: 보통 1-3일 내 응답
- **Pull Request**: 보통 3-7일 내 리뷰
- **Email**: 1주일 내 응답

## 🏷️ 라벨 시스템

### Issue 라벨
- `bug`: 버그 리포트
- `enhancement`: 새 기능 제안
- `question`: 질문
- `help wanted`: 도움이 필요한 작업
- `good first issue`: 초보자에게 적합한 작업

### Pull Request 라벨
- `tutorial`: 새로운 튜토리얼 추가
- `improvement`: 기존 내용 개선
- `documentation`: 문서 관련 변경
- `bug fix`: 버그 수정

## 🎖️ 기여자 인정

모든 기여자는 다음과 같은 방식으로 인정받습니다:
- README.md의 기여자 섹션에 이름 추가
- 특별한 기여에 대해서는 별도 감사 인사
- 프로젝트 발전에 대한 공로 인정

## 📚 추가 자료

- [Redis 공식 문서](https://redis.io/documentation)
- [Docker 공식 문서](https://docs.docker.com/)
- [GitHub Flow 가이드](https://guides.github.com/introduction/flow/)

---

## 💝 마지막으로

여러분의 기여가 이 프로젝트를 더욱 가치 있게 만듭니다. 작은 기여라도 큰 도움이 됩니다!

**기여에 대한 질문이나 도움이 필요하시면 언제든 연락주세요.** 🚀