texttool.sh - CLI Text Processing Tool
======================================

A fast, zero-install, pure-Bash command-line utility that turns the most
common Unix text-processing commands into one consistent, user-friendly tool.

Why this exists
---------------
Running `wc`, `grep`, `awk`, `sed`, `sort`, `uniq` separately works, but you
end up typing long pipelines and remembering different flags every time.
texttool.sh gives you a single script with memorable subcommands, clear
help, good error messages, and predictable output.

Full Feature List
-----------------
stats        Exact equivalent of wc -l -w -c for one or many files
             Shows lines, words, bytes per file + grand total

find         Search pattern across files with context
             - Shows filename:linenumber:content (like grep -nH)
             - Supports -i (case-insensitive) and basic glob patterns

topwords     Most frequent words (case-insensitive, alphanumeric only)
             - Optional -n N to limit output (default 20)
             - Optional --stopwords FILE (defaults to stopwords.txt if exists)
             - Ignores punctuation and normalizes everything

clean        Clean up messy text files
             - Collapses multiple spaces/tabs into single space
             - Removes leading/trailing whitespace on every line
             - Deletes completely blank lines
             - Outputs cleaned text to stdout (perfect for piping or redirection)

report       One-command summary report generator
             - Human-readable Markdown by default
             - --csv flag produces clean CSV
             - --top N includes aggregated top words section
             - Works on hundreds of files without running out of memory

Detailed Usage Examples
-----------------------

# 1. Basic statistics
./texttool.sh stats document.txt notes.txt

# 2. Find all TODO comments in a whole project
./texttool.sh find -i todo src/**/*.c src/**/*.h

# 3. Discover the real most-used words in a novel (excluding "the", "and", etc.)
./texttool.sh topwords -n 30 moby-dick.txt

# 4. Clean a badly formatted log before analysis
./texttool.sh clean messy.log > clean.log

# 5. Full Markdown report for every text file in current folder
./texttool.sh report *.txt > project_report.md

# 6. CSV report + top 15 words (great for spreadsheets or scripts)
./texttool.sh report --csv --top 15 logs/*.log > logs_summary.csv

# 7. One-liner: top 10 words across every .md file in the repo
./texttool.sh topwords -n 10 --stopwords stopwords.txt *.md

Help System
-----------
./texttool.sh                shows short global help
./texttool.sh --help         full global help
./texttool.sh stats --help   help specific to the stats subcommand
(and similarly for every other subcommand)

Customization
-------------
- stopwords.txt (optional)
  Plain text file, one stop-word per line.
  Automatically used by topwords and report --top when present.

Error Handling
--------------
- Clear, colored error messages when files are missing
- Proper exit codes (1 for usage errors, works great in scripts)
- Graceful handling of empty files or zero matches

Performance
-----------
All operations stream data instead of loading files into memory.
Tested on multi-gigabyte log files with no slowdown.

Requirements
------------
- Linux or macOS (or any system with GNU coreutils)
- Bash 4+ (standard on virtually all modern systems)
- No sudo, no packages, no compilation

Just one file. Drop it anywhere and run.

License
-------
MIT – feel free to use, modify, and share.

Enjoy faster text processing!