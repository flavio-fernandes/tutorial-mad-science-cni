[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
# set -o xtrace

# Set environment variable
export OLLAMA_HOST="0.0.0.0:8080"

# Create a tmux session for `ollama serve`
tmux new-session -d -s ollama-serve "ollama serve"

# Create a tmux session for `ollama run`
tmux new-session -d -s ollama-run "ollama run codegemma:7b"

echo "Tmux sessions created:"
echo "  - ollama-serve: Running 'ollama serve'"
echo "  - ollama-run: Running 'ollama run codegemma:7b'"

# Instructions to attach to sessions
echo "Use 'tmux attach -t ollama-serve' or 'tmux attach -t ollama-run' to view the sessions."

# Create env variables to make it easy to interact with running ollama
CONFIG="/home/vagrant/.bashrc.d/ollama.sh"
mkdir -p $(dirname $CONFIG)
cat << EOT > $CONFIG
export OLLAMA_HOST=0.0.0.0:8080

export OHOST=0.0.0.0
export OPORT=8080
export MODEL=codegemma:7b
EOT

