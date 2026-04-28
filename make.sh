#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found on PATH: $1"
}

show_help() {
  cat <<'EOF'
Usage:
  ./make.sh [options]

Default:
  ./make.sh
    Build title pages and dissertation using latexmk.

Actions:
  --clean              Remove auxiliary build files, keep PDFs.
  --full-clean         Remove the out directory and generated title-page PDF.
  --clean-all          Alias for --full-clean.
  --rebuild            Full clean, then build.
  --help, -h           Show this help.

Tool selection:
  --tool latexmk       Use latexmk dependency tracking. Default.
  --tool pdflatex      Run pdflatex + biber + pdflatex + pdflatex directly.

Build tuning:
  --jobs N             Use N jobs for make-backed dependency generation.
  --no-parallel        Disable latexmk -use-make and MAKEFLAGS.

Examples:
  ./make.sh --rebuild
  ./make.sh --tool pdflatex
  ./make.sh --jobs 8
EOF
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

TOOL="latexmk"
ACTION="build"
PARALLEL=1
MAKE_JOBS=""

while (($#)); do
  case "$1" in
    -h|--help|help)
      ACTION="help"
      shift
      ;;
    --clean|clean)
      ACTION="clean"
      shift
      ;;
    --full-clean|--clean-all|full-clean)
      ACTION="full-clean"
      shift
      ;;
    --rebuild|rebuild)
      ACTION="rebuild"
      shift
      ;;
    --tool)
      [[ $# -ge 2 ]] || die "--tool requires latexmk or pdflatex"
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#--tool=}"
      shift
      ;;
    --jobs)
      [[ $# -ge 2 ]] || die "--jobs requires a number"
      MAKE_JOBS="$2"
      shift 2
      ;;
    --jobs=*)
      MAKE_JOBS="${1#--jobs=}"
      shift
      ;;
    --no-parallel)
      PARALLEL=0
      shift
      ;;
    *)
      die "Unknown argument: $1. Run ./make.sh --help for usage."
      ;;
  esac
done

if [[ "$ACTION" == "help" ]]; then
  show_help
  exit 0
fi

printf '== Thesis handover build ==\n'
printf 'Working directory: %s\n' "$PWD"
printf 'Tool: %s\n' "$TOOL"
printf 'Action: %s\n' "$ACTION"

clean_aux() {
  printf '== Cleaning auxiliary files ==\n'
  if [[ -d out ]]; then
    if [[ "$TOOL" == "latexmk" ]] && command -v latexmk >/dev/null 2>&1; then
      latexmk -c -outdir=out main.tex
      if [[ -d out/tuc-titlepages ]]; then
        (cd frontmatter && latexmk -c -outdir=../out/tuc-titlepages univerlag_publisher_filler.tex)
      fi
    else
      find out -type f \( \
        -name '*.aux' -o -name '*.bbl' -o -name '*.bcf' -o -name '*.blg' -o \
        -name '*.fdb_latexmk' -o -name '*.fls' -o -name '*.glo' -o \
        -name '*.log' -o -name '*.out' -o -name '*.run.xml' -o \
        -name '*.synctex.gz' -o -name '*.toc' \
      \) -delete
    fi
  fi
  printf 'Clean complete.\n'
}

full_clean() {
  printf '== Full clean ==\n'
  rm -rf out
  rm -f frontmatter/univerlag_publisher_filler.pdf
  printf 'Full clean complete.\n'
}

case "$ACTION" in
  clean)
    clean_aux
    exit 0
    ;;
  full-clean)
    full_clean
    exit 0
    ;;
  rebuild)
    full_clean
    ;;
esac

case "$TOOL" in
  latexmk)
    require_tool latexmk
    ;;
  pdflatex)
    require_tool pdflatex
    ;;
  *)
    die "Unsupported tool '$TOOL'. Use latexmk or pdflatex."
    ;;
esac
require_tool biber

LATEXMK_FLAGS=(-pdf -file-line-error -interaction=nonstopmode -synctex=1)
LATEXMK_MAKE_FLAGS=()
if [[ "$PARALLEL" -eq 1 ]]; then
  if command -v make >/dev/null 2>&1; then
    if [[ -z "$MAKE_JOBS" ]]; then
      if command -v nproc >/dev/null 2>&1; then
        MAKE_JOBS="$(nproc)"
      else
        MAKE_JOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1')"
      fi
    fi
    export MAKEFLAGS="-j${MAKE_JOBS} ${MAKEFLAGS:-}"
    LATEXMK_MAKE_FLAGS=(-use-make)
    printf 'Parallel dependency builds enabled via make -j%s.\n' "$MAKE_JOBS"
  else
    printf 'Parallel dependency builds unavailable: make not found; using normal latexmk mode.\n'
  fi
fi

build_document() {
  local source="$1"
  local outdir="$2"
  local stem="${source%.tex}"
  local pdf="$outdir/$stem.pdf"

  if [[ "$TOOL" == "latexmk" ]]; then
    latexmk "${LATEXMK_FLAGS[@]}" "${LATEXMK_MAKE_FLAGS[@]}" \
      -outdir="$outdir" \
      "$source"
    return
  fi

  run_pdflatex "$source" "$outdir" "$pdf"
  if [[ -f "$outdir/$stem.bcf" ]]; then
    biber "$outdir/$stem"
  fi
  run_pdflatex "$source" "$outdir" "$pdf"
  run_pdflatex "$source" "$outdir" "$pdf"
}

run_pdflatex() {
  local source="$1"
  local outdir="$2"
  local pdf="$3"

  if pdflatex -file-line-error -interaction=nonstopmode -synctex=1 \
      -output-directory="$outdir" "$source"; then
    return 0
  fi
  [[ -f "$pdf" ]] || return 1
  printf 'WARNING: pdflatex returned a nonzero status, but produced %s.\n' "$pdf"
}

copy_if_changed() {
  local src="$1"
  local dst="$2"
  [[ -f "$src" ]] || die "Missing build output: $src"
  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
  elif cmp -s "$src" "$dst"; then
    printf 'TUC titlepage PDF unchanged; keeping existing frontmatter copy.\n'
  else
    cp "$src" "$dst"
  fi
}

mkdir -p out/tuc-titlepages
[[ -d out/tuc-titlepages ]] || die "Could not create output directory: out/tuc-titlepages"

printf '\n== Building TUC title pages ==\n'
(
  cd frontmatter
  build_document univerlag_publisher_filler.tex ../out/tuc-titlepages
)
copy_if_changed out/tuc-titlepages/univerlag_publisher_filler.pdf frontmatter/univerlag_publisher_filler.pdf

printf '\n== Building dissertation ==\n'
build_document main.tex out

printf '\nBuild complete: %s/out/main.pdf\n' "$PWD"
