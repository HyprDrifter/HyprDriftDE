#!/usr/bin/env bash
set -euo pipefail

button_center_x=${1:-}
output_width=${2:-}
cache_home="${XDG_CACHE_HOME:-${HOME:?HOME is not set}/.cache}"
runtime_config="$cache_home/hyprdrift/swaync/config.json"
swaync_client="${HYPRDRIFT_SWAYNC_CLIENT:-/usr/bin/swaync-client}"

toggle_panel() {
    exec "$swaync_client" --toggle-panel --skip-wait
}

if [[ ! $button_center_x =~ ^[0-9]+$ || ! $output_width =~ ^[0-9]+$ ]]; then
    toggle_panel
fi

if [[ ! -r $runtime_config ]] || ! command -v jq >/dev/null 2>&1; then
    toggle_panel
fi

panel_width=$(jq -er '."control-center-width" | numbers' "$runtime_config") || toggle_panel
edge_gap=$(jq -er '."control-center-margin-left" | numbers' "$runtime_config") || edge_gap=15

panel_width=${panel_width%.*}
edge_gap=${edge_gap%.*}

if [[ ! $panel_width =~ ^[0-9]+$ || ! $edge_gap =~ ^[0-9]+$ ]]; then
    toggle_panel
fi

if ((panel_width <= 0 || output_width <= panel_width)); then
    toggle_panel
fi

desired_right_gap=$((output_width - button_center_x - panel_width / 2))
maximum_right_gap=$((output_width - panel_width - edge_gap))

if ((maximum_right_gap < edge_gap)); then
    edge_gap=$(((output_width - panel_width) / 2))
    maximum_right_gap=$edge_gap
fi

if ((desired_right_gap < edge_gap)); then
    desired_right_gap=$edge_gap
elif ((desired_right_gap > maximum_right_gap)); then
    desired_right_gap=$maximum_right_gap
fi

temporary_config=$(mktemp "${runtime_config}.XXXXXX")
if jq --argjson right_gap "$desired_right_gap" \
    '."control-center-margin-right" = $right_gap' \
    "$runtime_config" > "$temporary_config"; then
    chmod 600 "$temporary_config"
    mv -f -- "$temporary_config" "$runtime_config"
else
    rm -f -- "$temporary_config"
    toggle_panel
fi

"$swaync_client" --reload-config --skip-wait
exec "$swaync_client" --toggle-panel --skip-wait
