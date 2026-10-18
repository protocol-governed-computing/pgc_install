#!/usr/bin/env bash
#
# pgc-demo — play the Collatz game, then look inside it.
#
#   pgc-demo.sh collatz                  the game in your browser
#   pgc-demo.sh collatz N                one game in the terminal, through the same entrance
#   pgc-demo.sh collatz set-limit N      change the entrance's limit by its declaration, and rebuild
#   pgc-demo.sh collatz reset            go back to the published snapshot
#   pgc-demo.sh collatz tamper           edit a copy of the sealed snapshot and try to start it
#   pgc-demo.sh inspect                  the game's map and declarations in your browser
#   pgc-demo.sh inspect show FQDN        one declaration, e.g. workload::TI_COLLATZ_COMPUTE_V0
#   pgc-demo.sh inspect code MODULE      the Python module a transform names
#   pgc-demo.sh where                    open the folder holding every run's trace
#
# This script adds no behavior. Every step runs a command the PGC install provides —
# `pgc_transport`, `protocol_compiler`, `protocol_runtime`, `snapshot_assembler`, `si` — and the
# web pages are the clients the PGC repositories publish. Read on to see exactly what each step
# runs. Install the commands first:
#
#   pipx install --include-deps protocol-governed-computing
#
# On first use it downloads, from GitHub, the release it names below: the sealed snapshot, the
# two web clients, the snapshot profiles, and the declaration sources `set-limit` recompiles.
# Everything it writes stays under ~/pgc-demo (or $PGC_DEMO_HOME).
#
# To run against a development workspace instead of a release, set PGC_DEMO_WORKSPACE to the
# directory holding the PGC repositories. Their working trees are used as they stand, and the
# snapshot is the workspace's working build. Set PGC_DEMO_REF to name the copy (e.g. dev-18).
set -euo pipefail

REF="${PGC_DEMO_REF:-v6}"
ORG="https://github.com/protocol-governed-computing"
DEMO_HOME="${PGC_DEMO_HOME:-$HOME/pgc-demo}"
DATA="$DEMO_HOME/${REF//\//-}"
PROFILE="GOVERNANCE_SURFACE_PROFILE_V0"
ENTRANCE="workload::TI_COLLATZ_COMPUTE_V0"
WORKFLOW="workload::WF_COLLATZ_CONJECTURE_V0"
REPOS="pgc_release .github conformance_workloads snapshot_inspector software_governance"

usage() { sed -n '5,13s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; exit 2; }

need() {
  command -v "$1" >/dev/null || {
    echo "pgc-demo: '$1' is not on your PATH. Install the PGC commands with:" >&2
    echo "  pipx install --include-deps protocol-governed-computing" >&2
    exit 2; }
}

# The interpreter the PGC packages are installed into: the one running `pgc_transport`.
python_of_install() {
  if [ -n "${PGC_DEMO_PYTHON:-}" ]; then echo "$PGC_DEMO_PYTHON"; return; fi
  need pgc_transport
  head -1 "$(command -v pgc_transport)" | sed 's/^#![[:space:]]*//'
}

# ── the release's files, fetched once ────────────────────────────────────────────────────────
fetch() {
  [ -f "$DATA/.complete" ] && return 0
  rm -rf "$DATA"; mkdir -p "$DATA/repos"
  echo "Fetching $REF (first run only) into $DATA" >&2
  for repo in $REPOS; do
    mkdir -p "$DATA/repos/$repo"
    if [ -n "${PGC_DEMO_WORKSPACE:-}" ]; then
      [ "$repo" = pgc_release ] && continue
      # The working tree as git sees it: tracked and new files, nothing ignored.
      (cd "$PGC_DEMO_WORKSPACE/$repo" && git ls-files -z --cached --others --exclude-standard |
        xargs -0 tar -c 2>/dev/null) | tar -x -C "$DATA/repos/$repo"
    else
      curl -fsSL "$ORG/$repo/archive/refs/tags/$REF.tar.gz" | tar -xz -C "$DATA/repos/$repo" --strip-components 1
    fi
    echo "  $repo" >&2
  done
  if [ -n "${PGC_DEMO_WORKSPACE:-}" ]; then
    cp -R "$PGC_DEMO_WORKSPACE/snapshot" "$DATA/repos/pgc_release/snapshot"
    echo "  snapshot (the workspace's working build)" >&2
  fi
  touch "$DATA/.complete"
}

paths() {
  fetch
  PUBLISHED="$DATA/repos/pgc_release/snapshot"
  COLLATZ_CLIENT="$DATA/repos/conformance_workloads/workloads/collatz/client"
  INSPECTION_CLIENT="$DATA/repos/snapshot_inspector/client"
  export PGC_SNAPSHOT_PROFILES="$DATA/repos/.github/snapshot_profiles"
  export PGC_DATA_ROOT="$DEMO_HOME"
}

# The snapshot every step uses: the one `set-limit` built last, or else the published one.
snapshot() {
  if [ -f "$DEMO_HOME/active" ]; then cat "$DEMO_HOME/active"; else echo "$PUBLISHED"; fi
}
snapshot_id() { sed -n 's/.*"snapshot_id": *"\([0-9a-f]*\)".*/\1/p' "$1/manifest.json" | head -1; }

open_path() {
  [ -n "${PGC_DEMO_NO_BROWSER:-}" ] && return 0
  if command -v open >/dev/null; then open "$1"; elif command -v xdg-open >/dev/null; then xdg-open "$1"; fi
}

port_in_use() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }

