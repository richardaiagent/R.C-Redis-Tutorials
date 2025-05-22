#!/bin/bash
#
# Redis 부하 테스트 스크립트 (load-test.sh)
# 
# 이 스크립트는 Redis 서버에 높은 부하를 발생시켜 안정성과 성능 저하 여부를 테스트합니다.
# 대규모 동시 연결 및 지속적인 데이터 요청을 통해 시스템의 한계를 측정합니다.
#
# 사용법: ./load-test.sh [options]
#

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 기본 설정값
HOST="localhost"
PORT=6379
CLIENTS=1000
REQUESTS_PER_CLIENT=10000
DATA_SIZE_KB=10
TEST_DURATION=60
REQUEST_RATE=0  # 무제한
TEST_MODE="mixed"  # read, write, mixed
PASSWORD=""
KEY_PREFIX="loadtest"
MONITOR_INTERVAL=5
RESULT_FILE="redis-loadtest-results.log"
CLEANUP_AFTER_TEST=true
VERBOSE=false
DEBUG=false

# 진행 상태 변수
CURRENT_PROGRESS=0
TOTAL_PROGRESS=100
start_time=0
should_stop=false

# 트랩 설정 - Ctrl+C로 인한 정상 종료
trap ctrl_c INT
ctrl_c() {
    echo -e "\n${YELLOW}테스트가 사용자에 의해 중단되었습니다...${NC}"
    should_stop=true
    wait_for_test_completion
    cleanup_test
    exit 1
}

# 배너 출력
print_banner() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${BLUE}         Redis 부하 테스트 스크립트 (load-test.sh)      ${NC}"
    echo -e "${BLUE}====================================================${NC}"
    echo ""
}

# 사용법 출력
print_usage() {
    echo "사용법: $0 [options]"
    echo ""
    echo "옵션:"
    echo "  -h HOST             호스트 지정 (기본값: $HOST)"
    echo "  -p PORT             포트 지정 (기본값: $PORT)"
    echo "  -c CLIENTS          동시 클라이언트 수 (기본값: $CLIENTS)"
    echo "  -n REQUESTS         클라이언트당 요청 수 (기본값: $REQUESTS_PER_CLIENT)"
    echo "  -d DATA_SIZE        데이터 크기 (KB) (기본값: $DATA_SIZE_KB)"
    echo "  -t DURATION         테스트 지속 시간 (초) (기본값: $TEST_DURATION)"
    echo "  -r REQUEST_RATE     요청 비율 (RPS) (기본값: $REQUEST_RATE, 무제한)"
    echo "  -m MODE             테스트 모드 (기본값: $TEST_MODE)"
    echo "                       - read: 읽기 전용 테스트"
    echo "                       - write: 쓰기 전용 테스트"
    echo "                       - mixed: 읽기/쓰기 혼합 테스트 (70:30 비율)"
    echo "  -a PASSWORD         Redis 인증 비밀번호"
    echo "  -k KEY_PREFIX       테스트 키 접두사 (기본값: $KEY_PREFIX)"
    echo "  -i INTERVAL         모니터링 간격 (초) (기본값: $MONITOR_INTERVAL)"
    echo "  -o RESULT_FILE      결과 파일 (기본값: $RESULT_FILE)"
    echo "  --no-cleanup        테스트 후 생성된 데이터 유지"
    echo "  -v, --verbose       상세 출력 모드"
    echo "  -D, --debug         디버그 모드 (매우 상세한 출력)"
    echo "  --help              도움말 표시"
    echo ""
    echo "예제:"
    echo "  $0 -h redis.example.com -p 6380 -c 5000 -t 300"
    echo "  $0 -m read -r 10000 -t 120"
    echo "  $0 -m write -d 100 -c 500 -t 180 --no-cleanup"
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
                REQUESTS_PER_CLIENT="$2"
                shift 2
                ;;
            -d)
                DATA_SIZE_KB="$2"
                shift 2
                ;;
            -t)
                TEST_DURATION="$2"
                shift 2
                ;;
            -r)
                REQUEST_RATE="$2"
                shift 2
                ;;
            -m)
                TEST_MODE="$2"
                if [[ "$TEST_MODE" != "read" && "$TEST_MODE" != "write" && "$TEST_MODE" != "mixed" ]]; then
                    echo -e "${RED}오류: 테스트 모드는 read, write, mixed 중 하나여야 합니다.${NC}"
                    exit 1
                fi
                shift 2
                ;;
            -a)
                PASSWORD="$2"
                shift 2
                ;;
            -k)
                KEY_PREFIX="$2"
                shift 2
                ;;
            -i)
                MONITOR_INTERVAL="$2"
                shift 2
                ;;
            -o)
                RESULT_FILE="$2"
                shift 2
                ;;
            --no-cleanup)
                CLEANUP_AFTER_TEST=false
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -D|--debug)
                DEBUG=true
                VERBOSE=true
                shift
                ;;
            --help)
                print_banner
                print_usage
                exit 0
                ;;
            *)
                echo -e "${RED}오류: 알 수 없는 옵션 $1${NC}"
                print_usage
                exit 1
                ;;
        esac
    done
}

