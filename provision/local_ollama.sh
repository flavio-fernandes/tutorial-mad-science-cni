[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
# set -o xtrace

# https://ollama.com/download
curl -fsSL https://ollama.com/install.sh | sh

