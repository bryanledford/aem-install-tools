#!/usr/bin/env bash

_gwt_tmp_files=()

gwt_cleanup() {
  local file

  for file in "${_gwt_tmp_files[@]:-}"; do
    [[ -n "${file}" && -e "${file}" ]] && rm -f "${file}"
  done

  return 0
}

gwt_die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

gwt_require_commands() {
  local cmd

  for cmd in git sort; do
    command -v "${cmd}" >/dev/null 2>&1 || gwt_die "Required command not found: ${cmd}"
  done
}

gwt_has_tui_support() {
  [[ -t 0 && -t 2 ]] || return 1
  command -v stty >/dev/null 2>&1 || return 1
  return 0
}

gwt_supports_color() {
  [[ -t 2 ]] || return 1
  [[ "${TERM:-}" != "dumb" ]] || return 1
  return 0
}

gwt_supports_truecolor() {
  case "${COLORTERM:-}" in
    truecolor|24bit)
      return 0
      ;;
  esac

  case "${TERM:-}" in
    *direct*|*truecolor*)
      return 0
      ;;
  esac

  return 1
}

gwt_init_styles() {
  GWT_STYLE_RESET=""
  GWT_STYLE_DIM=""
  GWT_STYLE_TITLE=""
  GWT_STYLE_SUBTITLE=""
  GWT_STYLE_SELECTED=""
  GWT_STYLE_SELECTED_PATH=""
  GWT_STYLE_SELECTED_BRANCH=""
  GWT_STYLE_SELECTED_META=""
  GWT_STYLE_UNSELECTED=""
  GWT_STYLE_BRANCH=""
  GWT_STYLE_META=""
  GWT_STYLE_HINT=""
  GWT_STYLE_WARNING=""

  if gwt_supports_color; then
    GWT_STYLE_RESET=$'\033[0m'
    GWT_STYLE_DIM=$'\033[2m'

    if gwt_supports_truecolor; then
      GWT_STYLE_TITLE=$'\033[38;2;122;162;247m\033[1m'
      GWT_STYLE_SUBTITLE=$'\033[38;2;169;177;214m'
      GWT_STYLE_SELECTED=$'\033[48;2;125;207;255m\033[38;2;26;27;38m\033[1m'
      GWT_STYLE_SELECTED_PATH=$'\033[48;2;125;207;255m\033[38;2;15;15;20m\033[1m'
      GWT_STYLE_SELECTED_BRANCH=$'\033[48;2;125;207;255m\033[38;2;36;40;59m'
      GWT_STYLE_SELECTED_META=$'\033[48;2;125;207;255m\033[38;2;61;68;96m'
      GWT_STYLE_UNSELECTED=$'\033[38;2;192;202;245m'
      GWT_STYLE_BRANCH=$'\033[38;2;122;162;247m'
      GWT_STYLE_META=$'\033[38;2;169;177;214m'
      GWT_STYLE_HINT=$'\033[38;2;169;177;214m'
      GWT_STYLE_WARNING=$'\033[38;2;255;149;128m\033[1m'
    else
      GWT_STYLE_TITLE=$'\033[38;5;111m\033[1m'
      GWT_STYLE_SUBTITLE=$'\033[38;5;146m'
      GWT_STYLE_SELECTED=$'\033[48;5;117m\033[38;5;16m\033[1m'
      GWT_STYLE_SELECTED_PATH=$'\033[48;5;117m\033[38;5;16m\033[1m'
      GWT_STYLE_SELECTED_BRANCH=$'\033[48;5;117m\033[38;5;17m'
      GWT_STYLE_SELECTED_META=$'\033[48;5;117m\033[38;5;24m'
      GWT_STYLE_UNSELECTED=$'\033[38;5;153m'
      GWT_STYLE_BRANCH=$'\033[38;5;111m'
      GWT_STYLE_META=$'\033[38;5;146m'
      GWT_STYLE_HINT=$'\033[38;5;146m'
      GWT_STYLE_WARNING=$'\033[38;5;209m\033[1m'
    fi
  fi
}

gwt_entry_path() {
  printf '%s\n' "${1%%$'\t'*}"
}

gwt_entry_after_path() {
  local rest="${1#*$'\t'}"
  printf '%s\n' "${rest}"
}

gwt_entry_branch() {
  local rest
  rest="$(gwt_entry_after_path "$1")"
  printf '%s\n' "${rest%%$'\t'*}"
}

gwt_entry_is_main() {
  local rest
  rest="$(gwt_entry_after_path "$1")"
  rest="${rest#*$'\t'}"
  printf '%s\n' "${rest%%$'\t'*}"
}

