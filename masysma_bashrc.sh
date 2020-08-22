# Ma_Sys.ma Bashrc 2.0.2, Copyright (c) 2013-2017, 2019, 2020 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de

[ -n "$PS1" ] || return # Terminate when not running interactively

# ============================================================== RUN SYSSHEET ==
export LINES
export COLUMNS
sheetpid=
if [ -z "$MAEM_RES" ]; then
	/usr/bin/syssheet -f & # Syssheet is slow => Parallelization is good
	sheetpid=$!
else
	sheetpid=-1
fi

# ====================================================== BASIC SHELL SETTINGS ==
HISTCONTROL=ignoredups:ignorespace
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
shopt -s checkwinsize

# https://serverfault.com/questions/208265
set +H
set -o vi

# ========================================================== CONFIGURE PROMPT ==
if [ -z "$MAEM_RES" ]; then
	ma_host_tmp="$(who -m | cut -d "(" -f 2 | tr -d ")" | cut -d "." -f 1)"
	ma_tty_tmp="$(echo $ma_host_tmp | cut -d " " -f 2 | cut -c -3)"
	if [ -e /.dockerenv ] || { [ -x /usr/bin/ischroot ] && ischroot; }; then
		# container
		export PS1='\[\033[36;40;1m\]\H:\w\$\[\033]0;\H:\w\$\007\033[00m\] '
	elif [ -z "$ma_host_tmp" -o "$ma_host_tmp" = ":0" -o \
						"$ma_tty_tmp" = "tty" ]; then
		# local
		export PS1='\[\033[33;40;1m\]\w\$\[\033]0;\w\$\007\033[00m\] '
	else
		# remote
		export PS1='\[\033[31;40;1m\]\H:\w\$\[\033]0;\H:\w\$\007\033[00m\] '
	fi
	unset ma_tty_tmp
	unset ma_host_tmp
fi

# ======================================================== EDITORS AND PAGERS ==
if [ -x /usr/bin/vim ]; then
	export EDITOR=vim
else
	export EDITOR=vi
fi

# -> http://stackoverflow.com/questions/26524559/git-commands-execution-like-
# 				git-diff-or-git-help-commit-returns-errors-abo
export PAGER=/usr/bin/less

# Vimpager for manpages
# http://vim.wikia.com/wiki/Using_vim_as_a_man-page_viewer_under_Unix
export MANPAGER="/bin/sh -c \"unset PAGER;col -b -x | \
	vim -R -c 'set ft=man nomod nolist nonumber' -c 'map q :q<CR>' \
	-c 'map <SPACE> <C-D>' -c 'map b <C-U>' \
	-c 'nmap K :Man <C-R>=expand(\\\"<cword>\\\")<CR><CR>' -\""

# ================================================================== SET PATH ==
export PATH="$PATH:/sbin:/usr/sbin:/usr/local/sbin"
if [ -d "/usr/lib/mdvl-lejos-nxj" ]; then
	export NXJ_HOME=/usr/lib/mdvl-lejos-nxj
	export PATH="$PATH:$NXJ_HOME/bin"
fi
if [ -d "$HOME/.mdvl/user_bin" ]; then
	export PATH="$PATH:$HOME/.mdvl/user_bin"
fi

# ====================================================================== JAVA ==
arch="$(dpkg --print-architecture)"
if [ -d "/usr/lib/jvm/java-6-openjdk" ]; then
	export JAVA_HOME=/usr/lib/jvm/java-6-openjdk
elif [ -d "/usr/lib/jvm/java-7-openjdk-$arch" ]; then
	export JAVA_HOME="/usr/lib/jvm/java-7-openjdk-$arch"
elif [ -d "/usr/lib/jvm/java-8-openjdk-$arch" ]; then
	export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-$arch"
fi
# Although this should be automatically imported, it is not and therefore the
# files are listed here. Seems to be a bug (noted 02.2013).
export CLASSPATH=.:/usr/share/java/j3dcore.jar:/usr/share/java/j3dutils.jar
export CLASSPATH="$CLASSPATH:/usr/share/java/vecmath.jar"

# =================================================================== ALIASES ==
alias ls="/bin/ls --color=auto -h"
# cf. http://www.commandlinefu.com/commands/view/1892/vi-keybindings-with-info
alias info="/usr/bin/info --vi-keys"
#alias reboot="/usr/bin/mahalt -r"
#alias halt="/usr/bin/mahalt"
#alias poweroff="/usr/bin/mahalt"
alias maxima="/usr/bin/maxima -q"
alias grep="grep --color=auto"
alias sysus="systemctl --no-pager --user"
# disable pagers
alias journalctl="journalctl --no-pager"
alias systemctl="systemctl -l --no-pager"
[ ! -f "$JAVA_HOME/bin/java" ] || alias java="$JAVA_HOME/bin/java"
alias 7z_ma="/usr/bin/7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=64m -ms=2g -l"

# ========================================= MDVL SIMPLE LOGIN MANAGER AND END ==
# MDVL _simple_ login manager. Login on tty1 automatically runs startx.
if [ -z "$DISPLAY" -a -z "$MAEMR_RES" -a "$(tty)" = "/dev/tty1" -a \
							"$(id -u)" != 0 ]; then
	unset sheetpid
	unset sleeppid
	unset LINES
	unset COLUMNS
	# Prevent ck-launch blah to fail automounting when using startx...
	export GDMSESSION=masysma
	# invoke on the same VT to mitigate potential security issues
	exec /usr/bin/startx -- vt1 2> /dev/null > /dev/null
elif [ $sheetpid != -1 ]; then
	( sleep 3 && kill $sheetpid ) 2>&1 > /dev/null & sleeppid=$!
	disown
	wait $sheetpid
	kill -s TERM $sleeppid 2> /dev/null
	echo
fi
unset sheetpid
unset sleeppid
