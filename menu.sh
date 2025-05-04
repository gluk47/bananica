# Usage: . menu.sh

# https://askubuntu.com/a/1386907/371856
# ANSI codes: https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
function menu() {
    local -r prompt="$1" options=("${@:3}")
    local -n outvar="$2"

    ##############################################################################
    ### These variables can be set when calling the function to style the menu ###
    ###                                                                        ###

    # 'radiobutton': Draw selection boxes. Spacebar moves selection. Exaclty one item is always selected.
    # 'checkbox': Draw selection boxes. Spacebar adds/removes selection. Any number of items can be selected.
    # 'menu': No selection boxes, spacebar accepts the selected options and works as Enter, leaves the menu.
    local mode

    local selected  # 0-based number of the menu item selected by default

    # For mode=checkbox: range within which Enter accepts the choice and leaves the menu.
    # If set to 1..1, the 'checkbox' mode acts exactly as the 'radiobutton' mode.
    local min_count max_count

    local cyclic  # 'yes'/'no' to wrap over when reaching the first or last menu item

    # An array of 0/1 with the same length as $options for the 'checkbox' mode, the default selection state
    local checked

    # A pattern for `printf` to use for a highglited string.
    # %s: checkmark (if multiselect), %s: line text
    local style

    # A pattern to use for non-highglited strings. Derived from style
    # automatically: everything inside the outer \e[*m in the 'style' string.
    local nonhl_style

    # What string to use as a checkmark (the argument to the first %s in style). Escape-sequences may be used.
    local checkmark

    # margin: if supplied, a string of spaces to be printed before 'nonhl_style'.
    # The margin is calculated automatically based on 'style': as many spaces as there are chars before the first '\e[*m'

    : ${mode:=menu}
    : ${selected:=0}  # negative indexes supported (as in python arrays)
    : ${cyclic=yes}

    ##############################################################################

    local check_count=0 index=0

    # Crop leftmost and rightmost '\e[.*m' and everything outside
    # If you want no formatting, still provide \e[0m for a correct margin autodetection
    _get_nonhl_style() {
        local s="${1%\\e[*m*}"
        echo "${s#*\\e[*m}"
    }

    local count=${#options[@]}
    (( selected < 0 )) && (( selected += count ))
    case "$mode" in
        radiobutton)
            min_count=1
            max_count=1
            : ${style:='> \e[7m(%s) %s\e[0m'}
            ;&
        checkbox)
            : ${style:='> \e[7m[%s] %s\e[0m'}
            : ${nonhl_style:="$(_get_nonhl_style "$style")"}
            : ${checkmark=*}
            : ${min_count:=0}
            : ${max_count:=$count}
            local check_space="${checkmark%\\e[*m*}"
            check_space="${check_space#*\\e[*m}"
            check_space="${check_space//?/ }"
            (( ${#checked[@]} == count )) || {
                checked=({1..$count})
                checked=(${checked[@]/*/0})
            }
            (( min_count == 1 && max_count == 1 )) && mode=radiobutton
            [[ $mode == radiobutton ]] && {
                checked=(${checked[@]/*/0})
                checked[selected]=1
                check_count=1
            }
            ;;
        menu)
            : ${style:='> \e[7m%s\e[0m'}
            : ${nonhl_style:="$(_get_nonhl_style "$style")"}
            style="${style/'%s'/%s%s}"
            nonhl_style="${nonhl_style/'%s'/%s%s}"
            checkmark=
            min_count=0
            max_count=0
            ;;
    esac
    [[ ! $cyclic || $cyclic == no || $cyclic == 0 ]] && cyclic=0 || cyclic=1

    [[ -v margin ]] || {
        local margin="${style%%\\e[*m*}"
        margin="${margin//?/ }"
    }

    unset _get_nonhl_style  # bash has no 'local' keyword for functions

    while :; do
        printf -- "$prompt\e[0K"
        (( check_count < min_count || check_count > max_count )) && printf " (choose from $min_count to $max_count)"
        echo
        local key keys item formatted_item check
        index=0
        for item in "${options[@]}"; do
            check=
            [[ $mode != menu ]] && {
                (( checked[index] )) && check="$checkmark" || check="$check_space"
            }
            if (( index == selected )); then
                printf -v formatted_item -- "$style\e[0K" "$check" "$item"
                printf -- "$formatted_item\n"
            else
                printf -v formatted_item -- "%s$nonhl_style\e[0K" "$margin" "$check" "$item"
                printf -- "$formatted_item\n"
            fi
            ((index++))
        done
        read -sN1 key
        read -sN2 -t.0001 keys  # esc sequences are 3 chars
        case "$key$keys" in
            $'\e[A' | k | л | ↑)  (( --selected < 0 )) && (( selected = cyclic ? count - 1 : 0 )) ;;
            $'\e[B' | j | о | ↓)  (( ++selected >= count)) && (( selected = cyclic ? 0 : count - 1 )) ;;
            ' ')
                case $mode in
                    menu) break;;
                    radiobutton)
                        checked=(${checked[@]/*/0})
                        checked[selected]=1
                        ;;
                    checkbox)
                        (( check_count -= checked[selected] ))
                        (( checked[selected] = 1 - checked[selected] ))
                        (( check_count += checked[selected] ))
                        ;;
                esac
                ;;
            $'\x0a') (( min_count <= check_count && check_count <= max_count )) && break ;;
        esac
        printf "\e[$((count + 1))A"
    done

    if [[ $mode == checkbox ]]; then
        outvar=()
        for ((index = 0; index < count; index++)); do
            (( checked[index] )) && outvar+=("${options[index]}")
        done
    else
        outvar="${options[selected]}"
    fi
}
