
# Couleurs 
export PS1="\[\e[1;34m\]\u@\h:\w\$\[\e[0m\] "


alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'
alias cls='clear'
alias ..='cd ..'

# la complétion 
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi


export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=5000
export HISTFILESIZE=10000


shopt -s checkwinsize  # la taille du terminal automatiquement
shopt -s autocd        # Aller dans un dossier sans taper 'cd'
shopt -s dirspell      # Corriger automatiquement les fautes dans cd

