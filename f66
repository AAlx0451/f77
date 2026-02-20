#!/bin/bash
# f77/66/IV - like (posix) c99, but f77 :)

VERSION="f77 version 20240505 (wraps f2c)" # updated version

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
CPP="${CPP:-cpp}"
CFLAGS="${CFLAGS:--O3 -w}" # FORTRAN must be fast. If you don't have a GCC-like CC, use -O
LIBS="-lf2c -lm"

declare -a GCC_INPUTS
declare -a TEMP_FILES
declare -a F2C_OPTS
declare -a CPP_OPTS
declare -a CC_OPTS
declare -a INPUT_FILES
declare -a EXTERN_FUNCS # array to store functions passed via --extern
declare -a BYVAL_RULES  # array to store byval rules (func=arg_index)

LINKER_FLAG=1
OUTPUT_FILE=""

# check how we were invited to the party
# if we are f66 (or f4/fiv), we need to act like f66 code
PROGRAM_NAME=$(basename "$0")
if [[ "$PROGRAM_NAME" =~ ^(f66|f4|fiv)$ ]]; then
    F2C_OPTS+=("-onetrip" "-w66")
else
    PROGRAM_NAME="f77"
fi

show_help() {
    cat << EOF
$VERSION

Usage: $PROGRAM_NAME [options] file...
Supported extensions: 
  .f, .f77, .f66, .for        - Fortran source
  .F, .F77, .F66, .FOR        - Fortran source with C preprocessor directives

Options:
  -o <file>    Place the output into <file>.
  -c           Compile and assemble, but do not link.
  -g           Generate debugging information.
  -O<number>   Set optimization level (Default is -O3).
  -I<dir>      Add <dir> to include search path (passed to f2c and cpp).
  -D<macro>    Define preprocessor macro (passed to cpp).
  -C           Compile code to check that subscripts are within bounds.
  -I2          Render INTEGER and LOGICAL as short, INTEGER*4 as long int.
  -I4          Confirm the default rendering of INTEGER as long int.
  -I8          Assume 8-byte integer and logical, 4-byte REAL, etc.
  -onetrip     Compile DO loops that are performed at least once if reached.
  -U           Honor the case of variable and external names.
  -u           Make the default type of a variable 'undefined'.
  -w           Suppress all warning messages.
  -w66         Suppress Fortran 66 compatibility warnings only.
  -A           Produce ANSI C (default).
  -K           Produce K&R C
  -a           Make local variables automatic rather than static.
  -C++         Output C++ code.
  -E           Declare uninitialized COMMON to be Extern.
  -ec          Place uninitialized COMMON blocks in separate files.
  -ext         Complain about f77 extensions.
  -f           Assume free-format input.
  -72          Treat text appearing after column 72 as an error.
  -h           Emulate Fortran 66's treatment of Hollerith.
  -i2          Similar to -I2, but assume a modified libF77 and libI77.
  -i90         Do not recognize the Fortran 90 bit-manipulation intrinsics.
  -kr          Enforce Fortran expression evaluation (K&R style).
  -P           Write a file.P of ANSI (or C++) prototypes.
  -p           Supply preprocessor definitions for common-block members.
  -R           Do not promote REAL functions and operations to DOUBLE PRECISION.
  -r           Cast REAL arguments of intrinsic functions to REAL.
  -r8          Promote REAL to DOUBLE PRECISION, COMPLEX to DOUBLE COMPLEX.
  -s           Preserve multidimensional subscripts.
  -trapuv      Dynamically initialize local variables to help find references.
  -w8          Suppress warnings about odd-word alignment of doubles.
  -Wn          Assume n characters/word.
  -z           Do not implicitly recognize DOUBLE COMPLEX.
  -!bs         Do not recognize backslash escapes.
  -!c          Inhibit C output, but produce -P output.
  -!I          Reject include statements.
  -!i8         Disallow INTEGER*8.
  -!it         Don't infer types of untyped EXTERNAL procedures.
  -!P          Do not attempt to infer ANSI or C++ prototypes from usage.
  --extern=fn  Replace fn_ with fn in generated C code (C linkage interop).
  --byval=fn=N Remove '&' from N-th argument of function fn (1-based index).
  --help       Display this information.
  --version    Display compiler version information.
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

if ! command -v f2c >/dev/null 2>&1; then
    error_msg "'f2c' not found."
    exit 127
fi

while [ $# -gt 0 ]; do
    arg="$1"
    case "$arg" in
        --help|-h)
            show_help
            ;;
        --version)
            show_version
            ;;
        --extern=*)
            # extract the function name and add it to the array
            EXTERN_FUNCS+=("${arg#--extern=}")
            ;;
        --byval=*)
            # extract rule: function_name=arg_number
            BYVAL_RULES+=("${arg#--byval=}")
            ;;
        -o)
            if [ -z "$2" ]; then
                error_msg "argument to '-o' is missing (expected 1 value)"
                exit 1
            fi
            CC_OPTS+=("-o" "$2")
            OUTPUT_FILE="$2"
            shift
            ;;
        -c)
            LINKER_FLAG=0
            CC_OPTS+=("-c")
            ;;
        -g)
            F2C_OPTS+=("-g")
            CC_OPTS+=("-g")
            ;;
        -O*)
            CC_OPTS+=("$arg")
            ;;
        -I*)
            F2C_OPTS+=("$arg")
            CPP_OPTS+=("$arg")
            ;;
        -D*|-U*)
            CPP_OPTS+=("$arg")
            ;;
        # f2c flags
        -C|-I2|-I4|-I8|-onetrip|-u|-w|-w66|-A|-a|-C++|-E|-ec|-ext|-f|-72|-h|-i2|-i90|-kr|-P|-p|-R|-r|-r8|-s|-trapuv|-w8|-W*|-z)
            F2C_OPTS+=("$arg")
            ;;
        -!*)
            F2C_OPTS+=("$arg")
            ;;
        *.f|*.F|*.f77|*.f66|*.F77|*.F66|*.for|*.FOR)
            INPUT_FILES+=("$arg")
            ;;
        *.c|*.o|*.a|*.so)
            GCC_INPUTS+=("$arg")
            ;;
        *)
            CC_OPTS+=("$arg")
            ;;
    esac
    shift