# ── serve PORT CLIENT PAGE MOUNTS: the transport's HTTP adapter, pointed at one web client ───
serve() {
  local port=$1 client=$2 page=$3 mounts=$4 pid
  need pgc_transport
  if port_in_use "$port"; then
    echo "pgc-demo: port $port is in use. Is the demo already running? Stop it with Ctrl-C." >&2
    exit 2
  fi
  echo "  page     : http://127.0.0.1:$port$page"
  echo "  snapshot : $(snapshot_id "$(snapshot)")"
  echo "  records  : $DEMO_HOME"
  echo "Press Ctrl-C to stop."
  echo
  PGC_HTTP_PORT="$port" PGC_HTTP_BINDINGS="$client/bindings/http.json" \
  PGC_SNAPSHOT_ROOT="$(snapshot)" PGC_STATIC_MOUNTS="/=$client/web;$mounts" \
    pgc_transport http &
  pid=$!
  trap 'kill $pid 2>/dev/null; echo; echo Stopped.; exit 0' INT TERM
  for _ in $(seq 50); do
    port_in_use "$port" && { open_path "http://127.0.0.1:$port$page"; break; }
    sleep 0.2
  done
  wait $pid
}

# ── play VALUE: one request through the entrance ──────────────────────────────────────────────
# A number-shaped value is sent as a number, anything else as text: the entrance alone decides.
play() {
  local value=$1 json
  need pgc_transport
  if [[ $value =~ ^-?[0-9]+$ ]]; then json="{\"number\": $value}"
  else json="{\"number\": \"${value//[\"\\]/}\"}"; fi
  PGC_SNAPSHOT_ROOT="$(snapshot)" pgc_transport call collatz.compute "$json"
}

# ── set-limit N: edit one declaration, then the release's own build ───────────────────────────
step() {
  local label=$1; shift
  printf '  %-46s' "$label"
  if "$@" >> "$LOG" 2>&1; then echo ok; else
    echo FAILED; tail -12 "$LOG" | sed 's/^/    /'
    echo "pgc-demo: $label failed. The full log is $LOG" >&2; exit 1
  fi
}

# What `compile_domain.sh` does: compile, then prove the transforms the build supplies.
compile() {
  local name=$1 dir="$BUILD/$2" structure=$3
  step "compile   $name" env PGC_PLATFORM_ROOT="$BUILD/software_governance" PGC_DOMAIN_ROOTS="$dir" \
    protocol_compiler compile --structure "$structure"
  step "prove     ${name%% *} transforms" protocol_runtime conformance "$dir" --structure "$structure"
}

