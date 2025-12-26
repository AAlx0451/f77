#!/bin/bash
# f77 - like (posix) c99, but f77 :)

VERSION="f77 version 20240504" # current f2c --help version output. this tool is designed for latest f2c from netlib. anyway the changes are small, so you can use ANY f2c

# to be pretty, we need to check if we are a tty ^^
if [ -t 2 ]; then
    BOLD_RED=$(printf '\033[1;31m')
    BOLD_MAGENTA=$(printf '\033[1;35m')
    RESET=$(printf '\033[0m')
else
    BOLD_RED=""
    BOLD_MAGENTA=""
    RESET=""
fi

# make error bold red
error_msg() {
    printf "f77: %serror:%s %s\n" "$BOLD_RED" "$RESET" "$1" >&2
}

# format f2c errors and warnings to be pretty
format_f2c_output() {
    local original_filename=$1
    sed -E \
        -e "s/^Error on line ([0-9]+) of [^:]+: (.*)/${original_filename}:\1: ${BOLD_RED}error:${RESET} \2/" \
        -e "s/^Warning on line ([0-9]+)( of [^:]+)?: (.*)/${original_filename}:\1: ${BOLD_MAGENTA}warning:${RESET} \3/" >&2
}

CC="${CC:-cc}"
CFLAGS="-O3 -w" # FORTRAN must be fast. If you don't have a GCC-like CC, use -O

LIBS="-lf2c -lm"

declare -a GCC_INPUTS
declare -a TEMP_FILES

show_help() {
    cat << EOF
$VERSION

Usage: f77 [options] file...
Supported extensions: .f, .F, .f77

Options:
  -o <file>        Place the output into <file>.
  -c               Compile and assemble, but do not link.
  -g               Generate debugging information.
  -O<number>       Set optimization level (Default is -O3).
  --help           Display this information.
  --version        Display compiler version information.

Examples:
  f77 main.f77 -o app
  f77 -c module.f
EOF
    exit 0
}

show_version() {
    echo "$VERSION"
    exit 0
}

cleanup() {
    if [ ${#TEMP_FILES[@]} -gt 0 ]; then
        rm -f "${TEMP_FILES[@]}"
    fi
}
trap cleanup EXIT INT TERM

for arg in "$@"; do
    if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        show_help
    fi
    if [[ "$arg" == "--version" ]]; then
        show_version
    fi
done

if ! command -v f2c >/dev/null 2>&1; then
    error_msg "'f2c' not found."
    exit 127
fi

if [ $# -eq 0 ]; then
    error_msg "no input files"
    exit 1
fi

for arg in "$@"; do
    case "$arg" in
        *.f77) # explained below
            temp_f_file=$(mktemp --suffix=.f)
            if ! cp "$arg" "$temp_f_file"; then
                error_msg "failed to create temporary file for '$arg'"
                exit 1
            fi
            TEMP_FILES+=("$temp_f_file")

            LOGFILE=$(mktemp) # to avoid race condition 
            TEMP_FILES+=("$LOGFILE")

            f2c "$temp_f_file" > "$LOGFILE" 2>&1
            rc=$?
            
            grep -E "^(Error|Warning)" "$LOGFILE" | format_f2c_output "$arg"

            if [ $rc -ne 0 ]; then
                exit 1
            fi

            temp_basename=$(basename "$temp_f_file")
            c_file="${temp_basename%.f}.c"

            GCC_INPUTS+=("$c_file")
            TEMP_FILES+=("$c_file")
            ;;

        *.f|*.F)
            LOGFILE=$(mktemp)
            TEMP_FILES+=("$LOGFILE")

            f2c "$arg" > "$LOGFILE" 2>&1
            rc=$?

            grep -E "^(Error|Warning)" "$LOGFILE" | format_f2c_output "$arg"
            
            if [ $rc -ne 0 ]; then
                exit 1
            fi

            base_name=$(basename "$arg")
            c_file="${base_name%.*}.c"

            GCC_INPUTS+=("$c_file")
            TEMP_FILES+=("$c_file")
            ;;

        *)
            GCC_INPUTS+=("$arg")
            ;;
    esac
done

if [ ${#GCC_INPUTS[@]} -gt 0 ]; then
    "$CC" $CFLAGS "${GCC_INPUTS[@]}" $LIBS
    exit $?
fi

exit 0

# .f77 I/O operations explanation:
# idk why, but f2c allows .f or .F files
# only. but now F77 code is
# usually .f77

# grep operations explanation:
# idk why, but f2c always writes to stderr :(

# this should be fixed. code updates, so commits are probably possible.... well, later. or never