gwt_entry_is_current() {
  local rest
  rest="$(gwt_entry_after_path "$1")"
  rest="${rest#*$'\t'}"
  rest="${rest#*$'\t'}"
  printf '%s\n' "${rest%%$'\t'*}"
}

gwt_entry_display_path() {
  local path="$1"

  if [[ "${path}" == "${HOME}" ]]; then
    printf '~\n'
    return 0
  fi

  if [[ "${path}" == "${HOME}/"* ]]; then
    printf '~/%s\n' "${path#"${HOME}/"}"
    return 0
  fi

  printf '%s\n' "${path}"
}

gwt_entry_meta() {
  local entry="$1"
  local meta=()

  if [[ "$(gwt_entry_is_main "${entry}")" == "1" ]]; then
    meta+=("main")
  fi

  if [[ "$(gwt_entry_is_current "${entry}")" == "1" ]]; then
    meta+=("current")
  fi

  printf '%s\n' "${meta[*]}"
}

gwt_detect_repo_context() {
  GWT_REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || gwt_die "Run this from inside a Git worktree."
  GWT_REPO_ROOT="$(cd "${GWT_REPO_ROOT}" && pwd)"
  GWT_CURRENT_WORKTREE_ROOT="${GWT_REPO_ROOT}"
  GWT_GIT_COMMON_DIR="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || gwt_die "Could not determine the repository common git dir."
  GWT_GIT_COMMON_DIR="$(cd "${GWT_GIT_COMMON_DIR}" && pwd)"
}

gwt_branch_label() {
  local path="$1"
  local branch_ref="$2"
  local detached="$3"
  local short_head=""

  if [[ -n "${branch_ref}" ]]; then
    printf '%s\n' "${branch_ref#refs/heads/}"
    return 0
  fi

  short_head="$(git -C "${path}" rev-parse --short HEAD 2>/dev/null || true)"
  if [[ "${detached}" == "1" && -n "${short_head}" ]]; then
    printf 'detached @ %s\n' "${short_head}"
    return 0
  fi

  if [[ -n "${short_head}" ]]; then
    printf '%s\n' "${short_head}"
    return 0
  fi

  printf '(unknown)\n'
}

gwt_commit_epoch() {
  local path="$1"
  local epoch

  epoch="$(git -C "${path}" log -1 --format=%ct HEAD 2>/dev/null || true)"
  if [[ "${epoch}" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "${epoch}"
  else
    printf '0\n'
  fi
}

gwt_emit_sorted_entries() {
  local include_main="$1"
  local include_current="$2"
  local sort_mode="$3"
  local line=""
  local path=""
  local branch_ref=""
  local detached=0
  local git_dir=""
  local branch_label=""
  local is_main=0
  local is_current=0
  local epoch=0
  local sortable=""
  local rows=()

  finalize_entry() {
    [[ -n "${path}" ]] || return 0

    git_dir="$(git -C "${path}" rev-parse --absolute-git-dir 2>/dev/null || true)"
    is_main=0
    is_current=0

    [[ "${git_dir}" == "${GWT_GIT_COMMON_DIR}" ]] && is_main=1
    [[ "${path}" == "${GWT_CURRENT_WORKTREE_ROOT}" ]] && is_current=1

    if [[ "${include_main}" != "1" && "${is_main}" == "1" ]]; then
      path=""
      branch_ref=""
      detached=0
      return 0
    fi

    if [[ "${include_current}" != "1" && "${is_current}" == "1" ]]; then
      path=""
      branch_ref=""
      detached=0
      return 0
    fi

    branch_label="$(gwt_branch_label "${path}" "${branch_ref}" "${detached}")"
    epoch="$(gwt_commit_epoch "${path}")"
    sortable="$(printf '%010d\t%s\t%s\t%s\t%s\n' "${epoch}" "${path}" "${branch_label}" "${is_main}" "${is_current}")"
    rows+=("${sortable}")

    path=""
    branch_ref=""
    detached=0
    return 0
  }

  while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ -z "${line}" ]]; then
      finalize_entry
      continue
    fi

    case "${line}" in
      worktree\ *)
        path="${line#worktree }"
        ;;
      branch\ *)
        branch_ref="${line#branch }"
        ;;
      detached)
        detached=1
        ;;
    esac
  done < <(git -C "${GWT_REPO_ROOT}" worktree list --porcelain)

  finalize_entry

  if [[ "${sort_mode}" == "recent" ]]; then
    printf '%s\n' "${rows[@]}" | sort -r -t $'\t' -k1,1n -k2,2f
    return 0
  fi

  printf '%s\n' "${rows[@]}" | sort -f -t $'\t' -k2,2
}

