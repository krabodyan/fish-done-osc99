if not status is-interactive
    exit
end

set TMUX_SOCKET (echo $TMUX | cut -d ',' -f1)

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

function __done_is_tmux_window_active
    command tmux -S $TMUX_SOCKET display-message -pt "$TMUX_PANE" '#{window_active}' | grep -q 1
end

function __done_ended --on-event fish_postexec
    set -l exit_status $status
    set -q __done_min_cmd_duration; or set -g __done_min_cmd_duration 1000
    set -q cmd_duration; or set -l cmd_duration $CMD_DURATION
    set -q __done_tmux_pane_format; or set -g __done_tmux_pane_format '[#{window_index}]'

    if test $cmd_duration
        and test $cmd_duration -gt $__done_min_cmd_duration

        set -l humanized_duration (__done_humanize_duration "$cmd_duration")
        set -l message (echo $argv[1] | base64)

        set title "Failed after $humanized_duration"
        set -l urgency 2
        set -l duration 6000

        if test $exit_status -eq 0; or test $exit_status -eq 130
            set title "Done in $humanized_duration"
            set urgency 1
        end

        set id (date +%s%N)

        if test -n "$TMUX"
            printf "\x1bPtmux;\x1b\x1b]99;i=$id:d=0;$title\x1b\\"
            printf "\x1bPtmux;\x1b\x1b]99;i=$id:d=0:u=$urgency;\x1b\\"
            printf "\x1bPtmux;\x1b\x1b]99;i=$id:d=0:w=$duration;\x1b\\"
            if __done_is_tmux_window_active
                printf "\x1bPtmux;\x1b\x1b]99;i=$id:d=1:o=invisible:e=1:p=body;$message\x1b\\"
            else
                printf "\x1bPtmux;\x1b\x1b]99;i=$id:d=1:o=always:e=1:p=body;$message\x1b\\"
            end
        else
            printf "\x1b]99;i=$id:d=0;$title\x1b\\"
            printf "\x1b]99;i=$id:d=0:u=$urgency;\x1b\\"
            printf "\x1b]99;i=$id:d=0:w=$duration;\x1b\\"
            printf "\x1b]99;i=$id:d=1:o=invisible:e=1:p=body;$message\x1b\\"
        end
    end
end

function __done_uninstall -e done_uninstall
    functions -e __done_ended
    functions -e __done_is_tmux_window_active
    functions -e __done_humanize_duration
end
