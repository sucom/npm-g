#!/usr/bin/env bash

# Resolve directory across platforms (bash/zsh)
if [ -n "${BASH_VERSION:-}" ]; then
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [ -n "${ZSH_VERSION:-}" ]; then
  DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# The baseline global manifest (fallback)
MANIFEST="$DIR/npm-g.manifest"
MANIFEST_TYPE="Global"
ACTIVE_MAJOR=""

if [ ! -f "$MANIFEST" ]; then
    echo "# Global Packages Manifest" > "$MANIFEST"
    echo "# Add one global package per line like nodemon or typescript@5.4.2" >> "$MANIFEST"
    echo "# Blank lines and lines starting with # are ignored." >> "$MANIFEST"
    echo "[npm-g] Created empty global manifest configuration at: $MANIFEST"
fi

resolve_manifest() {
    local target_m="$1"

    if [ -z "$target_m" ]; then
        local raw_v
        raw_v=$(node -v 2>/dev/null)
        target_m="${raw_v#v}"
        target_m="${target_m%%.*}"
    fi

    if [ -z "$target_m" ]; then
        MANIFEST="$DIR/npm-g.manifest"
        MANIFEST_TYPE="Global"
        ACTIVE_MAJOR=""
        echo "[npm-g] Operating against Global manifest."
        return
    fi

    local specific_manifest="$DIR/npm-g-$target_m.manifest"
    if [ -f "$specific_manifest" ]; then
        MANIFEST="$specific_manifest"
        MANIFEST_TYPE="v$target_m"
        ACTIVE_MAJOR=""
    else
        MANIFEST="$DIR/npm-g.manifest"
        MANIFEST_TYPE="Global"
        ACTIVE_MAJOR="$target_m"
    fi
    echo "[npm-g] Operating against $MANIFEST_TYPE manifest."
}

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

        # Allow forward slashes for scoped packages.
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
    echo "  version, -v, --version    Show npm-g tool, node, and npm versions"
    echo "  list, -l, --list          List all manifest vs currently installed packages"
    echo "                            (Optional: pass a version number to inspect an alternate NVM node environment)"
    echo "  diff, -d, --diff          Show only environment discrepancies"
    echo "  install, -i, --install    Install missing/mismatched manifest packages,"
    echo "                            or pass arguments to run a targeted global install"
    echo "  uninstall, -u, --uninstall Purge all untracked global packages from system,"
    echo "                            or pass arguments to explicitly remove target modules"
    echo "  add, -a, --add            Add package entries directly into the manifest"
    echo "  remove, -r, --remove      Remove package entries from the manifest"
    echo "                            (Optional: pass . or .NN to purge a version-specific manifest file completely)"
    echo "  edit, -e, --edit          Open manifest in editor (creates it if missing)."
    echo "                            (Optional: pass a major version like 22 to edit/create a specific manifest)"
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

routine_edit() {
    local edit_arg="$1"
    local target_file
    local n_type

    # Ensure the argument is purely numeric
    if [ -n "$edit_arg" ] && ! [[ "$edit_arg" =~ ^[0-9]+$ ]]; then
        echo "[npm-g] Error: Manifest version must be a major version number."
        edit_arg=""
    fi

    if [ -z "$edit_arg" ]; then
        target_file="$DIR/npm-g.manifest"
        n_type="Global"
    else
        target_file="$DIR/npm-g-$edit_arg.manifest"
        n_type="v$edit_arg"
    fi

    if [ ! -f "$target_file" ]; then
        echo "# Global Packages Manifest" > "$target_file"
        echo "# Add one global package per line like nodemon or typescript@5.4.2" >> "$target_file"
        echo "# Blank lines and lines starting with # are ignored." >> "$target_file"
        echo "[npm-g] Created new $n_type manifest configuration."
    fi

    echo "[npm-g] Opening $n_type manifest in editor..."

    # Cross-platform editor launch
    if command -v cygpath >/dev/null 2>&1 && command -v notepad.exe >/dev/null 2>&1; then
        # Windows / Git-Bash
        notepad.exe "$(cygpath -w "$target_file")" &
    elif command -v open >/dev/null 2>&1; then
        # macOS - Force open with TextEdit for unrecognized extensions
        open -e "$target_file"
    else
        # Linux Fallback
        ${EDITOR:-nano} "$target_file"
    fi
}

