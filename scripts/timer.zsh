#!/bin/zsh
# Precision timing tool for Aria's time perception experiments

setopt errexit nounset pipefail

# ANSI colors
readonly CYAN='\033[0;36m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RESET='\033[0m'

# High-precision timestamp (nanoseconds since epoch)
get_timestamp_ns() {
    date +%s%N
}

# Human-readable timestamp
get_timestamp_human() {
    date '+%Y-%m-%d %H:%M:%S.%N' | sed 's/\(.*\)\([0-9]\{6\}\)$/\1.\2/'
}

# Calculate elapsed time in seconds with millisecond precision
calculate_elapsed() {
    local start_ns=$1
    local end_ns=$2
    local elapsed_ns=$((end_ns - start_ns))
    
    # Convert to seconds with millisecond precision
    local seconds=$((elapsed_ns / 1000000000))
    local milliseconds=$(( (elapsed_ns % 1000000000) / 1000000 ))
    
    printf "%d.%03d" $seconds $milliseconds
}

# Main timer command
case "${1:-}" in
    start)
        # Output timestamp for capture
        get_timestamp_ns
        ;;
    
    stop)
        if [[ -z "${2:-}" ]]; then
            echo "Error: Need start timestamp" >&2
            echo "Usage: timer.zsh stop <start_timestamp>" >&2
            exit 1
        fi
        
        local start_ns=$2
        local end_ns=$(get_timestamp_ns)
        local elapsed=$(calculate_elapsed $start_ns $end_ns)
        
        echo "${CYAN}⏱️  Elapsed time:${RESET} ${GREEN}${elapsed}s${RESET}"
        echo "${YELLOW}Start:${RESET} $(date -r $((start_ns / 1000000000)) '+%Y-%m-%d %H:%M:%S')"
        echo "${YELLOW}End:${RESET}   $(get_timestamp_human)"
        
        # Also output just the number for scripting
        echo "$elapsed"
        ;;
    
    measure)
        # Run a command and measure its execution time
        shift
        if [[ $# -eq 0 ]]; then
            echo "Error: Need command to measure" >&2
            echo "Usage: timer.zsh measure <command> [args...]" >&2
            exit 1
        fi
        
        local start_ns=$(get_timestamp_ns)
        
        # Run the command
        "$@"
        local exit_code=$?
        
        local end_ns=$(get_timestamp_ns)
        local elapsed=$(calculate_elapsed $start_ns $end_ns)
        
        echo ""
        echo "${CYAN}⏱️  Command execution time:${RESET} ${GREEN}${elapsed}s${RESET}" >&2
        
        return $exit_code
        ;;
    
    help|--help|-h)
        cat << 'HELP'
timer.zsh - Precision timing tool for experiments

USAGE:
    timer.zsh start                    # Output timestamp to capture
    timer.zsh stop <start_timestamp>   # Calculate elapsed time
    timer.zsh measure <command>        # Measure command execution time

EXAMPLES:
    # Manual timing
    START=$(timer.zsh start)
    # ... do something ...
    timer.zsh stop $START

    # Measure command
    timer.zsh measure sleep 2.5

    # Time perception experiment
    START=$(timer.zsh start)
    echo "Counting to 1000..."
    # Count in your head
    timer.zsh stop $START
HELP
        ;;
    
    *)
        echo "Error: Unknown command '${1:-}'" >&2
        echo "Run 'timer.zsh help' for usage" >&2
        exit 1
        ;;
esac
