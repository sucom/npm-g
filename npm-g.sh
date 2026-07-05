#!/usr/bin/env bash

# Resolve directory across platforms (bash/zsh)
if [ -n "${BASH_VERSION:-}" ]; then
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [ -n "${ZSH_VERSION:-}" ]; then
  DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  DIR="$(cd "$(dirname "$0")" && pwd)"
fi

MANIFEST="$DIR/npm-g.manifest"

if [ ! -f "$MANIFEST" ]; then
    echo "# Global Packages Manifest" > "$MANIFEST"
    echo "# Add one global package per line like nodemon or typescript@5.4.2" >> "$MANIFEST"
    echo "# Blank lines and lines starting with # are ignored." >> "$MANIFEST"
    echo "Created empty manifest configuration at: $MANIFEST"
fi

parse_package() {
    local raw="$1"
    local _name_var="$2"
    local _ver_var="$3"

    local pkg_name
    local pkg_ver

    if [[ "$raw" == @* ]]; then
        local rest="${raw:1}"
        if [[ "$rest" == *@* ]]; then
            pkg_name="@${rest%%@*}"
            pkg_ver="${rest#*@}"
        else
            pkg_name="$raw"
            pkg_ver=""
        fi
    else
        if [[ "$raw" == *@* ]]; then
            pkg_name="${raw%%@*}"
            pkg_ver="${raw#*@}"
        else
            pkg_name="$raw"
            pkg_ver=""
        fi
    fi
    eval "$_name_var=\"\$pkg_name\""
    eval "$_ver_var=\"\$pkg_ver\""
}

to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

nl=$'\n'
INSTALLED_LIST=""
MANIFEST_LIST=""