# Redis 연결 명령 생성
get_redis_cli_cmd() {
    local redis_cli_cmd="redis-cli -h $HOST -p $PORT"
    
    if [[ -n "$PASSWORD" ]]; then
        redis_cli_cmd="$redis_cli_cmd -a $PASSWORD"
    fi
    
    echo "$redis_cli_cmd"
}

# 시스템 리소스 확인
check_system_resources() {
    echo -e "${BLUE}시스템 리소스를 확인하는 중...${NC}"
    
    # 사용 가능한 메모리 확인 (KB 단위)
    local available_memory=$(free -k | awk '/^Mem:/ {print $7}')
    local estimated_memory=$((DATA_SIZE_KB * CLIENTS * 2))
    
    # 현재 열린 파일 수와 제한 확인
    local open_files=$(lsof | wc -l)
    local max_open_files=$(ulimit -n)
    
    # 충분하지 않은 파일 제한
    if [[ $CLIENTS -gt $((max_open_files / 2)) ]]; then
        echo -e "${YELLOW}경고: 클라이언트 수($CLIENTS)가 열린 파일 제한의 절반에 가깝습니다(최대: $max_open_files).${NC}"
        echo -e "${YELLOW}제안: 'ulimit -n <더 큰 값>'으로 제한을 늘리세요.${NC}"
        
        read -p "계속 진행하시겠습니까? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}테스트가 사용자에 의해 취소되었습니다.${NC}"
            exit 1
        fi
    fi
    
    # 메모리 사용량 경고
    if [[ $estimated_memory -gt $((available_memory * 70 / 100)) ]]; then
        echo -e "${YELLOW}경고: 예상 메모리 사용량(${estimated_memory}KB)이 사용 가능한 메모리(${available_memory}KB)의 70%를 초과합니다.${NC}"
        echo -e "${YELLOW}이로 인해 시스템 성능이 저하되거나 메모리 부족 오류가 발생할 수 있습니다.${NC}"
        
        read -p "계속 진행하시겠습니까? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}테스트가 사용자에 의해 취소되었습니다.${NC}"
            exit 1
        fi
    fi
    
    # Redis 서버 정보 확인
    local redis_cli_cmd=$(get_redis_cli_cmd)
    
    echo -e "${BLUE}Redis 서버 정보를 가져오는 중...${NC}"
    local redis_memory=$($redis_cli_cmd info memory | grep used_memory: | cut -d':' -f2)
    local redis_max_memory=$($redis_cli_cmd config get maxmemory | awk 'NR==2 {print $1}')
    local redis_clients=$($redis_cli_cmd info clients | grep connected_clients | cut -d':' -f2)
    local redis_max_clients=$($redis_cli_cmd config get maxclients | awk 'NR==2 {print $1}')
    
    # Redis 메모리 경고
    if [[ $redis_max_memory != "0" && $redis_memory -gt $((redis_max_memory * 70 / 100)) ]]; then
        echo -e "${YELLOW}경고: Redis가 이미 최대 메모리의 70% 이상을 사용하고 있습니다.${NC}"
    fi
    
    # Redis 클라이언트 연결 경고
    if [[ $((redis_clients + CLIENTS)) -gt $((redis_max_clients * 90 / 100)) ]]; then
        echo -e "${YELLOW}경고: 요청된 클라이언트 수는 Redis 최대 클라이언트 제한에 가깝습니다.${NC}"
        echo -e "${YELLOW}현재 연결: $redis_clients, 최대 연결: $redis_max_clients, 요청된 추가 연결: $CLIENTS${NC}"
    fi
    
    echo -e "${GREEN}리소스 확인 완료.${NC}"
}

