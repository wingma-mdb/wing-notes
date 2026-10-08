#!/usr/bin/env bash
set -euo pipefail

#if [[ $# -ne 1 || ! -f "$1" ]]; then
#  echo "Usage: $0 /path/to/configdump.tgz" >&2
#  exit 2
#fi

#DUMP="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
#SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#ANALYZER="$SCRIPT_DIR/config_analyzer.py"


if [[ $# -ne 2 || ! -f "$1" || ! -f "$2/config_analyzer.py" ]]; then
  echo "Usage: $0 /path/to/configdump.tgz /path/to/sharding-analyzer" >&2
  exit 2
fi

DUMP="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
REPO_DIR="$(cd "$2" && pwd)"
ANALYZER="$REPO_DIR/config_analyzer.py"






DB="sample_config"
PORT=27017
URI="mongodb://127.0.0.1:$PORT"
DBPATH="$HOME/data/config-analyzer-6.0"
LOG="$DBPATH/mongod.log"

for cmd in mongod mongorestore mongosh python3; do
  command -v "$cmd" >/dev/null || {
    echo "Required command not found: $cmd" >&2
    exit 1
  }
done

[[ -f "$ANALYZER" ]] || {
  echo "Can't find config_analyzer.py. Save this script in the repo root." >&2
  exit 1
}

VERSION="$(mongod --version | awk '/db version/ {print $3; exit}')"
case "$VERSION" in
  v6.*) ;;
  *)
    echo "Expected mongod 6.x, found $VERSION. Switch to a 6.x binary and retry." >&2
    exit 1
    ;;
esac

mkdir -p "$DBPATH"
mongod --dbpath "$DBPATH" --port "$PORT" --bind_ip 127.0.0.1 >>"$LOG" 2>&1 &
MONGOD_PID=$!

cleanup() {
  if kill -0 "$MONGOD_PID" 2>/dev/null; then
    kill -TERM "$MONGOD_PID" 2>/dev/null || true
    wait "$MONGOD_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

READY=0
for ((i=0; i<60; i++)); do
  if mongosh --quiet "$URI/admin" \
      --eval 'db.runCommand({ping: 1}).ok' >/dev/null 2>&1; then
    READY=1
    break
  fi
  if ! kill -0 "$MONGOD_PID" 2>/dev/null; then
    break
  fi
  sleep 1
done

if [[ "$READY" -ne 1 ]]; then
  echo "mongod did not start. Recent log output:" >&2
  tail -30 "$LOG" >&2
  exit 1
fi

#mongorestore --uri="$URI" \
#  --gzip \
#  --archive="$DUMP" \
#  --drop \
#  --nsFrom="config.*" \
#  --nsTo="$DB.*" \
#  --nsExclude="config.system.preimages"

mongorestore --uri="$URI" \
  --gzip \
  --archive="$DUMP" \
  --drop \
  --nsFrom="config.*" \
  --nsTo="$DB.*" \
  --nsExclude="config.system.*"


# cd "$SCRIPT_DIR"
cd "$REPO_DIR"
python3 "$ANALYZER" -u "$URI" -d "$DB"