hydrate_installed_map() {
    INSTALLED_LIST=""
    while IFS= read -r line || [ -n "$line" ]; do
        local cleaned="$line"
        # Strip hidden carriage returns to prevent terminal visual glitches
        cleaned="${cleaned%$'\r'}"
        cleaned="${cleaned//├── /}"
        cleaned="${cleaned//└── /}"
        cleaned="${cleaned//+-- /}"
        cleaned="${cleaned//\`-- /}"
        cleaned="${cleaned//|/}"
        cleaned="${cleaned// /}"

        # FIXED: Allow forward slashes for scoped packages.
        # Only block strings that start with a root slash (/) or Windows drive letter (C:)
        if [[ "$cleaned" == *@* ]] && [[ "$cleaned" != /* ]] && [[ "$cleaned" != [A-Za-z]:* ]]; then
            INSTALLED_LIST="${INSTALLED_LIST}${cleaned}${nl}"
        fi
    done <<< "$(npm list -g --depth=0 2>/dev/null)"
}

hydrate_manifest_list() {
    MANIFEST_LIST=""
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        if [ -n "$line" ] && [[ "$line" != \#* ]]; then
            parse_package "$line" m_name m_ver
            local lower_m_name
            lower_m_name=$(to_lower "$m_name")
            MANIFEST_LIST="${MANIFEST_LIST}${lower_m_name}${nl}"
        fi
    done < "$MANIFEST"
}

get_installed_version() {
    local search_name
    search_name=$(to_lower "$1")
    if [ -z "$search_name" ]; then return; fi
    local line
    while IFS= read -r line || [ -n "$line" ]; do
        if [ -n "$line" ]; then
            parse_package "$line" i_name i_ver
            local lower_i_name
            lower_i_name=$(to_lower "$i_name")
            if [ "$lower_i_name" = "$search_name" ]; then
                echo "$i_ver"
                return 0
            fi
        fi
    done <<< "$INSTALLED_LIST"
}

is_in_manifest() {
    local search_name
    search_name=$(to_lower "$1")
    if [ -z "$search_name" ]; then return 1; fi
    echo "$MANIFEST_LIST" | grep -qxF "$search_name"
}

routine_help() {
    echo "Usage: npm-g [action] [packages...]"
    echo ""
    echo "Actions:"
    echo "  help, -h, --help          Show this usage information"
    echo "  version, -v, --version     Show npm-g tool, node, and npm versions"
    echo "  list, -l, --list          List all manifest vs currently installed packages"
    echo "  diff, -d, --diff          Show only environment discrepancies"
    echo "  install, -i, --install    Install missing/mismatched manifest packages,"
    echo "                            or pass arguments to run a targeted global install"
    echo "  uninstall, -u, --uninstall Purge all untracked global packages from system,"
    echo "                            or pass arguments to explicitly remove target modules"
    echo "  add, -a, --add            Add package entries directly into the manifest"
    echo "  remove, -r, --remove      Remove package entries from the manifest"
    echo ""
    echo "Special Case:"
    echo "  npm-g [package1] ...      Implicit fallback to sequential global installation"
}

routine_version() {
    echo "npm-g version: 1.0.0"
    local node_v
    node_v=$(node -v 2>/dev/null)
    if [ -n "$node_v" ]; then echo "node version:  $node_v"; fi
    local npm_v
    npm_v=$(npm -v 2>/dev/null)
    if [ -n "$npm_v" ]; then echo "npm version:   $npm_v"; fi
}

routine_list() {
    hydrate_installed_map
    hydrate_manifest_list
    echo ""
    echo "Manifest vs Global Environment List:"
    echo "----------------------------------------------------------------------------"

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        if [ -n "$line" ] && [[ "$line" != \#* ]]; then
            parse_package "$line" m_name m_ver
            local cur_ver
            cur_ver=$(get_installed_version "$m_name")

            if [ -n "$cur_ver" ]; then
                if [ -z "$m_ver" ]; then
                    echo "[OK]        $m_name (@$cur_ver)"
                else
                    if [ "$m_ver" = "$cur_ver" ]; then
                        echo "[OK]        $m_name (@$cur_ver)"
                    else
                        echo "[MISMATCH]  $m_name (Manifest: $m_ver, Current: $cur_ver)"
                    fi
                fi
            else
                echo "[MISSING]   $m_name"
            fi
        fi
    done < "$MANIFEST"

    while IFS= read -r line || [ -n "$line" ]; do
        if [ -n "$line" ]; then
            parse_package "$line" i_name i_ver
            if ! is_in_manifest "$i_name"; then
                echo "[UNTRACKED] $i_name (@$i_ver)"
            fi
        fi
    done <<< "$INSTALLED_LIST"
}

routine_diff() {
    hydrate_installed_map
    hydrate_manifest_list
    echo ""
    echo "Environment Discrepancies (Diff):"
    echo "----------------------------------------------------------------------------"

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        if [ -n "$line" ] && [[ "$line" != \#* ]]; then
            parse_package "$line" m_name m_ver
            local cur_ver
            cur_ver=$(get_installed_version "$m_name")

            if [ -n "$cur_ver" ]; then
                if [ -n "$m_ver" ]; then
                    if [ "$m_ver" != "$cur_ver" ]; then
                        echo "[MISMATCH]  $m_name (Manifest: $m_ver, Current: $cur_ver)"
                    fi
                fi
            else
                echo "[MISSING]   $m_name"
            fi
        fi
    done < "$MANIFEST"

    while IFS= read -r line || [ -n "$line" ]; do
        if [ -n "$line" ]; then
            parse_package "$line" i_name i_ver
            if ! is_in_manifest "$i_name"; then
                echo "[UNTRACKED] $i_name (@$i_ver)"
            fi
        fi
    done <<< "$INSTALLED_LIST"
}

execution_summary() {
    local p_list="$1"
    local f_list="$2"
    echo ""
    echo "============================================================================"
    echo "Operational Summary Details"
    echo "============================================================================"
    if [ -n "$p_list" ]; then echo "Successfully Installed: $p_list"; fi
    if [ -n "$f_list" ]; then echo "Critical Operational Fails: $f_list"; fi
}

routine_install() {
    shift
    if [ $# -gt 0 ]; then
        routine_install_args "$@"
        return
    fi

    hydrate_installed_map
    hydrate_manifest_list
    local passed_list=""
    local failed_list=""
    local any_work=0
    local corepack_hook=0

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        if [ -n "$line" ] && [[ "$line" != \#* ]]; then
            parse_package "$line" m_name m_ver
            local lower_m_name
            lower_m_name=$(to_lower "$m_name")

            if [ "$lower_m_name" = "corepack" ]; then
                corepack_hook=1
            fi

            local cur_ver
            cur_ver=$(get_installed_version "$m_name")

            local need_install=0
            if [ -z "$cur_ver" ]; then
                need_install=1
            else
                if [ -n "$m_ver" ] && [ "$m_ver" != "$cur_ver" ]; then
                    need_install=1
                fi
            fi

            if [ "$need_install" -eq 1 ]; then
                any_work=1
                local target_pkg="$m_name"
                if [ -n "$m_ver" ]; then target_pkg="$m_name@$m_ver"; fi

                echo ""
                echo "Installing $target_pkg globally..."
                if npm install -g "$target_pkg"; then
                    passed_list="$passed_list $target_pkg"
                else
                    failed_list="$failed_list $target_pkg"
                fi
            fi
        fi
    done < "$MANIFEST"

    if [ "$corepack_hook" -eq 1 ]; then
        echo ""
        echo "[HOOK] Activating Corepack shims..."
        if corepack enable; then
            echo "[HOOK] Corepack shims enabled successfully."
        else
            echo "[HOOK] Warning: Failed to enable Corepack shims." >&2
        fi
    fi

    if [ "$any_work" -eq 0 ]; then
        echo "All global packages are synchronized and matching your manifest perfectly."
    else
        execution_summary "$passed_list" "$failed_list"
    fi
}

routine_install_args() {
    local passed_list=""
    local failed_list=""
    for target_pkg in "$@"; do
        echo ""
        echo "Installing $target_pkg globally..."
        if npm install -g "$target_pkg"; then
            passed_list="$passed_list $target_pkg"
        else
            failed_list="$failed_list $target_pkg"
        fi
    done
    execution_summary "$passed_list" "$failed_list"
}

routine_install_special() {
    local passed_list=""
    local failed_list=""
    for target_pkg in "$@"; do
        echo ""
        echo "[npm-g] Installing $target_pkg globally..."
        if npm install -g "$target_pkg"; then
            passed_list="$passed_list $target_pkg"
        else
            failed_list="$failed_list $target_pkg"
        fi
    done
    execution_summary "$passed_list" "$failed_list"
}

routine_uninstall() {
    shift
    if [ $# -gt 0 ]; then
        routine_uninstall_args "$@"
        return
    fi

    hydrate_installed_map
    hydrate_manifest_list
    local passed_list=""
    local failed_list=""
    local any_work=0

    while IFS= read -r line || [ -n "$line" ]; do
        if [ -n "$line" ]; then
            parse_package "$line" i_name i_ver
            if ! is_in_manifest "$i_name"; then
                any_work=1
                echo ""
                echo "Uninstalling untracked package $i_name globally..."
                if npm uninstall -g "$i_name"; then
                    passed_list="$passed_list $i_name"
                else
                    failed_list="$failed_list $i_name"
                fi
            fi
        fi
    done <<< "$INSTALLED_LIST"

    if [ "$any_work" -eq 0 ]; then
        echo "Your environment is clean! No untracked global packages found to purge."
    else
        execution_summary "$passed_list" "$failed_list"
    fi
}

routine_uninstall_args() {
    local passed_list=""
    local failed_list=""
    for target_pkg in "$@"; do
        echo ""
        echo "Uninstalling $target_pkg globally..."
        if npm uninstall -g "$target_pkg"; then
            passed_list="$passed_list $target_pkg"
        else
            failed_list="$failed_list $target_pkg"
        fi
    done
    execution_summary "$passed_list" "$failed_list"
}

routine_add() {
    shift
    if [ $# -eq 0 ]; then
        echo "Error: Specify at least one package name to append to your manifest."
        return
    fi
    hydrate_manifest_list

    for add_raw in "$@"; do
        parse_package "$add_raw" a_name a_ver
        if is_in_manifest "$a_name"; then
            echo "[npm-g] SKIPPED $a_name as it already exists."
        else
            echo "$add_raw" >> "$MANIFEST"
            echo "[npm-g] ADDED $add_raw to the global manifest file."
            local lower_a_name
            lower_a_name=$(to_lower "$a_name")
            MANIFEST_LIST="${MANIFEST_LIST}${lower_a_name}${nl}"
        fi
    done
}

routine_remove() {
    shift
    if [ $# -eq 0 ]; then
        echo "Error: Specify at least one package definition to strip from configuration."
        return
    fi

    local remove_list=""
    for target in "$@"; do
        parse_package "$target" t_name t_ver
        local l_target
        l_target=$(to_lower "$t_name")
        remove_list="${remove_list}${l_target}${nl}"
        echo "[npm-g] REMOVED $target from the global manifest file."
    done

    local temp_manifest="$DIR/npm-g.manifest.tmp"
    rm -f "$temp_manifest"

    while IFS= read -r line || [ -n "$line" ]; do
        local original_line="$line"
        line="${line%$'\r'}"
        if [ -n "$line" ]; then
            if [[ "$line" == \#* ]]; then
                echo "$original_line" >> "$temp_manifest"
            else
                parse_package "$line" m_name m_ver
                local lm_name
                lm_name=$(to_lower "$m_name")
                if ! echo "$remove_list" | grep -qxF "$lm_name"; then
                    echo "$original_line" >> "$temp_manifest"
                fi
            fi
        else
            echo "" >> "$temp_manifest"
        fi
    done < "$MANIFEST"

    if [ -f "$temp_manifest" ]; then
        mv -f "$temp_manifest" "$MANIFEST"
    fi
}

CMD_ARG="$1"

if [ -z "$CMD_ARG" ]; then
    routine_help
    exit 0
fi

L_CMD_ARG=$(to_lower "$CMD_ARG")

case "$L_CMD_ARG" in
    help|-h|--help|h|'?'|'/?'|-)
        routine_help
        ;;
    version|-v|v|-version|--version)
        routine_version
        ;;
    list|-l|l|-list|--list)
        routine_list
        ;;
    diff|-d|d|-diff|--diff)
        routine_diff
        ;;
    install|-i|i|-install|--install|--i)
        routine_install "$@"
        ;;
    uninstall|-u|u|-uninstall|--uninstall|--u)
        routine_uninstall "$@"
        ;;
    add|-a|a|-add|--add|--a)
        routine_add "$@"
        ;;
    remove|-r|r|-remove|--remove|--r|rem|-rem|--rem)
        routine_remove "$@"
        ;;
    *)
        routine_install_special "$@"
        ;;
esac