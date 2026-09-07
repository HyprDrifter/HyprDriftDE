#!/usr/bin/env bash
set -uo pipefail

button_x=${1:-}
button_y=${2:-}
button_width=${3:-}
button_height=${4:-}
hyprctl_command=${HYPRDRIFT_HYPRCTL:-/usr/bin/hyprctl}
jq_command=${HYPRDRIFT_JQ:-/usr/bin/jq}
swaync_client=${HYPRDRIFT_SWAYNC_CLIENT:-/usr/bin/swaync-client}

is_integer() {
    [[ $1 =~ ^-?[0-9]+$ ]]
}

is_positive_integer() {
    [[ $1 =~ ^[0-9]+$ ]] && (( $1 > 0 ))
}

inside_rectangle() {
    local cursor_x=$1
    local cursor_y=$2
    local rect_x=$3
    local rect_y=$4
    local rect_width=$5
    local rect_height=$6

    (( cursor_x >= rect_x
        && cursor_x < rect_x + rect_width
        && cursor_y >= rect_y
        && cursor_y < rect_y + rect_height ))
}

inside_swaync_surface() {
    local cursor_x=$1
    local cursor_y=$2

    "$hyprctl_command" layers -j 2>/dev/null \
        | "$jq_command" -e \
            --argjson cursor_x "$cursor_x" \
            --argjson cursor_y "$cursor_y" '
                [.. | objects
                    | select((.namespace? // "") | startswith("swaync"))
                    | select(.x? != null and .y? != null
                        and .w? != null and .h? != null)
                    | select($cursor_x >= .x and $cursor_x < (.x + .w)
                        and $cursor_y >= .y and $cursor_y < (.y + .h))]
                | length > 0
            ' >/dev/null 2>&1
}

if ! is_integer "$button_x" \
        || ! is_integer "$button_y" \
        || ! is_positive_integer "$button_width" \
        || ! is_positive_integer "$button_height"; then
    exit 0
fi

panel_geometry=""
for _ in {1..20}; do
    panel_geometry=$(
        "$hyprctl_command" layers -j 2>/dev/null \
            | "$jq_command" -r '
                [.. | objects
                    | select(.namespace? == "swaync-control-center")
                    | [.x, .y, .w, .h]
                    | @tsv]
                | last // empty
            ' 2>/dev/null
    )

    [[ -n $panel_geometry ]] && break
    sleep 0.05
done

read -r panel_x panel_y panel_width panel_height <<< "$panel_geometry"
if ! is_integer "${panel_x:-}" \
        || ! is_integer "${panel_y:-}" \
        || ! is_positive_integer "${panel_width:-}" \
        || ! is_positive_integer "${panel_height:-}"; then
    exit 0
fi

outside_samples=0
panel_entered=0
while true; do
    cursor_position=$(
        "$hyprctl_command" cursorpos -j 2>/dev/null \
            | "$jq_command" -r '[(.x | floor), (.y | floor)] | @tsv' \
                2>/dev/null
    )
    read -r cursor_x cursor_y <<< "$cursor_position"

    if ! is_integer "${cursor_x:-}" || ! is_integer "${cursor_y:-}"; then
        exit 0
    fi

    if inside_rectangle "$cursor_x" "$cursor_y" \
            "$panel_x" "$panel_y" "$panel_width" "$panel_height"; then
        panel_entered=1
        outside_samples=0
    elif inside_rectangle "$cursor_x" "$cursor_y" \
            "$button_x" "$button_y" "$button_width" "$button_height"; then
        outside_samples=0
    elif inside_swaync_surface "$cursor_x" "$cursor_y"; then
        # Revalidate against live layer geometry before treating the pointer
        # as outside. The control center can resize and SwayNC can create
        # auxiliary surfaces for close buttons and grouped-card controls.
        panel_entered=1
        outside_samples=0
    elif (( panel_entered == 1 )); then
        ((outside_samples += 1))
        if (( outside_samples >= 4 )); then
            "$swaync_client" --close-panel --skip-wait >/dev/null 2>&1 || true
            exit 0
        fi
    fi

    sleep 0.05
done
