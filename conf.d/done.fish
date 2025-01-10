if not status is-interactive
    exit
end

function __done_humanize_duration -a milliseconds
    set -l seconds (math --scale=0 "$milliseconds/1000" % 60)
    set -l minutes (math --scale=0 "$milliseconds/60000" % 60)
    set -l hours (math --scale=0 "$milliseconds/3600000")

    if test $hours -gt 0
        printf '%s' $hours'h '
    end
    if test $minutes -gt 0
        printf '%s' $minutes'm '
    end
    if test $seconds -gt 0
        printf '%s' $seconds's'
    end
end

function __done_ended --on-event fish_postexec
    set -l exit_status $status
    set -q __done_min_cmd_duration; or set -g __done_min_cmd_duration 2000
    set -q cmd_duration; or set -l cmd_duration $CMD_DURATION

    if test $cmd_duration
        and test $cmd_duration -gt $__done_min_cmd_duration

        set -l humanized_duration (__done_humanize_duration "$cmd_duration")
        set -l message (echo $argv[1] | base64)

        set -l title "Done in $humanized_duration"
        set -l duration 5000

        if test $exit_status -ne 0
            set title "Failed after $humanized_duration"
            set duration 7000
        end

        set -l urgency 1
        if test $exit_status -ne 0
            set urgency 2
        end

        set id (date +%s%N)
        printf "\x1b]99;i=$id:d=0;$title\x1b\\"
        printf "\x1b]99;i=$id:d=0:u=$urgency;\x1b\\"
        printf "\x1b]99;i=$id:d=0:w=$duration;\x1b\\"
        printf "\x1b]99;i=$id:e=1:d=1:p=body;$message\x1b\\"
    end
end

function __done_uninstall -e done_uninstall
    functions -e __done_ended
    functions -e __done_humanize_duration
end
