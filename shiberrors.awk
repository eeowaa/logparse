BEGIN {
    # Make sure we have enough terminal color support to run this script
    "tput colors" | getline ncolors
    if (ncolors < 8) {
        printf "Invalid terminal type: %s\n", ENVIRON["TERM"] > "/dev/stderr"
        exit 1
    }

    # ANSI color escape sequences
    color["gray"]    = "\033[1;30m"
    color["red"]     = "\033[1;31m"
    color["green"]   = "\033[1;32m"
    color["yellow"]  = "\033[1;33m"
    color["blue"]    = "\033[1;34m"
    color["magenta"] = "\033[1;35m"
    color["cyan"]    = "\033[1;36m"
    color["none"]    = "\033[0;;m"

    # "Weather map" colors (currently unused)
    # XXX: I like the idea of this, but don't have an immediate use for it
    scale[1] = color["blue"]
    scale[2] = color["cyan"]
    scale[3] = color["green"]
    scale[4] = color["yellow"]
    scale[5] = color["red"]
    scale[6] = color["magenta"]

    # Stability indicators
    status["better"]  = color["green"]
    status["worse"]   = color["red"]
    status["stable"]  = color["blue"]
    status["perfect"] = color["gray"]
    status["default"] = status["stable"]
    status["none"]    = color["none"]

    # Get width of terminal from cmdline arg, environment, or terminfo db
    if (COLUMNS !~ /^[[:digit:]]+$/) {
        if (ENVIRON[COLUMNS] ~ /^[[:digit:]]+$/)
            COLUMNS = ENVIRON[COLUMNS]
        else
            "tput cols" | getline COLUMNS
    }

    # Get output column width from cmdline arg or default to 8
    # TODO: Allow users to specific left- or right-alignment of fields
    if (WIDTH !~ /^[[:digit:]]+$/)
        WIDTH = 8
}

# This is our header line containing column labels
# TODO: Handle cases where there is no header line
NR == 1 {

    # The number of data columns is equal to the number of column labels
    # XXX: This assumption is critical to successful operation
    ncols = NF

    # We do not colorize this line; just print it and move on
    for (i = 1; i <= ncols; ++i)
        printf "%-*s", WIDTH, $i

    printf "\n"
    next
}

# This block is executed for each data line
# TODO: Break this out into a function and let users decide which to use
{
    last = 0
    position = 0
    for (i = 1; i <= ncols; ++i) {
        if ($i == last) {
            if ($i == 0)
                # Zero for 2nd consecutive column (or zero in column 1)
                output($i, status["perfect"])
            else
                # Same positive count as previous column
                output($i, status["stable"])
        } else if ($i > last) {
            if (i == 1)
                # Positive count in column 1
                output($i, status["default"])
            else
                # Greater count than previous column
                output($i, status["worse"])
        } else {
            # Lesser count than previous column
            output($i, status["better"])
        }
        last = $i
        position += length($i) + 1
    }

    # End the line with the row description, trimmed to terminal width
    # TODO: Give users the option to not trim the description, or to omit it
    description = substr($0, position + 1)
    print status["none"] substr(description, 1, COLUMNS - WIDTH * ncols)
}

# TODO: Print statistics at the end
END {
}

function output(string, color) {
    printf "%s%-*s", color, WIDTH, string
}
