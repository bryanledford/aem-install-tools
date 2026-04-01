#!/usr/bin/env bash
# Bash/Zsh completion for aem-install, aem-package-install, aem-bundle-install,
# git-worktree-jump, and git-worktree-remove
#
# To load in bash:
#   source /path/to/aem-tools/completions/aem-tools-completion.bash
#
# To load in zsh (bashcompinit required):
#   autoload -U +X bashcompinit && bashcompinit
#   source /path/to/aem-tools/completions/aem-tools-completion.bash

_aem_package_install_complete() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local flags="--dry-run --shallow --disable-workflows --help -l"
  local opts="-p -u -P"

  case "${prev}" in
    -p|-u|-P) return 0 ;;
  esac

  case "${cur}" in
    -*)
      COMPREPLY=( $(compgen -W "${flags} ${opts}" -- "${cur}") )
      return 0
      ;;
  esac

  compopt -o filenames 2>/dev/null
  COMPREPLY=( $(compgen -f -X '!*.zip' -- "${cur}") $(compgen -d -- "${cur}") )
}

_aem_bundle_install_complete() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local flags="--dry-run --no-refresh --no-start --help -l"
  local opts="-p -u -P --start-level"

  case "${prev}" in
    -p|-u|-P|--start-level) return 0 ;;
  esac

  case "${cur}" in
    -*)
      COMPREPLY=( $(compgen -W "${flags} ${opts}" -- "${cur}") )
      return 0
      ;;
  esac

  compopt -o filenames 2>/dev/null
  COMPREPLY=( $(compgen -f -X '!*.jar' -- "${cur}") $(compgen -d -- "${cur}") )
}

_aem_install_complete() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Peek at the artifact already on the line to decide which flags to show
  local artifact=""
  local word
  for word in "${COMP_WORDS[@]:1}"; do
    case "${word}" in
      -*) ;;
      *.zip|*.jar) artifact="${word}"; break ;;
    esac
  done

  case "${prev}" in
    -p|-u|-P|--start-level) return 0 ;;
  esac

  case "${cur}" in
    -*)
      local flags="--dry-run --help -p -u -P -l"
      case "${artifact}" in
        *.zip) flags="${flags} --shallow --disable-workflows" ;;
        *.jar) flags="${flags} --no-refresh --no-start --start-level" ;;
        *)     flags="${flags} --shallow --disable-workflows --no-refresh --no-start --start-level" ;;
      esac
      COMPREPLY=( $(compgen -W "${flags}" -- "${cur}") )
      return 0
      ;;
  esac

  compopt -o filenames 2>/dev/null
  COMPREPLY=( $(compgen -f -X '!*.zip' -- "${cur}") \
              $(compgen -f -X '!*.jar' -- "${cur}") \
              $(compgen -d -- "${cur}") )
}

_git_worktree_picker_complete() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "${prev}" in
    --sort)
      COMPREPLY=( $(compgen -W "name recent" -- "${cur}") )
      return 0
      ;;
  esac

  case "${cur}" in
    -*)
      COMPREPLY=( $(compgen -W "--sort --help -h" -- "${cur}") )
      return 0
      ;;
  esac

  COMPREPLY=()
}

complete -F _aem_package_install_complete aem-package-install
complete -F _aem_bundle_install_complete  aem-bundle-install
complete -F _aem_install_complete         aem-install
complete -F _git_worktree_picker_complete git-worktree-jump
complete -F _git_worktree_picker_complete git-worktree-remove
