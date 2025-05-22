
```mermaid

sequenceDiagram
    participant 클라이언트
    participant Redis
    participant 디스크
    
    클라이언트->>Redis: 요청(SET/GET)
    Redis->>디스크: 주기적으로 데이터 저장
    Redis->>클라이언트: 응답(값 반환)