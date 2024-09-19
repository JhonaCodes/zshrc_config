# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="edvardm"
ZSH_THEME=""
# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git rust sdk ssh zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Nivagion on filtered hostory
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Define la información de la rama de Git y commits
git_prompt_info() {
  # Verificar si estamos en un repositorio Git
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return
  fi

  local branch
  local ahead=0
  local behind=0
  local git_status
  local stashed
  local project_name
  local output
  local modified
  local untracked
  local staged
  local is_remote_branch
  local remote_status
  local current_commit

  # Obtener el nombre del proyecto (último componente del path del repositorio)
  project_name=$(basename "$(git rev-parse --show-toplevel)")

  # Obtener la rama actual
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

  # Obtener el hash abreviado del commit actual
  current_commit=$(git rev-parse --short HEAD)

  # Verificar si la rama está en remoto
  if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    is_remote_branch=true
  else
    is_remote_branch=false
  fi

  remote_branch=$(git for-each-ref --format '%(refname:short)' refs/remotes/origin/ | grep -E '^origin/(main|master)' | head -n 1 | sed 's/^origin\///')

  # Obtener el número de commits adelante y atrás respecto a la rama remota
  if [[ "$is_remote_branch" == true ]]; then
    ahead=$(git rev-list --count "$branch" ^"origin/$remote_branch" 2>/dev/null || echo 0)
    behind=$(git rev-list --count "origin/$branch".."$branch" 2>/dev/null || echo 0)
  else
    # Para ramas locales que no tienen rama remota asociada
    ahead=$(git rev-list --count "$branch" ^main 2>/dev/null || echo 0)

    behind=0
  fi

  # Obtener el estado del repositorio
  git_status=$(git status --porcelain)

  # Contar archivos modificados, sin seguimiento y staged
  modified=$(echo "$git_status" | grep '^ M' | wc -l | tr -d ' ')
  untracked=$(echo "$git_status" | grep '^??' | wc -l | tr -d ' ')
  staged=$(git diff --cached --name-only | wc -l | tr -d ' ')

  # Verificar si hay cambios stashed
  if git rev-parse --verify refs/stash >/dev/null 2>&1; then
    stashed="%{$fg_bold[cyan]%}⚑%{$reset_color%}"
  else
    stashed=""
  fi

  # Determinar el estado de conexión
  if [[ "$is_remote_branch" == true ]]; then
    if [[ $ahead -gt 0 || $behind -gt 0 ]]; then
      remote_status="%{$fg_bold[red]%}🟥%{$reset_color%}"  # Desincronizado
    else
      remote_status="%{$fg_bold[green]%}🟩%{$reset_color%}"  # Sincronizado
    fi
  else
    remote_status="%{$fg_bold[yellow]%}🟧%{$reset_color%}"  # Solo local
  fi

  # Construir la cadena de salida
  output+="%{$fg_bold[green]%}🌿 Git: %{$reset_color%}"
  output+="%{$fg_bold[blue]%}$project_name %{$reset_color%}"
  output+="$remote_status "
  output+="%{$fg_bold[yellow]%}[$branch]%{$reset_color%}"
  output+="%{$fg_bold[red]%} $current_commit%{$reset_color%} "

  if [[ -n $git_status ]]; then
    output+="%{$fg_bold[red]%}✗%{$reset_color%} "
  else
    output+="%{$fg_bold[green]%}✓%{$reset_color%} "
  fi

  output+="%{$fg_bold[white]%}[%{$reset_color%}"
  output+="%{$fg[yellow]%}📬:$staged%{$reset_color%}, "
  output+="%{$fg[red]%}✏️:$modified%{$reset_color%}, "
  output+="%{$fg[blue]%}❓:$untracked%{$reset_color%}"
  output+="%{$fg_bold[white]%}]%{$reset_color%}"

  # Mostrar commits ahead/behind
  if [[ $ahead -gt 0 || $behind -gt 0 ]]; then
    [[ $ahead -gt 0 ]] && output+="%{$fg_bold[green]%} ↑$ahead"
    [[ $behind -gt 0 ]] && output+="%{$fg_bold[red]%} ↓$behind"
  fi

  output+="$stashed"

  echo -n "$output"
}

# Configura el prompt
PROMPT='$(git_prompt_info)
%{$fg_bold[cyan]%}|%{$fg_bold[green]%}Jhonacode%{$fg_bold[cyan]%}|-> '