gwt_load_worktree_entries() {
  local include_main="$1"
  local include_current="$2"
  local sort_mode="$3"
  local row=""

  GWT_WORKTREE_ENTRIES=()

  while IFS= read -r row; do
    [[ -n "${row}" ]] || continue
    GWT_WORKTREE_ENTRIES+=("${row#*$'\t'}")
  done < <(gwt_emit_sorted_entries "${include_main}" "${include_current}" "${sort_mode}")
}

gwt_render_worktree_menu() {
  local title="$1"
  local subtitle="$2"
  local footer="$3"
  local selected="$4"
  shift 4
  local entries=("$@")
  local i path branch meta display_path

  printf '%s%s%s\n' "${GWT_STYLE_TITLE}" "${title}" "${GWT_STYLE_RESET}" >&2
  if [[ -n "${subtitle}" ]]; then
    printf '%s%s%s\n' "${GWT_STYLE_SUBTITLE}" "${subtitle}" "${GWT_STYLE_RESET}" >&2
  fi

  for i in "${!entries[@]}"; do
    path="$(gwt_entry_path "${entries[$i]}")"
    branch="$(gwt_entry_branch "${entries[$i]}")"
    meta="$(gwt_entry_meta "${entries[$i]}")"
    display_path="$(gwt_entry_display_path "${path}")"

    if [[ "${i}" -eq "${selected}" ]]; then
      if [[ -n "${meta}" ]]; then
        printf '  %s[ %s%s%s ]  %s[%s]%s  %s[%s]%s%s\n' \
          "${GWT_STYLE_SELECTED}" "${GWT_STYLE_SELECTED_PATH}" "${display_path}" "${GWT_STYLE_SELECTED}" \
          "${GWT_STYLE_SELECTED_BRANCH}" "${branch}" "${GWT_STYLE_SELECTED}" \
          "${GWT_STYLE_SELECTED_META}" "${meta}" "${GWT_STYLE_SELECTED}" "${GWT_STYLE_RESET}" >&2
      else
        printf '  %s[ %s%s%s ]  %s[%s]%s%s\n' \
          "${GWT_STYLE_SELECTED}" "${GWT_STYLE_SELECTED_PATH}" "${display_path}" "${GWT_STYLE_SELECTED}" \
          "${GWT_STYLE_SELECTED_BRANCH}" "${branch}" "${GWT_STYLE_SELECTED}" "${GWT_STYLE_RESET}" >&2
      fi
    else
      if [[ -n "${meta}" ]]; then
        printf '  %s%s%s  %s[%s]%s  %s[%s]%s\n' \
          "${GWT_STYLE_UNSELECTED}" "${display_path}" "${GWT_STYLE_RESET}" \
          "${GWT_STYLE_BRANCH}" "${branch}" "${GWT_STYLE_RESET}" \
          "${GWT_STYLE_META}" "${meta}" "${GWT_STYLE_RESET}" >&2
      else
        printf '  %s%s%s  %s[%s]%s\n' \
          "${GWT_STYLE_UNSELECTED}" "${display_path}" "${GWT_STYLE_RESET}" \
          "${GWT_STYLE_BRANCH}" "${branch}" "${GWT_STYLE_RESET}" >&2
      fi
    fi
  done

  printf '%s%s%s\n' "${GWT_STYLE_HINT}" "${footer}" "${GWT_STYLE_RESET}" >&2
}