routine_list() {
    if [ -n "$1" ]; then
        routine_list_target "$1"
        return
    fi

    resolve_manifest
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

read_package_variable() {
    local json_path="$1"
    local var_name="$2"

    # If running in Git-Bash on Windows, translate the POSIX path to a Windows-friendly path
    # so the native Node executable's require() method can resolve it.
    if command -v cygpath >/dev/null 2>&1; then
        json_path=$(cygpath -m "$json_path")
    fi

    local extracted
    # We use node -p natively to avoid messy JSON parsing in bash
    extracted=$(node -p "try { require('$json_path').$var_name } catch(e) { '' }" 2>/dev/null)
    if [ "$extracted" = "undefined" ]; then extracted=""; fi
    echo "$extracted"
}

evaluate_package() {
    local pkg_name="$1"
    local pkg_path="$2"
    local pkg_json="$pkg_path/package.json"

    if [ -f "$pkg_json" ]; then
        local pkg_ver
        pkg_ver=$(read_package_variable "$pkg_json" "version")
        if [ -n "$pkg_ver" ]; then
            INSTALLED_LIST="${INSTALLED_LIST}${pkg_name}@${pkg_ver}${nl}"
        fi
    fi
}

routine_list_target() {
    local target_ver="$1"
    resolve_manifest "$target_ver"
    local node_versions_dir=""

    # Cross-platform NVM resolution mapping (borrowed from nvm-use structure)
    if [ -n "$NVM_HOME" ]; then
        if command -v cygpath >/dev/null 2>&1 && [[ "$NVM_HOME" == *'\'* ]]; then
            node_versions_dir=$(cygpath -u "$NVM_HOME")
        else
            node_versions_dir="$NVM_HOME"
        fi
    elif [ -n "$NVM_DIR" ] || [ -d "$HOME/.nvm" ]; then
        local resolved_nvm_dir="${NVM_DIR:-$HOME/.nvm}"
        node_versions_dir="$resolved_nvm_dir/versions/node"
    fi

    if [ -z "$node_versions_dir" ] || [ ! -d "$node_versions_dir" ]; then
        echo "[npm-g] ERROR: Could not resolve NVM path. Cannot scan alternate Node versions."
        return
    fi

    # Resolve target version directory - sort -V guarantees highest patch version
    local target_path
    target_path=$(ls -1d "$node_versions_dir/v$target_ver"* 2>/dev/null | sort -V | tail -n 1)

    if [ -z "$target_path" ] || [ ! -d "$target_path" ]; then
        echo "[npm-g] ERROR: Node version matching \"v$target_ver\" is not installed locally."
        return
    fi

    local target_name
    target_name=$(basename "$target_path")
    local target_node_modules=""

    # Dynamic node_modules resolution (Windows root vs Mac/Linux lib nesting)
    if [ -d "$target_path/node_modules" ]; then
        target_node_modules="$target_path/node_modules"
    elif [ -d "$target_path/lib/node_modules" ]; then
        target_node_modules="$target_path/lib/node_modules"
    fi

    if [ -z "$target_node_modules" ] || [ ! -d "$target_node_modules" ]; then
        echo "[npm-g] ERROR: node_modules folder missing in $target_name"
        return
    fi

    # Step 1: Pre-hydrate the INSTALLED_LIST strictly from the target node_modules
    INSTALLED_LIST=""
    for folder_path in "$target_node_modules"/*; do
        [ -e "$folder_path" ] || continue
        local folder_name
        folder_name=$(basename "$folder_path")

        if [[ "$folder_name" == @* ]]; then
            # Scoped package directory routing
            for sub_path in "$folder_path"/*; do
                [ -e "$sub_path" ] || continue
                evaluate_package "$folder_name/$(basename "$sub_path")" "$sub_path"
            done
        else
            # Standard package directory routing
            evaluate_package "$folder_name" "$folder_path"
        fi
    done

    # Step 2: Traverse Manifest and compare
    hydrate_manifest_list
    echo ""
    echo "Manifest vs Global Environment List ($target_name):"
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
                        echo "[MISMATCH]  $m_name (Manifest: $m_ver, Target: $cur_ver)"
                    fi
                fi
            else
                echo "[MISSING]   $m_name"
            fi
        fi
    done < "$MANIFEST"

    # Step 3: Print Untracked target packages
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
    resolve_manifest
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

    resolve_manifest
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

    resolve_manifest
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
        echo "[npm-g] Error: Specify at least one package name to append to your manifest."
        return
    fi

    resolve_manifest
    if [ "$MANIFEST_TYPE" = "Global" ] && [ -n "$ACTIVE_MAJOR" ]; then
        echo "[npm-g] (Hint: run 'npm-g edit $ACTIVE_MAJOR' to create a version-specific manifest)"
    fi

    hydrate_manifest_list

    for add_raw in "$@"; do
        parse_package "$add_raw" a_name a_ver
        if is_in_manifest "$a_name"; then
            echo "[npm-g] SKIPPED $a_name as it already exists in $MANIFEST_TYPE manifest."
        else
            echo "$add_raw" >> "$MANIFEST"
            echo "[npm-g] ADDED $add_raw to the $MANIFEST_TYPE manifest file."
            local lower_a_name
            lower_a_name=$(to_lower "$a_name")
            MANIFEST_LIST="${MANIFEST_LIST}${lower_a_name}${nl}"
        fi
    done
}

routine_remove() {
    shift
    if [ $# -eq 0 ]; then
        echo "[npm-g] Error: Specify at least one package definition to strip from configuration."
        return
    fi

    local first_arg="$1"
    if [[ "$first_arg" == .* ]]; then
        local t_manifest_arg="${first_arg#.}"
        local file_to_del
        local del_type

        if [ -z "$t_manifest_arg" ]; then
            resolve_manifest
            if [ "$MANIFEST_TYPE" = "Global" ]; then
                echo "[npm-g] Error: The Global manifest is protected and cannot be purged."
                return
            fi
            file_to_del="$MANIFEST"
            del_type="$MANIFEST_TYPE"
        else
            file_to_del="$DIR/npm-g-$t_manifest_arg.manifest"
            del_type="v$t_manifest_arg"
            if [ ! -f "$file_to_del" ]; then
                echo "[npm-g] Error: Manifest for $del_type does not exist."
                return
            fi
        fi

        rm -f "$file_to_del"
        echo "[npm-g] PURGED $del_type manifest file successfully."
        return
    fi

    resolve_manifest

    local remove_list=""
    for target in "$@"; do
        parse_package "$target" t_name t_ver
        local l_target
        l_target=$(to_lower "$t_name")
        remove_list="${remove_list}${l_target}${nl}"
        echo "[npm-g] REMOVED $target from the $MANIFEST_TYPE manifest file."
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
        routine_list "$2"
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
    edit|-e|e|-edit|--edit|--e)
        routine_edit "$2"
        ;;
    *)
        routine_install_special "$@"
        ;;
esac