# 데이터 생성
generate_initial_data() {
    echo -e "${BLUE}초기 테스트 데이터를 생성 중...${NC}"
    
    # 테스트 모드가 read 또는 mixed인 경우에만 초기 데이터 생성
    if [[ "$TEST_MODE" == "read" || "$TEST_MODE" == "mixed" ]]; then
        local redis_cli_cmd=$(get_redis_cli_cmd)
        local data_size_bytes=$((DATA_SIZE_KB * 1024))
        local data_chunk=$(head -c 1024 /dev/urandom | base64 | tr -d '\n')
        
        # 진행 상태 변수
        local total_keys=10000  # 읽기 테스트를 위한 충분한 키
        local progress=0
        
        echo -e "${BLUE}$total_keys 개의 키를 생성 중...${NC}"
        echo -ne "${YELLOW}[${NC}"
        
        # 파이프 모드로 한 번에 많은 명령 실행
        local pipe_cmds=""
        for ((i=1; i<=total_keys; i++)); do
            # 다양한 크기의 데이터 생성 (테스트 다양성을 위해)
            local actual_size=$((RANDOM % data_size_bytes + 1024))
            local repetitions=$((actual_size / 1024 + 1))
            
            # 파이프 명령에 추가
            pipe_cmds+="SET ${KEY_PREFIX}:$i $(printf '%s' "$data_chunk" | head -c $actual_size)\n"
            
            # 100개마다 전송
            if [[ $((i % 100)) -eq 0 || $i -eq $total_keys ]]; then
                echo -e "$pipe_cmds" | $redis_cli_cmd > /dev/null
                pipe_cmds=""
                
                # 진행 상태 업데이트
                progress=$((i * 100 / total_keys))
                if [[ $((i % (total_keys / 20))) -eq 0 || $i -eq $total_keys ]]; then
                    echo -ne "#"
                fi
            fi
        done
        
        echo -ne "${YELLOW}]${NC}"
        echo -e " ${GREEN}완료!${NC}"
        
        # TTL 설정 (테스트 후 자동 삭제를 위해)
        if [[ "$CLEANUP_AFTER_TEST" == "true" ]]; then
            echo -e "${BLUE}키 만료 시간 설정 중...${NC}"
            
            # 테스트 지속 시간 + 10분 (안전 마진)
            local expiry_seconds=$((TEST_DURATION + 600))
            
            # EXPIRE 명령을 샘플 키에 전송
            for ((i=1; i<=total_keys; i+=100)); do
                $redis_cli_cmd EXPIRE "${KEY_PREFIX}:$i" $expiry_seconds > /dev/null
            done
        fi
    else
        echo -e "${CYAN}쓰기 전용 테스트 - 초기 데이터 생성을 건너뜁니다.${NC}"
    fi
    
    echo -e "${GREEN}데이터 준비 완료.${NC}"
}

