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

function __done_is_tmux_window_active
    set -q fish_pid; or set -l fish_pid %self

    # find the outermost process within tmux
    # ppid != "tmux" -> pid = ppid
    # ppid == "tmux" -> break
    set tmux_fish_pid $fish_pid
    while set tmux_fish_ppid (ps -o ppid= -p $tmux_fish_pid | string trim)
        # remove leading hyphen so that basename does not treat it as an argument (e.g. -fish), and return only
        # the actual command and not its arguments so that basename finds the correct command name.
        # (e.g. '/usr/bin/tmux' from command '/usr/bin/tmux new-session -c /some/start/dir')
        and ! string match -q "tmux*" (basename (ps -o command= -p $tmux_fish_ppid | string replace -r '^-' '' | string split ' ')[1])
        set tmux_fish_pid $tmux_fish_ppid
    end

    # tmux session attached and window is active -> no notification
    # all other combinations -> send notification
    tmux list-panes -a -F "#{session_attached} #{window_active} #{pane_pid}" | string match -q "1 1 $tmux_fish_pid"
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
    functions -e __done_humanize_duration
end