done

if [ ${#INPUT_FILES[@]} -eq 0 ] && [ ${#GCC_INPUTS[@]} -eq 0 ]; then
    error_msg "no input files"
    exit 1
fi

for input_file in "${INPUT_FILES[@]}"; do
    filename=$(basename "$input_file")
    extension="${filename##*.}"
    f2c_input="$input_file"

    declare -a CURRENT_F2C_OPTS=("${F2C_OPTS[@]}")

    if [[ "$extension" =~ ^(f66|F66)$ ]]; then
        CURRENT_F2C_OPTS+=("-onetrip")
    fi

    # Capitalized extensions imply C Preprocessor
    if [[ "$extension" =~ ^(F|F77|F66|FOR)$ ]]; then
        if ! command -v "$CPP" >/dev/null 2>&1; then
            error_msg "preprocessing requested (.$extension file) but '$CPP' not found."
            exit 127
        fi

        temp_preprocessed=$(mktemp --suffix=.f)
        TEMP_FILES+=("$temp_preprocessed")
        CPP_LOG=$(mktemp)
        TEMP_FILES+=("$CPP_LOG")

        "$CPP" -P -x c -w "${CPP_OPTS[@]}" "$input_file" > "$temp_preprocessed" 2> "$CPP_LOG"
        cpp_rc=$?

        if [ -s "$CPP_LOG" ]; then
             cat "$CPP_LOG" >&2
        fi

        if [ $cpp_rc -ne 0 ]; then
             error_msg "preprocessing failed for '$input_file'"
             exit 1
        fi

        f2c_input="$temp_preprocessed"
    fi

    # Non-standard extensions (not .f or .F) need to be renamed/copied to .f for f2c
    if [[ "$extension" =~ ^(f77|f66|for)$ ]]; then
        temp_conv=$(mktemp --suffix=.f)
        TEMP_FILES+=("$temp_conv")
        if ! cp "$input_file" "$temp_conv"; then
             error_msg "failed to copy '$input_file'"
             exit 1
        fi
        f2c_input="$temp_conv"
    fi

    LOGFILE=$(mktemp)
    TEMP_FILES+=("$LOGFILE")

    f2c "${CURRENT_F2C_OPTS[@]}" "$f2c_input" > "$LOGFILE" 2>&1
    rc=$?

    grep -E "^(Error|Warning)" "$LOGFILE" | format_f2c_output "$input_file"

    if [ $rc -ne 0 ]; then
        exit 1
    fi

    base_name=$(basename "$f2c_input" .f)
    generated_p_file="${base_name}.P"
    if [ -f "$generated_p_file" ]; then
        original_base="${filename%.*}"
        target_p_file="${original_base}.P"

        if [ "$generated_p_file" != "$target_p_file" ]; then
            mv "$generated_p_file" "$target_p_file"
        fi
    fi

    generated_c_file="${base_name}.c"

    if [ -f "$generated_c_file" ]; then
        
        # 1. Apply --extern replacements (renaming func_ to func)
        if [ ${#EXTERN_FUNCS[@]} -gt 0 ]; then
            SED_CMD=""
            for efunc in "${EXTERN_FUNCS[@]}"; do
                # use \b (word boundary) to prevent accidental substring replacements
                SED_CMD+="s/\b${efunc}_\b/${efunc}/g; "
            done
            temp_c=$(mktemp)
            sed -E "$SED_CMD" "$generated_c_file" > "$temp_c"
            cat "$temp_c" > "$generated_c_file"
            rm -f "$temp_c"
        fi

        # 2. Apply --byval replacements (removing & from specific args)
        if [ ${#BYVAL_RULES[@]} -gt 0 ]; then
            SED_CMD=""
            for rule in "${BYVAL_RULES[@]}"; do
                # Split rule func=arg_num
                func_name="${rule%%=*}"
                arg_num="${rule##*=}"
                
                # Validation: arg_num must be an integer
                if ! [[ "$arg_num" =~ ^[0-9]+$ ]]; then
                    error_msg "invalid argument number in --byval=$rule"
                    continue
                fi

                if [ "$arg_num" -eq 1 ]; then
                    # For 1st argument: find 'func(', match whitespaces, remove '&'
                    # Regex: replace (func\s*\()\s*& with \1
                    SED_CMD+="s/(\b${func_name}\s*\()\s*&/\1/g; "
                else
                    # For N-th argument: we need to skip N-1 arguments (separated by commas)
                    # We build a regex that matches N-1 groups of "non-comma chars followed by comma"
                    repeat_count=$((arg_num - 1))
                    
                    # Pattern explanation:
                    # \b${func_name}\s*\(       -> match function name and open parenthesis
                    # ([^,)]+,[[:space:]]*){K}  -> match K arguments (non-comma/paren chars + comma + optional space)
                    # \s*&                      -> match the target ampersand (to be removed)
                    
                    SED_CMD+="s/(\b${func_name}\s*\(([^,)]+,[[:space:]]*){${repeat_count}})\s*&/\1/g; "
                fi
            done
            
            temp_c=$(mktemp)
            sed -E "$SED_CMD" "$generated_c_file" > "$temp_c"
            cat "$temp_c" > "$generated_c_file"
            rm -f "$temp_c"
        fi

        GCC_INPUTS+=("$generated_c_file")
        TEMP_FILES+=("$generated_c_file")
    fi
done

if [ ${#GCC_INPUTS[@]} -gt 0 ]; then
    "$CC" $CFLAGS "${CC_OPTS[@]}" "${GCC_INPUTS[@]}" $LIBS
    exit $?
fi

exit 0
