# Redis 중급 13강 - Stream 데이터 타입 실습

## 🎯 학습 목표
- Redis Stream 데이터 타입의 개념과 활용법 이해
- 이벤트 스트리밍 및 로그 수집 시스템 구현
- 실시간 주문 처리 스트림 구현

## 📚 이론 학습

### Redis Stream이란?
- Redis 5.0에서 도입된 로그 구조 데이터 타입
- 시간 순서대로 데이터를 저장하고 처리
- 메시지 큐와 로그 시스템의 특성을 결합
- 소비자 그룹을 통한 분산 처리 지원

### 주요 명령어
- `XADD stream_name * field1 value1 field2 value2...`: 메시지 추가
- `XREAD STREAMS stream_name last_id`: 메시지 읽기
- `XRANGE stream_name start end`: 범위 조회
- `XGROUP CREATE stream_name group_name start_id`: 소비자 그룹 생성
- `XREADGROUP GROUP group_name consumer_name STREAMS stream_name >`: 그룹