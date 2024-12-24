#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
set -o xtrace

# Default values
RUNS=2
MODE="robocni"

# Load environment variables if the file exists
[ -f /home/vagrant/.bashrc.d/ollama.sh ] && source /home/vagrant/.bashrc.d/ollama.sh

usage() {
    cat <<EOF
Usage: $0 [options]
Options:
  -h                Show this help message
  -c                Run in robocni mode (default)
  -l                Run in looprobocni mode
  -r <runs>         Number of runs for looprobocni (default: 2)
EOF
}

# Parse command-line arguments
while getopts "hclr:" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        c)
            MODE="robocni"
            ;;
        l)
            MODE="looprobocni"
            ;;
        r)
            RUNS=$OPTARG
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# Execute the selected mode
if [[ "$MODE" == "robocni" ]]; then
    robocni -debug -json -host "$OHOST" -model "$MODEL" -port "$OPORT" "give me a macvlan CNI config with ipam on 10.0.2.0/24" && echo
elif [[ "$MODE" == "looprobocni" ]]; then
    time looprobocni -host "$OHOST" -model "$MODEL" -introspect -port "$OPORT" -promptfile /tmp/prompts.txt --runs "$RUNS"
else
    echo "Invalid mode: $MODE" >&2
    usage
    exit 1
fi
