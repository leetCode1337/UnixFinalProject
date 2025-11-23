#!/bin/bash

set -euo pipefail

# Default values
DEFAULT_TOP_N=20
STOPWORDS_FILE="stopwords.txt"

# Usage help function
usage() {
    cat << EOF
Usage: $0 <subcommand> [options] <arguments>

CLI Text Processing Tool - A Bash script for common text processing tasks.

Subcommands:
  stats     Display line, word, and byte counts for files (wc -l -w -c)
  find      Search for patterns in files (grep -nH)
  topwords  List the top N most common words (case-insensitive)
  clean     Clean text by removing extra spaces and blank lines
  report    Generate a report in Markdown or CSV format with summaries

Global options:
  --help    Show this help message

For subcommand-specific help, run: $0 <subcommand> --help

Examples:
  ./texttool.sh stats notes.txt
  ./texttool.sh find "error" logs/*.log
  ./texttool.sh topwords -n 10 essay.txt
  ./texttool.sh clean draft.txt > draft_clean.txt
  ./texttool.sh report "*.txt" > report.md
  ./texttool.sh report --csv "*.txt" > report.csv
EOF
    exit 0
}

# Subcommand-specific usage
stats_usage() {
    cat << EOF
Usage: $0 stats [files...]

Display line, word, and byte counts for each file.
EOF
    exit 0
}

find_usage() {
    cat << EOF
Usage: $0 find [options] <pattern> [files...]

Search for pattern in files.

Options:
  -i          Case-insensitive search
  -r          Recursive search in directories
  --include   Include files matching glob (e.g., '*.txt')
  --exclude   Exclude files matching glob (e.g., '*.tmp')
EOF
    exit 0
}

topwords_usage() {
    cat << EOF
Usage: $0 topwords [options] [files...]

List the top N most common words (case-insensitive, alphanumeric only).

Options:
  -n N        Number of top words to show (default: $DEFAULT_TOP_N)
  --stopwords FILE  File with stop words to exclude (default: $STOPWORDS_FILE if exists)
EOF
    exit 0
}

clean_usage() {
    cat << EOF
Usage: $0 clean <file>

Clean text by replacing multiple spaces with single space and removing blank lines.
Outputs to stdout.
EOF
    exit 0
}

report_usage() {
    cat << EOF
Usage: $0 report [options] [files...]

Generate a report with counts and summaries.

Options:
  --csv       Output in CSV format instead of Markdown
  --top N     Include top N words in the report (default: none)
EOF
    exit 0
}

# Check if no arguments
if [ $# -eq 0 ]; then
    usage
fi

# Check for global --help
if [ "$1" = "--help" ]; then
    usage
fi

# Get subcommand
subcommand="$1"
shift

case "$subcommand" in
    stats)
        if [ $# -eq 0 ] || [ "$1" = "--help" ]; then
            stats_usage
        fi
        for file in "$@"; do
            if [ ! -f "$file" ]; then
                echo "Error: File '$file' not found" >&2
                exit 1
            fi
        done
        wc -l -w -c "$@"
        ;;

    find)
        ignore_case=""
        recursive=""
        include=""
        exclude=""
        while getopts ":ir" opt; do
            case $opt in
                i) ignore_case="-i" ;;
                r) recursive="-r" ;;
                \?) echo "Invalid option: -$OPTARG" >&2; find_usage ;;
            esac
        done
        shift $((OPTIND-1))

        # Parse long options for include/exclude
        while [ $# -gt 0 ]; do
            case "$1" in
                --include) include="--include=$2"; shift 2 ;;
                --exclude) exclude="--exclude=$2"; shift 2 ;;
                --help) find_usage ;;
                --*) echo "Invalid option: $1" >&2; find_usage ;;
                *) break ;;
            esac
        done

        if [ $# -lt 1 ]; then
            echo "Error: Pattern required" >&2
            find_usage
        fi
        pattern="$1"
        shift
        if [ -z "$pattern" ]; then
            echo "Error: Empty pattern" >&2
            exit 1
        fi
        files=("$@")
        if [ ${#files[@]} -eq 0 ]; then
            files=(".")
        fi
        grep -nH $ignore_case $recursive $include $exclude -- "$pattern" "${files[@]}" || true  # Ignore no match exit code
        ;;

    topwords)
        top_n=$DEFAULT_TOP_N
        stopwords=$STOPWORDS_FILE
        while getopts ":n:" opt; do
            case $opt in
                n) top_n="$OPTARG" ;;
                \?) echo "Invalid option: -$OPTARG" >&2; topwords_usage ;;
            esac
        done
        shift $((OPTIND-1))

        # Parse long options
        while [ $# -gt 0 ]; do
            case "$1" in
                --stopwords) stopwords="$2"; shift 2 ;;
                --help) topwords_usage ;;
                --*) echo "Invalid option: $1" >&2; topwords_usage ;;
                *) break ;;
            esac
        done

        if [ $# -eq 0 ]; then
            echo "Error: At least one file required" >&2
            topwords_usage
        fi
        for file in "$@"; do
            if [ ! -f "$file" ]; then
                echo "Error: File '$file' not found" >&2
                exit 1
            fi
        done

        # Pipeline for top words
        LC_ALL=C \
        cat "$@" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/[^a-z0-9]/\n/g' | \
        awk 'NF > 0' | \
        ( [ -f "$stopwords" ] && grep -v -F -f "$stopwords" || cat ) | \
        sort | \
        uniq -c | \
        sort -nr | \
        head -n "$top_n"
        ;;

    clean)
        if [ $# -ne 1 ] || [ "$1" = "--help" ]; then
            clean_usage
        fi
        file="$1"
        if [ ! -f "$file" ]; then
            echo "Error: File '$file' not found" >&2
            exit 1
        fi
        sed 's/[ \t]\+/ /g; s/^[ \t]*//; s/[ \t]*$//' "$file" | awk 'NF > 0'
        ;;

    report)
        csv=false
        top_n=0  # 0 means no top words
        while [ $# -gt 0 ]; do
            case "$1" in
                --csv) csv=true; shift ;;
                --top) top_n="$2"; shift 2 ;;
                --help) report_usage ;;
                --*) echo "Invalid option: $1" >&2; report_usage ;;
                *) break ;;
            esac
        done

        if [ $# -eq 0 ]; then
            echo "Error: At least one file required" >&2
            report_usage
        fi
        for file in "$@"; do
            if [ ! -f "$file" ]; then
                echo "Error: File '$file' not found" >&2
                exit 1
            fi
        done

        if $csv; then
            # CSV output
            echo "File,Lines,Words,Bytes"
            wc -l -w -c "$@" | sed '$d' | awk '{print $4 "," $1 "," $2 "," $3}'
            if [ "$top_n" -gt 0 ]; then
                echo "Top Words (aggregated)"
                $0 topwords -n "$top_n" "$@"
            fi
        else
            # Markdown output
            echo "# Text Processing Report"
            echo ""
            echo "## Per-File Statistics"
            echo ""
            echo "| File | Lines | Words | Bytes |"
            echo "|------|-------|-------|-------|"
            wc -l -w -c "$@" | sed '$d' | awk '{printf "| %s | %s | %s | %s |\n", $4, $1, $2, $3}'
            echo ""
            if [ "$top_n" -gt 0 ]; then
                echo "## Top $top_n Words (aggregated)"
                echo ""
                $0 topwords -n "$top_n" "$@" | awk '{printf "- %s: %s\n", $2, $1}'
                echo ""
            fi
            echo "## Summary"
            echo "Total files: $#"
            total_lines=$(wc -l "$@" | tail -1 | awk '{print $1}')
            total_words=$(wc -w "$@" | tail -1 | awk '{print $1}')
            total_bytes=$(wc -c "$@" | tail -1 | awk '{print $1}')
            echo "Total lines: $total_lines"
            echo "Total words: $total_words"
            echo "Total bytes: $total_bytes"
        fi
        ;;

    *)
        echo "Error: Unknown subcommand '$subcommand'" >&2
        usage
        ;;
esac