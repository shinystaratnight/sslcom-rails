# export PATH=$HOME/bin:/usr/local/bin:$PATH

### MANUAL SHELL INTEGRATIONS ###
export EDITOR="vim"
export GITHUB_OAUTH_TOKEN=
export ZSH_DISABLE_COMPFIX=true
export TERM="xterm-256color"
###

export ZSH=/usr/share/oh-my-zsh
export ZSH_CACHE_DIR=$HOME/.oh-my-zsh/cache

POWERLEVEL9K_MODE="nerdfont-complete"

POWERLEVEL9K_RVM_BACKGROUND="red"
POWERLEVEL9K_RVM_FOREGROUND="white"
POWERLEVEL9K_RVM_VISUAL_IDENTIFIER_COLOR="white"

POWERLEVEL9K_TIME_BACKGROUND="blue"
POWERLEVEL9K_TIME_FOREGROUND="white"
POWERLEVEL9K_TIME_FORMAT="%D{%H:%M %d.%m.%y}"
POWERLEVEL9K_TIME_VISUAL_IDENTIFIER_COLOR="white"

POWERLEVEL9K_VCS_CLEAN_FOREGROUND="black"
POWERLEVEL9K_VCS_CLEAN_BACKGROUND="green"
POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND="black"
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND="green"
POWERLEVEL9K_VCS_MODIFIED_FOREGROUND="black"
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND="yellow"
POWERLEVEL9K_VCS_GIT_ICON=""
POWERLEVEL9K_VCS_GIT_GITLAB_ICON="\uf296 "
POWERLEVEL9K_VCS_GIT_GITHUB_ICON="\ufbd9 "
POWERLEVEL9K_HIDE_BRANCH_ICON=true

POWERLEVEL9K_HOME_ICON="\uf015 "
POWERLEVEL9K_HOME_SUB_ICON="\uf07c "
POWERLEVEL9K_FOLDER_ICON="\uf07b "
POWERLEVEL9K_ETC_ICON="\uf013 "

POWERLEVEL9K_DIR_HOME_FOREGROUND='white'
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND='white'
POWERLEVEL9K_DIR_ETC_FOREGROUND='red'
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND='white'

POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%F{000}%K{003} \uf007 %n %F{003}%K{005}\ue0b0%K{005}%F{white} \uf308  %m %F{005}%K{blue}\ue0b0"
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{005}\uF460%F{blue}\uF460%F{white}\uF460%F{white} "

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=('dir' 'vcs')
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=('rvm' 'ruby_version' 'time')

ZSH_THEME="powerlevel9k/powerlevel9k"

plugins=(git rvm dotenv ruby)

source $ZSH/oh-my-zsh.sh

prompt_ruby_version() {
  local version=$(ruby -v | awk -F' ' '{print $2}' | awk -F'p' '{print $1}')
  "$1_prompt_segment" "$0" "$2" "red" "white" "$version" 'RUBY_ICON'
}

prompt_rvm() {
  local gemset=$(echo $GEM_HOME | awk -F'@' '{print $2}')
  [ "$gemset" != "" ] && gemset="@$gemset"

  local version=$(echo $MY_RUBY_HOME | awk -F'-' '{print $2}')

  if [[ -n "$version$gemset" ]]; then
    "$1_prompt_segment" "$0" "$2" "240" "$DEFAULT_COLOR" "$version$gemset" 'RUBY_ICON'
  fi
}
