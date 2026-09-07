#!/usr/bin/env bash
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}"
cache_home="${XDG_CACHE_HOME:-${HOME:?HOME is not set}/.cache}"
user_config="$config_home/swaync/config.json"
user_style="$config_home/swaync/style.css"
user_style_template="$config_home/swaync/style.css.in"
managed_swaync_root="${HYPRDRIFT_SWAYNC_ROOT:-/etc/hyprdrift/hypr/.config/swaync}"
quickdrift_root="${HYPRDRIFT_QUICKDRIFT_ROOT:-/etc/hyprdrift/quickdrift}"
managed_config="$managed_swaync_root/config.json"
managed_style_template="$managed_swaync_root/style.css.in"
settings_file="$quickdrift_root/Internal/Settings.qml"
theme_root="$quickdrift_root/Internal/Themes/base16"
generated_style="$cache_home/hyprdrift/swaync/style.css"
generated_config="$cache_home/hyprdrift/swaync/config.json"

warn() {
    printf '[swaync] %s\n' "$*" >&2
}

hex_to_rgb() {
    local hex_value=${1#\#}

    printf '%d, %d, %d' \
        "$((16#${hex_value:0:2}))" \
        "$((16#${hex_value:2:2}))" \
        "$((16#${hex_value:4:2}))"
}

selected_theme_name() {
    local settings_line

    [[ -r "$settings_file" ]] || return 1

    while IFS= read -r settings_line; do
        if [[ $settings_line =~ ^[[:space:]]*property[[:space:]]+string[[:space:]]+currentBase16ThemeName[[:space:]]*:[[:space:]]*\"([A-Za-z0-9._-]+)\" ]]; then
            printf '%s\n' "${BASH_REMATCH[1]}"
            return 0
        fi
    done < "$settings_file"

    return 1
}

generate_theme_style() {
    local style_template=$1
    local theme_name
    local theme_file
    local palette_key
    local palette_value
    local palette_token
    local temporary_style
    local -a palette_keys=(
        base00 base01 base02 base03 base04 base05 base06 base07
        base08 base09 base0A base0B base0C base0D base0E base0F
    )
    local -a replacements=()
    local -A palette=()

    command -v yq >/dev/null 2>&1 || {
        warn "yq is unavailable; using SwayNC's default stylesheet"
        return 1
    }

    theme_name=$(selected_theme_name) || {
        warn "could not read currentBase16ThemeName from $settings_file"
        return 1
    }
    theme_file="$theme_root/$theme_name.yaml"

    [[ -r "$theme_file" ]] || {
        warn "theme palette is unavailable: $theme_file"
        return 1
    }
    [[ -r "$style_template" ]] || return 1

    for palette_key in "${palette_keys[@]}"; do
        palette_value=$(yq eval -r ".palette.$palette_key // \"\"" "$theme_file")
        if [[ ! $palette_value =~ ^#[[:xdigit:]]{6}$ ]]; then
            warn "theme $theme_name has an invalid $palette_key color"
            return 1
        fi

        palette[$palette_key]=$palette_value
        palette_token=${palette_key^^}
        replacements+=(
            -e "s|@$palette_token@|$palette_value|g"
            -e "s|@${palette_token}_RGB@|$(hex_to_rgb "$palette_value")|g"
        )
    done

    mkdir -p "$(dirname "$generated_style")"
    temporary_style=$(mktemp "${generated_style}.XXXXXX")
    if ! sed "${replacements[@]}" "$style_template" > "$temporary_style"; then
        rm -f -- "$temporary_style"
        return 1
    fi
    chmod 600 "$temporary_style"
    mv -f -- "$temporary_style" "$generated_style"
}

selected_config=""
selected_style=""

if [[ -r "$user_config" ]]; then
    selected_config=$user_config
elif [[ -r "$managed_config" ]]; then
    selected_config=$managed_config
fi

if [[ -n $selected_config ]]; then
    mkdir -p "$(dirname "$generated_config")"
    temporary_config=$(mktemp "${generated_config}.XXXXXX")
    if install -m 600 "$selected_config" "$temporary_config"; then
        mv -f -- "$temporary_config" "$generated_config"
        selected_config=$generated_config
    else
        rm -f -- "$temporary_config"
    fi
fi

if [[ -r "$user_style" ]]; then
    selected_style=$user_style
else
    style_template=$managed_style_template
    if [[ -r "$user_style_template" ]]; then
        style_template=$user_style_template
    fi

    if generate_theme_style "$style_template"; then
        selected_style=$generated_style
    fi
fi

if [[ ${1:-} == "--print-style" ]]; then
    printf '%s\n' "$selected_style"
    exit 0
fi

swaync_command=(/usr/bin/swaync)
if [[ -n $selected_config ]]; then
    swaync_command+=(--config "$selected_config")
fi
if [[ -n $selected_style ]]; then
    swaync_command+=(--style "$selected_style")
fi

exec "${swaync_command[@]}"