# 진행 상태 표시줄 업데이트
update_progress_bar() {
    local percent=$1
    local bar_size=40
    local filled=$((percent * bar_size / 100))
    local empty=$((bar_size - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' ' '
    printf "] %d%%" $percent
}

# 테스트 실행
run_load_test() {
    echo -e "\n${BLUE}====== LOAD TEST START ======${NC}"
    echo -e "${CYAN}설정:${NC}"
    echo -e "- 호스트: ${GREEN}$HOST:$PORT${NC}"
    echo -e "- 클라이언트 수: ${GREEN}$CLIENTS${NC}"
    echo -e "- 요청 수/클라이언트: ${GREEN}$REQUESTS_PER_CLIENT${NC}"
    echo -e "- 데이터 크기: ${GREEN}${DATA_SIZE_KB}KB${NC}"
    echo -e "- 테스트 시간: ${GREEN}${TEST_DURATION}초${NC}"
    echo -e "- 모드: ${GREEN}$TEST_MODE${NC}"
    if [[ "$TEST_MODE" == "mixed" ]]; then
        echo -e "  (읽기:쓰기 = ${GREEN}70:30${NC})"
    fi
    if [[ "$REQUEST_RATE" -eq 0 ]]; then
        echo -e "- 요청 비율: ${GREEN}무제한${NC}"
    else
        echo -e "- 요청 비율: ${GREEN}$REQUEST_RATE RPS${NC}"
    fi
    echo

    # 결과 파일 초기화
    echo "====== REDIS LOAD TEST RESULTS ======" > "$RESULT_FILE"
    echo "시작 시간: $(date)" >> "$RESULT_FILE"
    echo "설정: $HOST:$PORT, $CLIENTS 클라이언트, ${DATA_SIZE_KB}KB 데이터, $TEST_DURATION 초, $TEST_MODE 모드" >> "$RESULT_FILE"
    echo "----------------------------------------" >> "$RESULT_FILE"
    
    # 임시 파일 생성
    local temp_dir=$(mktemp -d)
    local latency_file="$temp_dir/latency.log"
    local throughput_file="$temp_dir/throughput.log"
    local errors_file="$temp_dir/errors.log"
    
    # 시작 시간 기록
    start_time=$(date +%s)
    local end_time=$((start_time + TEST_DURATION))
    
    # 진행 상태 표시
    echo -e "${YELLOW}진행 중...${NC}"
    update_progress_bar 0
    
    # 모니터링 백그라운드 프로세스 시작
    monitor_redis_performance "$throughput_file" &
    local monitor_pid=$!
    
    # 워커 프로세스 시작
    local worker_pids=()
    for ((i=1; i<=CLIENTS; i+=$((CLIENTS/10 + 1)))); do
        local worker_end=$((i + CLIENTS/10))
        if [[ $worker_end -gt $CLIENTS ]]; then
            worker_end=$CLIENTS
        fi
        
        run_worker_processes $i $worker_end "$latency_file" "$errors_file" &
        worker_pids+=($!)
    done
    
    # 테스트 지속 시간 측정
    while [[ $(date +%s) -lt $end_time && "$should_stop" == "false" ]]; do
        # 진행 상태 계산
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local progress=$((elapsed * 100 / TEST_DURATION))
        
        # 진행 상태 표시 업데이트
        update_progress_bar $progress
        
        # 잠시 대기
        sleep 1
    done
    
    # 테스트 완료 표시
    update_progress_bar 100
    echo -e "\n\n${GREEN}테스트 실행 완료!${NC}"
    
    # 워커 프로세스 종료 대기
    wait_for_test_completion
    
    # 모니터링 프로세스 종료
    kill $monitor_pid 2>/dev/null
    
    # 결과 분석
    analyze_results "$latency_file" "$throughput_file" "$errors_file"
    
    # 임시 파일 제거
    rm -rf "$temp_dir"
}

# Redis 성능 모니터링
monitor_redis_performance() {
    local throughput_file=$1
    local redis_cli_cmd=$(get_redis_cli_cmd)
    
    # 사전 정보 수집
    local initial_total_commands=$($redis_cli_cmd info stats | grep total_commands_processed | cut -d':' -f2)
    local initial_time=$(date +%s)
    
    while true; do
        sleep $MONITOR_INTERVAL
        
        # 현재 정보 수집
        local current_total_commands=$($redis_cli_cmd info stats | grep total_commands_processed | cut -d':' -f2)
        local current_time=$(date +%s)
        local time_diff=$((current_time - initial_time))
        
        if [[ $time_diff -gt 0 ]]; then
            local commands_diff=$((current_total_commands - initial_total_commands))
            local throughput=$((commands_diff / time_diff))
            
            # 메모리 사용량 확인
            local used_memory=$($redis_cli_cmd info memory | grep used_memory_human | cut -d':' -f2)
            local mem_fragmentation=$($redis_cli_cmd info memory | grep mem_fragmentation_ratio | cut -d':' -f2)
            
            # 연결된 클라이언트 수
            local connected_clients=$($redis_cli_cmd info clients | grep connected_clients | cut -d':' -f2)
            
            # 결과 저장
            echo "$(date +%s),$throughput,$used_memory,$mem_fragmentation,$connected_clients" >> "$throughput_file"
            
            # 디버그 모드라면 출력
            if [[ "$DEBUG" == "true" ]]; then
                echo -e "\n${CYAN}[DEBUG] 처리량: ${throughput} ops/sec, 메모리: ${used_memory}, 프래그먼테이션: ${mem_fragmentation}, 클라이언트: ${connected_clients}${NC}"
            fi
        fi
        
        # 초기값 업데이트
        initial_total_commands=$current_total_commands
        initial_time=$current_time
    done
}

# 워커 프로세스 실행
run_worker_processes() {
    local start_client=$1
    local end_client=$2
    local latency_file=$3
    local errors_file=$4
    
    local redis_cli_cmd=$(get_redis_cli_cmd)
    local data_size_bytes=$((DATA_SIZE_KB * 1024))
    local data=$(head -c $data_size_bytes /dev/urandom | base64 | tr -d '\n' | head -c $data_size_bytes)
    
    # 각 클라이언트에 대한 요청 실행
    for ((client_id=start_client; client_id<=end_client; client_id++)); do
        # 클라이언트별 요청 횟수
        for ((req=1; req<=REQUESTS_PER_CLIENT; req++)); do
            # 테스트 중지 확인
            if [[ "$should_stop" == "true" || $(date +%s) -gt $((start_time + TEST_DURATION)) ]]; then
                return
            fi
            
            # 속도 제한이 설정된 경우 지연 처리
            if [[ $REQUEST_RATE -gt 0 ]]; then
                local sleep_time=$(echo "scale=6; 1/$REQUEST_RATE" | bc)
                sleep $sleep_time
            fi
            
            # 키 및 명령 선택
            local key="${KEY_PREFIX}:$((RANDOM % 10000 + 1))"
            local start_time_ms=$(date +%s%3N)
            local success=1
            local command=""
            
            # 테스트 모드에 따라 명령 선택
            if [[ "$TEST_MODE" == "read" ]]; then
                command="GET $key"
            elif [[ "$TEST_MODE" == "write" ]]; then
                command="SET $key $data"
            else  # mixed
                # 70% 읽기, 30% 쓰기
                if [[ $((RANDOM % 10)) -lt 7 ]]; then
                    command="GET $key"
                else
                    command="SET $key $data"
                fi
            fi
            
            # 명령 실행 및 응답 시간 측정
            if ! $redis_cli_cmd $command > /dev/null 2>&1; then
                success=0
                echo "$(date +%s),$client_id,$command,실패" >> "$errors_file"
            fi
            
            local end_time_ms=$(date +%s%3N)
            local latency=$((end_time_ms - start_time_ms))
            
            # 응답 시간 기록
            echo "$(date +%s),$client_id,$command,$latency,$success" >> "$latency_file"
        done
    done
}

# 테스트 완료 대기
wait_for_test_completion() {
    echo -e "${YELLOW}모든 테스트 작업 완료 대기 중...${NC}"
    wait
    echo -e "${GREEN}모든 프로세스가 완료되었습니다.${NC}"
}

# 결과 분석
analyze_results() {
    local latency_file=$1
    local throughput_file=$2
    local errors_file=$3
    
    echo -e "${BLUE}결과 분석 중...${NC}"
    
    # 테스트 요약
    local end_time=$(date +%s)
    local test_duration=$((end_time - start_time))
    
    echo -e "\n${CYAN}====== 결과 요약 ======${NC}" | tee -a "$RESULT_FILE"
    
    # 총 요청 수
    local total_requests=$(wc -l < "$latency_file")
    echo -e "- 총 처리된 요청: ${GREEN}$(printf "%'d" $total_requests)${NC}" | tee -a "$RESULT_FILE"
    
    # 응답 시간 분석
    if [[ -s "$latency_file" ]]; then
        local avg_latency=$(awk -F',' '{sum+=$4} END {print sum/NR}' "$latency_file")
        local max_latency=$(awk -F',' '{if($4>max) max=$4} END {print max}' "$latency_file")
        local min_latency=$(awk -F',' '{if(NR==1 || $4<min) min=$4} END {print min}' "$latency_file")
        local p99_latency=$(awk -F',' '{print $4}' "$latency_file" | sort -n | awk '{a[NR]=$1} END {print a[int(NR*0.99)]}')
        
        echo -e "- 평균 응답 시간: ${GREEN}${avg_latency}ms${NC}" | tee -a "$RESULT_FILE"
        echo -e "- 최대 응답 시간: ${GREEN}${max_latency}ms${NC}" | tee -a "$RESULT_FILE"
        echo -e "- 최소 응답 시간: ${GREEN}${min_latency}ms${NC}" | tee -a "$RESULT_FILE"
        echo -e "- 99% 응답 시간: ${GREEN}${p99_latency}ms${NC}" | tee -a "$RESULT_FILE"
    fi
    
    # 처리량 분석
    if [[ -s "$throughput_file" ]]; then
        local avg_throughput=$(awk -F',' '{sum+=$2} END {print sum/NR}' "$throughput_file")
        local max_throughput=$(awk -F',' '{if($2>max) max=$2} END {print max}' "$throughput_file")
        
        echo -e "- 평균 처리량: ${GREEN}$(printf "%.2f" $avg_throughput) ops/sec${NC}" | tee -a "$RESULT_FILE"
        echo -e "- 최대 처리량: ${GREEN}$max_throughput ops/sec${NC}" | tee -a "$RESULT_FILE"
        
        # 메모리 사용량 분석
        local initial_memory=$(awk -F',' 'NR==1{print $3}' "$throughput_file")
        local final_memory=$(awk -F',' 'END{print $3}' "$throughput_file")
        
        echo -e "- 초기 메모리 사용량: ${GREEN}$initial_memory${NC}" | tee -a "$RESULT_FILE"
        echo -e "- 최종 메모리 사용량: ${GREEN}$final_memory${NC}" | tee -a "$RESULT_FILE"
        
        # 프래그먼테이션 비율
        local final_fragmentation=$(awk -F',' 'END{print $4}' "$throughput_file")
        echo -e "- 메모리 프래그먼테이션 비율: ${GREEN}$final_fragmentation${NC}" | tee -a "$RESULT_FILE"
    fi
    
    # 오류 분석
    if [[ -s "$errors_file" ]]; then
        local error_count=$(wc -l < "$errors_file")
        local error_rate=$(echo "scale=6; $error_count / $total_requests * 100" | bc)
        
        echo -e "- 실패한 요청: ${RED}$error_count ($(printf "%.5f" $error_rate)%)${NC}" | tee -a "$RESULT_FILE"
        
        # 오류 유형 분석
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "\n${CYAN}== 오류 유형 분석 ==${NC}" | tee -a "$RESULT_FILE"
            
            # 명령별 오류 개수
            echo "명령별 오류:" | tee -a "$RESULT_FILE"
            awk -F',' '{print $3}' "$errors_file" | sort | uniq -c | sort -nr | head -5 | \
                while read count cmd; do
                    echo "  - $cmd: $count" | tee -a "$RESULT_FILE"
                done
        fi
    else
        echo -e "- 실패한 요청: ${GREEN}0 (0.000%)${NC}" | tee -a "$RESULT_FILE"
    fi
    
    # 성능 저하 분석
    if [[ -s "$throughput_file" && -s "$latency_file" ]]; then
        echo -e "\n${CYAN}== 성능 저하 분석 ==${NC}" | tee -a "$RESULT_FILE"
        
        # 테스트 시간을 5개 구간으로 나눔
        local segment_size=$((TEST_DURATION / 5))
        if [[ $segment_size -lt 5 ]]; then
            segment_size=5
        fi
        
        # 첫 번째 구간과 마지막 구간의 성능 비교
        local first_segment_start=$start_time
        local first_segment_end=$((start_time + segment_size))
        local last_segment_start=$((end_time - segment_size))
        local last_segment_end=$end_time
        
        # 응답 시간 변화 분석
        local first_segment_latency=$(awk -F',' -v start="$first_segment_start" -v end="$first_segment_end" \
            '$1 >= start && $1 <= end {sum+=$4; count++} END {if(count>0) print sum/count; else print 0}' "$latency_file")
        local last_segment_latency=$(awk -F',' -v start="$last_segment_start" -v end="$last_segment_end" \
            '$1 >= start && $1 <= end {sum+=$4; count++} END {if(count>0) print sum/count; else print 0}' "$latency_file")
        
        if [[ $first_segment_latency != "0" && $last_segment_latency != "0" ]]; then
            local latency_increase=$(echo "scale=2; ($last_segment_latency - $first_segment_latency) / $first_segment_latency * 100" | bc)
            
            if [[ $(echo "$latency_increase > 10" | bc) -eq 1 ]]; then
                echo -e "- 테스트 진행에 따른 응답 시간 증가: ${RED}$latency_increase%${NC}" | tee -a "$RESULT_FILE"
            elif [[ $(echo "$latency_increase > 0" | bc) -eq 1 ]]; then
                echo -e "- 테스트 진행에 따른 응답 시간 증가: ${YELLOW}$latency_increase%${NC}" | tee -a "$RESULT_FILE"
            else
                echo -e "- 테스트 진행에 따른 응답 시간 변화: ${GREEN}$latency_increase%${NC}" | tee -a "$RESULT_FILE"
            fi
        fi
        
        # 처리량 변화 분석
        local first_segment_throughput=$(awk -F',' -v start="$first_segment_start" -v end="$first_segment_end" \
            '$1 >= start && $1 <= end {sum+=$2; count++} END {if(count>0) print sum/count; else print 0}' "$throughput_file")
        local last_segment_throughput=$(awk -F',' -v start="$last_segment_start" -v end="$last_segment_end" \
            '$1 >= start && $1 <= end {sum+=$2; count++} END {if(count>0) print sum/count; else print 0}' "$throughput_file")
        
        if [[ $first_segment_throughput != "0" && $last_segment_throughput != "0" ]]; then
            local throughput_decrease=$(echo "scale=2; ($first_segment_throughput - $last_segment_throughput) / $first_segment_throughput * 100" | bc)
            
            if [[ $(echo "$throughput_decrease > 10" | bc) -eq 1 ]]; then
                echo -e "- 테스트 진행에 따른 처리량 감소: ${RED}$throughput_decrease%${NC}" | tee -a "$RESULT_FILE"
            elif [[ $(echo "$throughput_decrease > 0" | bc) -eq 1 ]]; then
                echo -e "- 테스트 진행에 따른 처리량 감소: ${YELLOW}$throughput_decrease%${NC}" | tee -a "$RESULT_FILE"
            else
                echo -e "- 테스트 진행에 따른 처리량 변화: ${GREEN}$throughput_decrease%${NC}" | tee -a "$RESULT_FILE"
            fi
        fi
        
        # 구간별 성능 저하 시점 분석
        echo -e "\n- 성능 저하 시점:" | tee -a "$RESULT_FILE"
        for ((seg=0; seg<5; seg++)); do
            local seg_start=$((start_time + seg * segment_size))
            local seg_end=$((seg_start + segment_size))
            if [[ $seg_end -gt $end_time ]]; then
                seg_end=$end_time
            fi
            
            local seg_latency=$(awk -F',' -v start="$seg_start" -v end="$seg_end" \
                '$1 >= start && $1 <= end {sum+=$4; count++} END {if(count>0) print sum/count; else print 0}' "$latency_file")
            
            if [[ $seg -gt 0 && $seg_latency != "0" && $first_segment_latency != "0" ]]; then
                local seg_increase=$(echo "scale=2; ($seg_latency - $first_segment_latency) / $first_segment_latency * 100" | bc)
                
                local time_point=$((seg * segment_size))
                if [[ $(echo "$seg_increase > 25" | bc) -eq 1 ]]; then
                    echo -e "  ${time_point}초 후 응답 시간 ${RED}$seg_increase% 증가${NC}" | tee -a "$RESULT_FILE"
                elif [[ $(echo "$seg_increase > 10" | bc) -eq 1 ]]; then
                    echo -e "  ${time_point}초 후 응답 시간 ${YELLOW}$seg_increase% 증가${NC}" | tee -a "$RESULT_FILE"
                fi
            fi
        done
    fi

    echo -e "\n${CYAN}== 권장 사항 ==${NC}" | tee -a "$RESULT_FILE"
    
    # 권장 사항 제시
    local recommendations=0
    
    # 메모리 관련 권장 사항
    if [[ -s "$throughput_file" ]]; then
        local final_fragmentation=$(awk -F',' 'END{print $4}' "$throughput_file")
        
        if [[ $(echo "$final_fragmentation > 1.5" | bc) -eq 1 ]]; then
            echo -e "- ${RED}메모리 프래그먼테이션이 높습니다 ($final_fragmentation). Redis 재시작을 고려하세요.${NC}" | tee -a "$RESULT_FILE"
            recommendations=$((recommendations + 1))
        fi
        
        # 메모리 증가율 확인
        local initial_memory_str=$(awk -F',' 'NR==1{print $3}' "$throughput_file")
        local final_memory_str=$(awk -F',' 'END{print $3}' "$throughput_file")
        
        # 문자열로부터 숫자 추출 (예: "1.20M" -> 1.20)
        local initial_memory_val=$(echo "$initial_memory_str" | sed 's/[^0-9.]//g')
        local final_memory_val=$(echo "$final_memory_str" | sed 's/[^0-9.]//g')
        local memory_unit=$(echo "$final_memory_str" | sed 's/[0-9.]//g')
        
        if [[ $initial_memory_val != "" && $final_memory_val != "" && $(echo "$final_memory_val > $initial_memory_val * 1.3" | bc) -eq 1 ]]; then
            echo -e "- ${YELLOW}테스트 중 메모리 사용량이 30% 이상 증가했습니다. 메모리 설정과 키 만료 정책을 확인하세요.${NC}" | tee -a "$RESULT_FILE"
            recommendations=$((recommendations + 1))
        fi
    fi
    
    # 응답 시간 관련 권장 사항
    if [[ -s "$latency_file" ]]; then
        local max_latency=$(awk -F',' '{if($4>max) max=$4} END {print max}' "$latency_file")
        local p99_latency=$(awk -F',' '{print $4}' "$latency_file" | sort -n | awk '{a[NR]=$1} END {print a[int(NR*0.99)]}')
        
        if [[ $max_latency -gt 1000 ]]; then
            echo -e "- ${RED}최대 응답 시간이 1초를 초과합니다. 네트워크 지연이나 Redis 서버 부하를 확인하세요.${NC}" | tee -a "$RESULT_FILE"
            recommendations=$((recommendations + 1))
        fi
        
        if [[ $p99_latency -gt 100 ]]; then
            echo -e "- ${YELLOW}99% 응답 시간이 100ms를 초과합니다. 연결 풀링 또는 Redis 서버 리소스 증가를 고려하세요.${NC}" | tee -a "$RESULT_FILE"
            recommendations=$((recommendations + 1))
        fi
    fi
    
    # 오류 관련 권장 사항
    if [[ -s "$errors_file" ]]; then
        local error_count=$(wc -l < "$errors_file")
        local error_rate=$(echo "scale=6; $error_count / $total_requests * 100" | bc)
        
        if [[ $(echo "$error_rate > 0.1" | bc) -eq 1 ]]; then
            echo -e "- ${RED}오류율이 0.1%를 초과합니다. 네트워크 연결, 타임아웃 설정, Redis 최대 클라이언트 수를 확인하세요.${NC}" | tee -a "$RESULT_FILE"
            recommendations=$((recommendations + 1))
        fi
    fi
    
    # 처리량 관련 권장 사항
    if [[ -s "$throughput_file" && -s "$latency_file" ]]; then
        local first_segment_throughput=$(awk -F',' -v start="$first_segment_start" -v end="$first_segment_end" \
            '$1 >= start && $1 <= end {sum+=$2; count++} END {if(count>0) print sum/count; else print 0}' "$throughput_file")
        local last_segment_throughput=$(awk -F',' -v start="$last_segment_start" -v end="$last_segment_end" \
            '$1 >= start && $1 <= end {sum+=$2; count++} END {if(count>0) print sum/count; else print 0}' "$throughput_file")
        
        if [[ $first_segment_throughput != "0" && $last_segment_throughput != "0" \
            && $(echo "$last_segment_throughput < $first_segment_throughput * 0.7" | bc) -eq 1 ]]; then
            echo -e "- ${RED}테스트 진행에 따라 처리량이 30% 이상 감소했습니다. Redis 서버의 성능 튜닝이 필요합니다.${NC}" | tee -a "$RESULT_FILE"
            echo -e "  - maxclients 설정 증가 고려" | tee -a "$RESULT_FILE"
            echo -e "  - IO 스레드 수 증가 고려" | tee -a "$RESULT_FILE"
            echo -e "  - Redis 클러스터 고려" | tee -a "$RESULT_FILE"
            recommendations=$((recommendations + 1))
        fi
    fi
    
    # 권장 사항이 없는 경우
    if [[ $recommendations -eq 0 ]]; then
        echo -e "- ${GREEN}Redis 서버가 테스트 부하에서 안정적으로 동작합니다. 권장 사항이 없습니다.${NC}" | tee -a "$RESULT_FILE"
    fi
    
    echo -e "\n${GREEN}결과가 $RESULT_FILE 파일에 저장되었습니다.${NC}"
}

# 테스트 후 정리
cleanup_test() {
    if [[ "$CLEANUP_AFTER_TEST" != "true" ]]; then
        echo -e "${YELLOW}생성된 테스트 데이터는 유지됩니다 (--no-cleanup 옵션 사용).${NC}"
        return
    fi
    
    echo -e "${BLUE}테스트 데이터 정리 중...${NC}"
    local redis_cli_cmd=$(get_redis_cli_cmd)
    
    # 모든 테스트 키 제거
    local keys_count=$($redis_cli_cmd keys "${KEY_PREFIX}:*" | wc -l)
    
    if [[ $keys_count -gt 0 ]]; then
        echo -e "${YELLOW}${keys_count}개의 테스트 키를 제거합니다...${NC}"
        
        # 많은 키를 한 번에 삭제하기 위해 SCAN 사용
        local cursor=0
        local deleted=0
        
        while true; do
            local scan_result=$($redis_cli_cmd SCAN $cursor MATCH "${KEY_PREFIX}:*" COUNT 1000)
            cursor=$(echo "$scan_result" | head -1)
            local keys=$(echo "$scan_result" | tail -n +2)
            
            if [[ -n "$keys" ]]; then
                echo -e "$keys" | xargs $redis_cli_cmd DEL > /dev/null
                deleted=$((deleted + $(echo "$keys" | wc -l)))
                echo -ne "\r${deleted}개 키 제거됨..."
            fi
            
            if [[ "$cursor" == "0" ]]; then
                break
            fi
        done
        
        echo -e "\n${GREEN}테스트 데이터 정리 완료.${NC}"
    else
        echo -e "${GREEN}제거할 테스트 데이터가 없습니다.${NC}"
    fi
}

# 주요 실행 함수
main() {
    print_banner
    parse_parameters "$@"
    
    # redis-cli 확인
    if ! command -v redis-cli &> /dev/null; then
        echo -e "${RED}오류: redis-cli 명령어를 찾을 수 없습니다.${NC}"
        echo -e "${YELLOW}Redis 클라이언트가 설치되어 있는지 확인하세요.${NC}"
        exit 1
    fi
    
    # 시스템 리소스 확인
    check_system_resources
    
    # 초기 데이터 생성
    generate_initial_data
    
    # 테스트 실행
    run_load_test
    
    # 정리
    cleanup_test
    
    echo -e "\n${GREEN}테스트가 완료되었습니다.${NC}"
    echo -e "${CYAN}자세한 결과는 $RESULT_FILE 파일을 참조하세요.${NC}"
}

# 스크립트 실행
main "$@"