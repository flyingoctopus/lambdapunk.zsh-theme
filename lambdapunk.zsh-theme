#!/usr/bin/env zsh
# Monokai-inspired colors for VCS status
local WHITE=255
local ORANGE=208
local GREEN=118
local PINK=201
local HOT_PINK=204
local YELLOW=227
local CYAN=81
local BLUE=75
local DIMGREYA=245
local DIMGREYB=242
local DIMGREYC=240
local DARK_GREY=236
local RED=160

# Use ॐ and λ directly in the LAMBDA symbol
local LAMBDA="%(?,%F{white}ॐ%f ,%F{$RED}λ%f)"
if [[ "$USER" == "root" ]]; then USERCOLOR="$RED"; else USERCOLOR="$PINK"; fi

# Function to handle the tilde (~) positioning based on prompt width
function position_tilde() {
    local prompt_width=$((${#LAMBDA} + ${#USER} + ${#HOST} + ${#PWD}))
    local git_status_width=$((${#$(check_vcs_prompt_info)}))
    local pkg_manager_status_width=$((${#$(check_pkg_manager_info)}))
    local total_width=$((pkg_manager_status_width + prompt_width + git_status_width + 20)) # buffer for extra characters

    if (( total_width > $(tput cols) )); then
        # echo -n '\n %F{$DIMGREYA}~%f ' # New line if prompt is too long
        echo -n '\n %F{white}~%f ' # New line if prompt is too long
    else
        # echo -n '%F{$DIMGREYA}~%f '    # Same line if prompt fits
        echo -n '%F{white}~%f '    # Same line if prompt fits
    fi
}

# VCS status function with color handling
function check_vcs_prompt_info() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Check if the repository has any commits
        if git rev-parse --verify HEAD > /dev/null 2>&1; then
            local branch_name=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null)
            local short_sha=$(git rev-parse --short HEAD)
            local local_git_prompt="%F{$ORANGE} %f"
            if [[ -z $branch_name ]]; then
                # Detached HEAD state with colors and status
                local_git_prompt+="$(git_prompt_status)%F{$CYAN} %f"
            else
                local_git_prompt+="$(git_prompt_status) %F{white}on%f %F{$BLUE}$branch_name%f %F{$GREEN}%f"
                RPROMPT="%F{$PINK}[%f%F{white}${short_sha}%f%F{$PINK}]%f"
            fi
            echo "$local_git_prompt"
        else
            # No commits yet
            # echo "%F{$ORANGE} %f %F{$YELLOW}No commits yet%f"
            echo "%F{$ORANGE} %f"
        fi
    elif hg root > /dev/null 2>&1; then
        hg_branch=$(hg branch 2>/dev/null)
        echo "%F{$PINK}%f %F{$YELLOW}%f %F{white}$hg_branch $(hg prompt '{status}')%f"
        RPROMPT=""
    else
        RPROMPT=""
    fi
}

# === PKG MANAGEMENT CHECK ===
local IS_USING_PKG_MANAGER=false

# naive nix-shell check
function check_nixshell {
  if [[ -n "$IN_NIX_SHELL" ]]; then
    IS_USING_PKG_MANAGER=true
    echo "%F{$CYAN}󱄅%f%F{$ORANGE}[%f%F{white}$name%f%F{white}%f%F{$ORANGE}]%f "
  fi
}

function set_conda() {
  # (( ${+commands[conda]} )) || return 0
  IS_USING_PKG_MANAGER=true
}

# naive venv check
function check_venv {
  if [[ ${VIRTUAL_ENV} ]]
  then
    IS_USING_PKG_MANAGER=true
    echo "%F{$CYAN}%f%F{$ORANGE}[%f%F{white}$(basename "$VIRTUAL_ENV")]%f%F{$ORANGE}]%f "
  fi
}

# jankled with love: https://github.com/CurryEleison/zsh-asdf-prompt/blob/main/zsh-asdf-prompt.plugin.zsh
function check_asdf_info() {
  # If asdf isn't present nothing to do
  (( ${+commands[asdf]} )) || return 0
  IS_USING_PKG_MANAGER=true
  local currenttools=$(asdf current 2> /dev/null)
  local toolvers_fname=${ASDF_DEFAULT_TOOL_VERSIONS_FILENAME-.tool-versions}
  # Decide how we filter what is shown
  if [[ $ZSH_THEME_ASDF_PROMPT_FILTER != "ALL" ]]; then
    currenttools=$(echo $currenttools | grep -v ' system ' -)
  fi
  if [[ -z "${ZSH_THEME_ASDF_PROMPT_FILTER// }" \
      || $ZSH_THEME_ASDF_PROMPT_FILTER == "COMPACT" ]]; then
    currenttools=$(echo $currenttools | grep -v "$HOME/$toolvers_fname" -)
  fi

  # Decide if anything is left to process and return if not.
  [[ -z "${currenttools// }" ]] && return

  local toolslist=$(echo $currenttools | awk '{ print $1 }')
  local versionslist
  # Decide if we do semi-major version (default) or full version info
  if [[ $ZSH_THEME_ASDF_PROMPT_VERSION_DETAIL == "PATCH" ]]; then
    versionslist=$(echo $currenttools | awk '{ print $2 }' - )
  elif [[ $ZSH_THEME_ASDF_PROMPT_VERSION_DETAIL == "MAJOR" ]]; then
    versionslist=$(echo $currenttools | awk '{ print $2 }' - \
      | sed -E 's/([^\.]*)(\.[^\.]*)(\..*)/\1/g'  \
      | sed 's/system/s/g' )
  else
    versionslist=$(echo $currenttools | awk '{ print $2 }' - \
      | sed -E 's/([^\.]*)(\.[^\.]*)(\..*)/\1\2/g'  \
      | sed 's/system/sys/g' )
  fi
  # Decide if we want to print out origins or not (default)
  local originslist
  if [[ $ZSH_THEME_ASDF_PROMPT_VERSION_RESOLUTION == "COMPACT" ]]; then
    originslist=$(echo $currenttools \
      | awk '{ $1=$2=""; print $0 }' \
      | sed 's/^ *//g' \
      | sed -E 's#ASDF_.*VERSION#\$#' \
      | sed -E "s#$HOME\/*($toolvers_fname|\.[^\/]+)\$#\~#" \
      | sed -E "s#$PWD\/*($toolvers_fname|\.[^\/]+)\$#\.#" \
      | sed -E "s#($HOME\/.+)#\/#" )
  else
    originslist=$(echo $currenttools | awk '{ print ""}' -)
  fi
  # Paste columns together
  local reassembled=$(paste  <(echo $toolslist) <(echo $versionslist) \
    <(echo $originslist))
  # Structure info in nice, separate lines
  local multilinesummary=$(echo $reassembled \
    | awk '{ print $1 ": " $2 $3 }' - )
  # If more than one line, scrunch them up
  local asdfsummary=$( [[ $( echo $multilinesummary | wc -l ) -le 1 ]] \
    && echo $multilinesummary \
    || (echo $multilinesummary | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/, /g'))

  # Oddly formatted to avoid spurious spaces
  echo " ${ZSH_THEME_ASDF_PROMPT_PREFIX-\{}"\
"${asdfsummary}${ZSH_THEME_ASDF_PROMPT_POSTFIX-\}}"
}

function check_pkg_manager_info() {
  if [[ $IS_USING_PKG_MANAGER ]]; then
    echo "%F{white}using%f $(set_conda)$(conda_prompt_info)$(check_nixshell)$(check_venv)"
  fi
}

# Main left prompt definition
PROMPT='
${LAMBDA}\
 %F{$USERCOLOR}%n%f\
 %F{white}in%f\
 %F{#CYAN}%m%f\
 $(check_pkg_manager_info)\
 %F{yellow}[%f%F{white}%3~%f%F{yellow}]%f\
 $(check_vcs_prompt_info) $(position_tilde)'

function setup_rprompt() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        if git rev-parse --verify HEAD > /dev/null 2>&1; then
            # Repository has commits
            if [[ -z $(git symbolic-ref --short HEAD 2> /dev/null) ]]; then
                # Detached HEAD state
                RPROMPT="%F{$ORANGE}[%F{white}$(git rev-parse HEAD)%F{$ORANGE}]%f"
            else
                # On a branch
                RPROMPT="%F{$PINK}[%F{white}$(git rev-parse --short HEAD)%F{$PINK}]%f"
            fi
        else
            # Repository exists but no commits yet
            RPROMPT="%F{$YELLOW}[No commits yet]%f"
        fi
    else
        # Not a Git repository
        RPROMPT=""
    fi
}

# Define the status line function with seconds-only timing
command_status_line() {
    if [[ -n $LAST_COMMAND_START ]]; then
        # Calculate the duration in seconds
        local duration_sec=$(( SECONDS - LAST_COMMAND_START ))

        # Capture the end time in seconds
        local command_end_time=$(date +'%H:%M:%S')

        # Display the duration and start/end times in seconds
        print -P "%F{white}⏱%f %F{yellow}:%f %F{$DARK_GREY}${duration_sec}s%f %F{yellow}:%f %F{$DARK_GREY}${COMMAND_START_TIME}%f %F{yellow}➔%f %F{$DARK_GREY}${command_end_time}%f"
    fi
}

# Record the start time in seconds
preexec() {
    LAST_COMMAND_START=$SECONDS
    COMMAND_START_TIME=$(date +'%H:%M:%S')
}

# Add the status line function to precmd_functions
precmd_functions+=(command_status_line)
precmd_functions+=(setup_rprompt)

# Git status format
ZSH_THEME_GIT_PROMPT_PREFIX="at %F{$BLUE}%f "
ZSH_THEME_GIT_PROMPT_SUFFIX="{$reset_color}"
ZSH_THEME_GIT_PROMPT_DIRTY="%F{$ORANGE}Δ%f"
ZSH_THEME_GIT_PROMPT_CLEAN="%F{$GREEN}✔%f"

# Git status symbols with explicit colors
ZSH_THEME_GIT_PROMPT_ADDED="%F{$GREEN} %f"
ZSH_THEME_GIT_PROMPT_MODIFIED="%F{$YELLOW}±%f"
ZSH_THEME_GIT_PROMPT_DELETED="%F{$PINK} %f"
ZSH_THEME_GIT_PROMPT_RENAMED="%F{$ORANGE} %f"
ZSH_THEME_GIT_PROMPT_UNMERGED="%F{$YELLOW}%f"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%F{$CYAN} %f"

# Format for git_prompt_ahead
ZSH_THEME_GIT_PROMPT_AHEAD="%F{orange}  %f"
ZSH_THEME_GIT_PROMPT_BEHIND="%F{$RED} %f"

# SHA status brackets with consistent color control
ZSH_THEME_GIT_PROMPT_SHA_BEFORE=" %F{white}[%F{$PINK}%f"
ZSH_THEME_GIT_PROMPT_SHA_AFTER="%F{white}]%f"

# conda plugin values
ZSH_THEME_CONDA_PREFIX="%F{$GREEN}%f %F{$ORANGE}"
ZSH_THEME_CONDA_SUFFIX="%f"

# Default values for check_asdf_info
ZSH_THEME_ASDF_PROMPT_PREFIX="%F{$PINK}[%f%F{white}"
ZSH_THEME_ASDF_PROMPT_POSTFIX="%f%F{$PINK}]%f"
ZSH_THEME_ASDF_PROMPT_FILTER="COMPACT"
ZSH_THEME_ASDF_PROMPT_VERSION_DETAIL="MINOR"
ZSH_THEME_ASDF_PROMPT_VERSION_RESOLUTION="NONE"