gwt_pick_worktree_entry() {
  local title="$1"
  local subtitle="$2"
  local footer="${3:-Press q to cancel.}"
  shift 3
  local entries=("$@")
  local selected=0
  local key=""
  local key2=""
  local key3=""
  local rendered=0
  local subtitle_lines=0
  [[ -n "${subtitle}" ]] && subtitle_lines=1
  local lines=$(( ${#entries[@]} + 2 + subtitle_lines ))
  local old_stty

  [[ ${#entries[@]} -gt 0 ]] || return 1
  [[ -t 0 && -t 2 ]] || return 1

  gwt_init_styles
  old_stty="$(stty -g)"

  restore_terminal() {
    stty "${old_stty}"
    command -v tput >/dev/null 2>&1 && tput cnorm >&2 2>/dev/null || true
  }

  render_menu() {
    if [[ ${rendered} -eq 1 ]]; then
      printf '\r\033[%dA\033[J' "${lines}" >&2
    fi

    gwt_render_worktree_menu "${title}" "${subtitle}" "${footer}" "${selected}" "${entries[@]}"
    rendered=1
  }

  trap 'restore_terminal; printf "\n" >&2; exit 130' INT TERM
  stty -echo -icanon time 1 min 0
  command -v tput >/dev/null 2>&1 && tput civis >&2 2>/dev/null || true

  render_menu

  while true; do
    if ! IFS= read -rsn1 key; then
      continue
    fi

    case "${key}" in
      ""|$'\n'|$'\r')
        restore_terminal
        trap - INT TERM
        printf '\r\033[%dA\033[J' "${lines}" >&2
        printf '%s\n' "${entries[$selected]}"
        return 0
        ;;
      j)
        ((selected < ${#entries[@]} - 1)) && ((selected++))
        ;;
      k)
        ((selected > 0)) && ((selected--))
        ;;
      q)
        restore_terminal
        trap - INT TERM
        printf '\r\033[%dA\033[J' "${lines}" >&2
        return 2
        ;;
      $'\x1b')
        IFS= read -rsn1 key2 || true
        IFS= read -rsn1 key3 || true
        case "${key2}${key3}" in
          "[A") ((selected > 0)) && ((selected--)) ;;
          "[B") ((selected < ${#entries[@]} - 1)) && ((selected++)) ;;
        esac
        ;;
    esac

    render_menu
  done
}

gwt_render_confirmation_menu() {
  local title="$1"
  local detail="$2"
  local selected="$3"
  shift 3
  local options=("$@")
  local i

  printf '%s%s%s\n' "${GWT_STYLE_TITLE}" "${title}" "${GWT_STYLE_RESET}" >&2
  printf '%s%s%s\n' "${GWT_STYLE_WARNING}" "${detail}" "${GWT_STYLE_RESET}" >&2

  for i in "${!options[@]}"; do
    if [[ "${i}" -eq "${selected}" ]]; then
      printf '  %s[ %s%s%s ]%s\n' \
        "${GWT_STYLE_SELECTED}" "${GWT_STYLE_SELECTED_PATH}" "${options[$i]}" "${GWT_STYLE_SELECTED}" "${GWT_STYLE_RESET}" >&2
    else
      printf '  %s%s%s\n' "${GWT_STYLE_UNSELECTED}" "${options[$i]}" "${GWT_STYLE_RESET}" >&2
    fi
  done

  printf '%sPress q to cancel.%s\n' "${GWT_STYLE_HINT}" "${GWT_STYLE_RESET}" >&2
}

gwt_confirm_remove_choice() {
  local path="$1"
  local branch="$2"
  local options=("No" "Yes" "Force")
  local selected=0
  local key=""
  local key2=""
  local key3=""
  local rendered=0
  local lines=6
  local old_stty
  local detail=""

  [[ -t 0 && -t 2 ]] || return 1

  gwt_init_styles
  old_stty="$(stty -g)"
  detail="$(printf 'Remove %s [%s]?' "$(gwt_entry_display_path "${path}")" "${branch}")"

  restore_terminal() {
    stty "${old_stty}"
    command -v tput >/dev/null 2>&1 && tput cnorm >&2 2>/dev/null || true
  }

  render_menu() {
    if [[ "${rendered}" -eq 1 ]]; then
      printf '\r\033[%dA\033[J' "${lines}" >&2
    fi

    gwt_render_confirmation_menu "Remove this worktree?" "${detail}" "${selected}" "${options[@]}"
    rendered=1
  }

  trap 'restore_terminal; printf "\n" >&2; exit 130' INT TERM
  stty -echo -icanon time 1 min 0
  command -v tput >/dev/null 2>&1 && tput civis >&2 2>/dev/null || true

  render_menu

  while true; do
    if ! IFS= read -rsn1 key; then
      continue
    fi

    case "${key}" in
      ""|$'\n'|$'\r')
        restore_terminal
        trap - INT TERM
        printf '\r\033[%dA\033[J' "${lines}" >&2
        printf '%s\n' "${options[$selected]}"
        return 0
        ;;
      j)
        ((selected < ${#options[@]} - 1)) && ((selected++))
        ;;
      k)
        ((selected > 0)) && ((selected--))
        ;;
      q)
        restore_terminal
        trap - INT TERM
        printf '\r\033[%dA\033[J' "${lines}" >&2
        return 2
        ;;
      $'\x1b')
        IFS= read -rsn1 key2 || true
        IFS= read -rsn1 key3 || true
        case "${key2}${key3}" in
          "[A") ((selected > 0)) && ((selected--)) ;;
          "[B") ((selected < ${#options[@]} - 1)) && ((selected++)) ;;
        esac
        ;;
    esac

    render_menu
  done
}
