#!/bin/bash
#
# Redis 성능 테스트 스크립트 (benchmark.sh)
# 
# 이 스크립트는 Redis 서버의 성능을 측정하기 위한 도구입니다.
# redis-benchmark 유틸리티를 이용하여 다양한 명령어와 설정에 대한 성능 메트릭을 수집합니다.
#
# 사용법: ./benchmark.sh [options]
#

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 기본 설정값
HOST="localhost"
PORT=6379
CLIENTS=50
REQUESTS=100000
DATA_SIZE=3
TESTS="set,get,incr,lpush,rpush,lpop,rpop,sadd,hset,spop,lrange,mset"
VERBOSE=0
CSV_OUTPUT=""
PIPELINE=1
PASSWORD=""
TLS=0

# 배너 출력
print_banner() {
    echo -e "${BLUE}=====================================================${NC}"
    echo -e "${BLUE}       Redis 성능 테스트 스크립트 (benchmark.sh)       ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo ""
}

# 사용법 출력
print_usage() {
    echo "사용법: $0 [options]"
    echo ""
    echo "옵션:"
    echo "  -h HOST       호스트 지정 (기본값: $HOST)"
    echo "  -p PORT       포트 지정 (기본값: $PORT)"
    echo "  -c CLIENTS    동시 연결 수 (기본값: $CLIENTS)"
    echo "  -n REQUESTS   총 요청 수 (기본값: $REQUESTS)"
    echo "  -d DATA_SIZE  데이터 크기 (바이트) (기본값: $DATA_SIZE)"
    echo "  -t TESTS      테스트할 명령어 (기본값: $TESTS)"
    echo "  -a PASSWORD   Redis 인증 비밀번호"
    echo "  -P PIPELINE   파이프라인 요청 수 (기본값: $PIPELINE)"
    echo "  -v            상세 출력 모드"
    echo "  -csv FILENAME CSV 파일로 결과 저장"
    echo "  --tls         TLS 연결 사용"
    echo "  --help        도움말 표시"
    echo ""
    echo "예제:"
    echo "  $0 -h redis.example.com -p 6380 -c 100 -n 500000 -d 1024 -t set,get"
    echo "  $0 -t set,get,lpush,lpop -csv results.csv"
    echo ""
}

# 매개변수 파싱
parse_parameters() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h)
                HOST="$2"
                shift 2
                ;;
            -p)
                PORT="$2"
                shift 2
                ;;
            -c)
                CLIENTS="$2"
                shift 2
                ;;
            -n)
                REQUESTS="$2"
                shift 2
                ;;
            -d)
                DATA_SIZE="$2"
                shift 2
                ;;
            -t)
                TESTS="$2"
                shift 2
                ;;
            -a)
                PASSWORD="$2"
                shift 2
                ;;
            -P)
                PIPELINE="$2"
                shift 2
                ;;
            -v)
                VERBOSE=1
                shift
                ;;
            -csv)
                CSV_OUTPUT="$2"
                shift 2
                ;;
            --tls)
                TLS=1
                shift
                ;;
            --help)
                print_banner
                print_usage
                exit 0
                ;;
            *)
                echo -e "${RED}에러: 알 수 없는 옵션 $1${NC}"
                print_usage
                exit 1
                ;;
        esac
    done
}

# Redis 연결 확인
check_redis_connection() {
    echo -e "${BLUE}Redis 연결 확인 중... ($HOST:$PORT)${NC}"
    
    local redis_cli_cmd="redis-cli -h $HOST -p $PORT"
    
    if [[ -n "$PASSWORD" ]]; then
        redis_cli_cmd="$redis_cli_cmd -a $PASSWORD"
    fi
    
    if [[ "$TLS" -eq 1 ]]; then
        redis_cli_cmd="$redis_cli_cmd --tls"
    fi
    
    if ! $redis_cli_cmd ping > /dev/null 2>&1; then
        echo -e "${RED}오류: Redis 서버에 연결할 수 없습니다. ($HOST:$PORT)${NC}"
        echo -e "${YELLOW}redis-cli가 설치되어 있는지, Redis 서버가 실행 중인지 확인하세요.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}성공: Redis 서버에 연결되었습니다.${NC}"
    
    # Redis 정보 출력
    if [[ "$VERBOSE" -eq 1 ]]; then
        echo -e "${CYAN}Redis 서버 정보:${NC}"
        $redis_cli_cmd info server | grep redis_version
        $redis_cli_cmd info server | grep os
        $redis_cli_cmd info memory | grep used_memory_human
        echo ""
    fi
    
    return 0
}

# 벤치마크 실행
run_benchmark() {
    echo -e "${CYAN}벤치마크 설정:${NC}"
    echo -e "- 호스트: ${GREEN}$HOST:$PORT${NC}"
    echo -e "- 클라이언트 수: ${GREEN}$CLIENTS${NC}"
    echo -e "- 요청 수: ${GREEN}$REQUESTS${NC}"
    echo -e "- 데이터 크기: ${GREEN}$DATA_SIZE 바이트${NC}"
    echo -e "- 테스트: ${GREEN}$TESTS${NC}"
    echo -e "- 파이프라인: ${GREEN}$PIPELINE${NC}"
    echo ""
    
    # 벤치마크 명령 구성
    local benchmark_cmd="redis-benchmark -h $HOST -p $PORT -c $CLIENTS -n $REQUESTS -d $DATA_SIZE -t $TESTS -P $PIPELINE"
    
    if [[ -n "$PASSWORD" ]]; then
        benchmark_cmd="$benchmark_cmd -a $PASSWORD"
    fi
    
    if [[ "$TLS" -eq 1 ]]; then
        benchmark_cmd="$benchmark_cmd --tls"
    fi
    
    if [[ -n "$CSV_OUTPUT" ]]; then
        benchmark_cmd="$benchmark_cmd --csv > $CSV_OUTPUT"
    fi
    
    if [[ "$VERBOSE" -eq 1 ]]; then
        echo -e "${CYAN}실행 명령: ${NC}$benchmark_cmd"
        echo ""
    fi
    
    # 벤치마크 실행
    echo -e "${BLUE}벤치마크 실행 중... (완료까지 몇 분 소요될 수 있습니다)${NC}"
    echo ""
    
    # 벤치마크 실행 시간 측정 시작
    local start_time=$(date +%s)
    
    # 벤치마크 실행
    eval $benchmark_cmd
    
    # 벤치마크 실행 시간 측정 종료
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo -e "${GREEN}벤치마크 완료! 총 실행 시간: $duration 초${NC}"
    
    if [[ -n "$CSV_OUTPUT" ]]; then
        echo -e "${CYAN}결과가 $CSV_OUTPUT 파일에 저장되었습니다.${NC}"
    fi
}

# 주요 실행 함수
main() {
    print_banner
    parse_parameters "$@"
    
    # redis-benchmark 유틸리티 확인
    if ! command -v redis-benchmark &> /dev/null; then
        echo -e "${RED}오류: redis-benchmark 유틸리티를 찾을 수 없습니다.${NC}"
        echo -e "${YELLOW}Redis 도구가 설치되어 있는지 확인하십시오.${NC}"
        exit 1
    fi
    
    # Redis 연결 확인
    if ! check_redis_connection; then
        exit 1
    fi
    
    # 벤치마크 실행
    run_benchmark
    
    echo ""
    echo -e "${GREEN}테스트 완료! 결과를 확인하세요.${NC}"
    echo -e "${CYAN}차트 생성 또는 추가 분석을 위해 CSV 출력 (-csv 옵션)을 사용할 수 있습니다.${NC}"
}

# 스크립트 실행
main "$@"