set_limit() {
  local limit=$1 ti before out new_id previous kept repos="$DATA/repos"
  [[ $limit =~ ^[0-9]+$ ]] && [ "$limit" -ge 1 ] || {
    echo "pgc-demo: the limit must be a whole number of 1 or more, not '$limit'" >&2; exit 2; }
  need protocol_compiler; need protocol_runtime; need snapshot_assembler
  BUILD="$DATA/build"; LOG="$BUILD/build.log"
  mkdir -p "$BUILD"; : > "$LOG"

  # The platform and the inspector are copied and compiled once; only the game changes.
  if [ ! -d "$BUILD/software_governance" ]; then
    mkdir -p "$BUILD/software_governance"
    for part in registry capability_side_effects capability_transforms; do
      cp -R "$repos/software_governance/$part" "$BUILD/software_governance/"
    done
    mkdir -p "$BUILD/snapshot_inspector"
    cp -R "$repos/snapshot_inspector/registry" "$repos/snapshot_inspector/transport" "$BUILD/snapshot_inspector/"
  fi
  # The game's source is restored on every build, so each limit is one edit away from the
  # released declaration, never an edit of an edit.
  rm -rf "$BUILD/collatz"; mkdir -p "$BUILD/collatz"
  cp -R "$repos/conformance_workloads/workloads/collatz/registry" \
        "$repos/conformance_workloads/workloads/collatz/transport" "$BUILD/collatz/"

  ti="$BUILD/collatz/transport/TI_COLLATZ_COMPUTE_V0.md"
  [ "$(grep -cE '^[[:space:]]+max:[[:space:]]*[0-9]+[[:space:]]*$' "$ti")" = 1 ] || {
    echo "pgc-demo: expected one 'max:' line in $ti" >&2; exit 1; }
  before=$(sed -nE 's/^[[:space:]]+max:[[:space:]]*([0-9]+)[[:space:]]*$/\1/p' "$ti")
  sed -i.orig -E "s/^([[:space:]]+max:[[:space:]]*)[0-9]+[[:space:]]*$/\1$limit/" "$ti" && rm "$ti.orig"
  echo "Changed the declaration of $ENTRANCE"
  echo "  collatz/transport/TI_COLLATZ_COMPUTE_V0.md: max $before -> $limit"
  echo

  [ -d "$BUILD/software_governance/snapshot/compiled" ] ||
    compile "platform (first build only)" software_governance STRUCTURE_BUILD_PLATFORM_CONFIG_V0
  [ -d "$BUILD/snapshot_inspector/snapshot/compiled" ] ||
    compile "inspection (first build only)" snapshot_inspector STRUCTURE_BUILD_INSPECTION_CONFIG_V0
  compile "workload" collatz STRUCTURE_BUILD_WORKLOAD_CONFIG_V0

  out="$BUILD/assembled"; rm -rf "$out"
  step "assemble  and seal a new snapshot" snapshot_assembler assemble \
    --source "$BUILD/software_governance/snapshot/compiled" \
    --source "$BUILD/collatz/snapshot/compiled" \
    --source "$BUILD/snapshot_inspector/snapshot/compiled" \
    --out "$out" --profile "$PROFILE"

  previous=$(snapshot_id "$(snapshot)")
  new_id=$(snapshot_id "$out")
  kept="$DEMO_HOME/snapshots/$new_id"
  if [ -d "$kept" ]; then rm -rf "$out"; else mkdir -p "$DEMO_HOME/snapshots"; mv "$out" "$kept"; fi
  echo "$kept" > "$DEMO_HOME/active"
  echo
  echo "New snapshot  $new_id  (now active; admits up to $limit)"
  echo "Previous      $previous  (unchanged, still sealed)"
  echo
  echo "If the game page is open, stop it with Ctrl-C and start it again: a running page keeps"
  echo "the snapshot it started with."
}

reset() {
  rm -f "$DEMO_HOME/active"
  echo "The published snapshot is active: $(snapshot_id "$(snapshot)")"
  echo "Snapshots you built are kept under $DEMO_HOME/snapshots"
}

# ── tamper: edit a copy of the sealed snapshot, and ask the runtime to start it ──────────────
tamper() {
  local copy ti before refusal
  need protocol_runtime
  SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/pgc-demo-tamper.XXXXXX")
  trap 'rm -rf "$SCRATCH"' EXIT
  copy="$SCRATCH/snapshot"
  cp -R "$(snapshot)" "$copy"
  ti=$(find "$copy/canonical" -name 'workload__TI_COLLATZ_COMPUTE_V0.json' | head -1)
  before=$(sed -nE 's/.*"max": ([0-9]+).*/\1/p' "$ti" | head -1)
  sed -i.orig -E "s/\"max\": $before/\"max\": $((before - 1))/" "$ti" && rm "$ti.orig"
  echo "Copied the sealed snapshot and changed $ENTRANCE"
  echo "  ${ti#"$copy"/}: max $before -> $((before - 1))"
  echo "Asking the runtime to start the copy: protocol_runtime boot"
  echo
  if refusal=$(protocol_runtime boot --snapshot "$copy" 2>&1); then
    echo "STARTED: the runtime accepted an edited snapshot. This is a defect; please report it."
    exit 1
  fi
  echo "$refusal" | grep -m1 -i "refused" || echo "$refusal"
  echo
  echo "The runtime ran nothing. A rule changes only through its declaration."
}

mkdir -p "$DEMO_HOME"
case "${1:-}" in
  collatz)
    paths
    case "${2:-}" in
      "")        echo "PGC demo — the Collatz game"
                 serve 8000 "$COLLATZ_CLIENT" /collatz/ "/traces=$DEMO_HOME/traces;/snapshot=$(snapshot);/diagram=$INSPECTION_CLIENT/web/workflow/js" ;;
      set-limit) [ $# -eq 3 ] || usage; set_limit "$3" ;;
      reset)     [ $# -eq 2 ] || usage; reset ;;
      tamper)    [ $# -eq 2 ] || usage; tamper ;;
      *)         [ $# -eq 2 ] || usage; play "$2" ;;
    esac ;;
  inspect)
    paths
    case "${2:-}" in
      "")   echo "PGC demo — look inside the game"
            serve 8001 "$INSPECTION_CLIENT" "/workflow/?wf=${WORKFLOW//:/%3A}" "/snapshot=$(snapshot)" ;;
      show) [ $# -eq 3 ] || usage; need si; si --snapshot "$(snapshot)" artifact show "$3" ;;
      code) [ $# -eq 3 ] || usage; "$(python_of_install)" -m inspect "$3" ;;
      *)    usage ;;
    esac ;;
  where) echo "$DEMO_HOME"; open_path "$DEMO_HOME" ;;
  *) usage ;;
esac
