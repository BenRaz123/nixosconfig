#!/usr/bin/env bash

TRUE=1
FALSE=0

c() {
	! [ -t 0 ] && return

	[ -z "$1" ] && {
		printf "\e[0m"
		return
	}

	for arg in "$@"; do
		case "$arg" in
		bold) printf "\e[1m" ;;
		black) printf "\e[30m" ;;
		red) printf "\e[31m" ;;
		green) printf "\e[32m" ;;
		yellow) printf "\e[33m" ;;
		blue) printf "\e[34m" ;;
		magenta) printf "\e[35m" ;;
		cyan) printf "\e[36m" ;;
		bblack) printf "\e[90m" ;;
		bred) printf "\e[91m" ;;
		bgreen) printf "\e[92m" ;;
		byellow) printf "\e[93m" ;;
		bblue) printf "\e[94m" ;;
		bmagenta) printf "\e[95m" ;;
		bcyan) printf "\e[96m" ;;
		esac
	done
}

usage() {
	cat <<-_EOF
		$(c green bold)Usage:$(c) $(c cyan bold)$0$(c) $(c cyan) [flags]$(c)

		$(c green bold)Options:$(c)
		  $(c cyan bold)-U$(c), $(c cyan bold)--force-user-ns$(c)   force user namespaces instead of using sudo
		  $(c cyan bold)-S$(c), $(c cyan bold)--force-sudo$(c)      force sudo instead of user namespaces
		  $(c cyan bold)-h$(c), $(c cyan bold)--help$(c)            display this page
		  $(c cyan bold)-s$(c), $(c cyan bold)--setup$(c)           setup some key services
		  $(c cyan bold)-a$(c), $(c cyan bold)--also-setup$(c)      setup home manager + key services
	_EOF
}

log_message() {
	msg=$(printf "$(c $1):: $(c bold)$2$(c) %s" "$3")
	if [[ "$3" =~ \.\.\.$ ]]; then
		LAST_PRINTED="$msg"
		printf "%s" "$msg" >&2
		return
	fi
	printf "%s\n" "$msg" >&2
}

info() {
	log_message bcyan info "$1"
}

warn() {
	log_message yellow warn "$1"
}

err() {
	log_message bred error "$1"
}

follow_up() {
	printf "\r$LAST_PRINTED %s\n" "$1"
}

backup_file() {
	! [ -f "$1" ] && return
	info "backup up file $1 to $1.bak"
	mv "$1" "$1.bak"
}

run() {
	local err=$(mktemp)
	local out=$(mktemp)
	"$@" >"$out" 2>"$err"
	local st="$?"
	if [ $st -ne 0 ]; then
		cat "$err"
		return $st
	fi
	cat "$out"
	return 0

}

get_file() {
	local prompt="$1"
	local res

	while true; do
		read -p "$(c bold magenta)$prompt>$(c) " res
		local expanded="$(eval echo "$res")"

		if [ -f "$expanded" ]; then
			echo "$expanded"
			return
		fi

		err "file \"$expanded\" does not exist!"
		echo
	done
}

setup() {
  info "github authentication"
  gh auth login

  info "importing key"
  local pub=$(get_file "Public Key Path")
  local priv=$(get_file "Secret Key Path")
  read -p "$(c bold magenta)Key ID>$(c) " id
  gpg --import "$pub" "$priv"

  info "setting trust to ultimate on key"
  fingerprint=$(gpg --with-colons --fingerprint "$id" | awk -F: '/^fpr:/ {print $10; exit}')
  echo "$fingerprint:6:" | gpg --import-ownertrust
  
  if [ ! -d "$HOME/.password-store" ]; then
  	info "cloning benraz123/passwordstore"
  	git clone "https://github.com/benraz123/passwordstore" "$HOME/.password-store"
  fi
  pass init "$id"

  info "setting up maestral"
  maestral auth link
  maestral start
  
  info "done!"
}

check_for_cmd() {
	command -v "$1" &>/dev/null && return
	local log_cmd="${2:err}"
	"$log_cmd" "the command $(c green)$1$(c) is not installed. please install it"
	[[ $log_cmd == "err" ]] && exit 1
}

check_user_ns() {
	info "do we have kernel support for unpriveleged user namespaces?..."
	if [[ $(unshare --user --pid echo YES) == "YES" ]] ||
		[[ $(zgrep CONFIG_USER_NS /proc/config.gz) == "CONFIG_USER_NS=y" ]] ||
		[[ $(grep CONFIG_USER_NS /boot/config-$(uname -r)) == "CONFIG_USER_NS=y" ]] ||
		[[ $(cat /proc/sys/kernel/unprivileged_userns_clone) == "1" ]]; then
		follow_up "yes"
		return 0
	fi
	follow_up "no"
	return 1
}

check_has_root() {
	info "do we have root?..."
	if id -nG "$USER" | grep -qwE 'sudo|wheel' || sudo true; then
		follow_up "yes"
		return 0
	else
		follow_up "no"
		return 1
	fi
}

install_user_ns() {
	info "checking for rust installation..."
	cargo_bin=cargo
	if ! command -v cargo >/dev/null 2>&1; then
		follow_up "not found"
		info "no cargo found... installing rust (this might take a while)..."
		local script_file=$(mktemp)
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o $script_file &>/dev/null
		if ! out=$(run bash "$script_file"); then
			follow_up "fail"
			err "problem installing rust:\n"
			echo "$out"
			return 1
		fi
		follow_up "done"
	else
		follow_up "found"
	fi
	follow_up "found"

	info "installing nix-user-chroot with cargo..."
	if ! out=$(run "$cargo_bin" install nix-user-chroot); then
		follow_up "fail"
		err "failed to install nix-user-chroot:\n"
		echo "$out"
		return 1
	fi
	follow_up "done"

	if command -v "nix-user-chroot" >/dev/null 2>&1; then
		chroot_bin="nix-user-chroot"
	else
		chroot_bin="$HOME/.cargo/bin/nix-user-chroot"
	fi

	mkdir -m 0755 ~/.nix
	#TODO: bring in line with the root implementation

	local script_file="$(mktemp)"

	info "installing nix in single user mode with a folder at ~/.nix..."

	if ! out="$(run curl --proto "=https" --tlsv1.2 -L https://nixos.org/nix/install -o "$script_file")"; then
		follow_up "fail"
		err "couldn't fetch nix install script:"
		printf "%s\n" "$out"
	fi

	if ! out=$(run "$chroot_bin" ~/.nix bash -c "bash $script_file --no-daemon"); then
		follow_up fail
		err "couldn't install nix:"
		printf "%s\n" "$out"
		return 1
	fi
	follow_up "done"
}

install_root() {
	info "installing nix in single user mode..."
	local script_file=$(mktemp)

	check_for_cmd curl
	check_for_cmd xz

	if ! out=$(run curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install -o "$script_file"); then
		follow_up "fail"
		err "couldn't fetch nix install script:"
		printf "%s\n" "$out"
		return 1
	fi

	if ! out=$(run bash "$script_file"); then
		follow_up "fail"
		err "couldn't install nix:"
		printf "%s\n" "$out"
		return 1
	fi

	. "$HOME/.nix-profile/etc/profile.d/nix.sh"
	follow_up "done"
}

main() {
	#backup_file "$HOME/.bashrc"
	#backup_file "$HOME/.profile"

	info "downloading home-manager..."
	sleep 1
	if ! out=$(run nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager); then
		follow_up "fail"
		sleep 1
		err "couldn't download home manager :"
		printf "%s\n" "$out"
		exit 1
	fi
	follow_up "done"

	info "updating nix-channel..."
	if ! out=$(run nix-channel --update); then
		follow_up "fail"
		err "couldn't update nix channel:"
		printf "%s\n" "$out"
		exit 1
	fi
	follow_up "done"

	info "installing home-manager..."
	if ! out=$(run nix-shell -p "home-manager" --command "home-manager init --switch --no-flake -b bak"); then
		follow_up "fail"
		err "couldn't install home manager:" "$out"
		printf "%s\n" "$out"
		exit 1
	fi
	follow_up "done"
}

if ! opts="$(getopt -o :hsSUa --long help,force-sudo,force-user-ns,setup,also-setup -n "$1" -- "$@")"; then
	err "invalid flag given"
	echo
	usage
	exit 1
fi

also_setup=$FALSE

eval set -- "$opts"
while true; do
	case $1 in
	-h | --help)
		usage
		shift
		exit 0
		;;
	-s | --setup)
		setup
		exit
		shift
		;;
	-a | --also-setup)
		also_setup=$TRUE
		shift
		;;
	-S | --force-sudo)
		force_sudo=$TRUE
		force_user_ns=$FALSE
		shift
		;;
	-U | --force-user-ns)
		force_user_ns=$TRUE
		force_sudo=$FALSE
		shift
		;;
	--)
		shift
		break
		;;
	esac
done

if (($force_sudo)); then
	check_has_root ||
		warn "i'm trusting you knew what you were doing when you set that -S | --force-sudo flag (see $0 -h). proceeding anyway even though this may not work"

	install_root || {
		err "installation with root failed. due to -S | --force-sudo flag (see $0 -h) we can't proceed with any alternative methods. exiting."
		exit 1
	}
elif (($force_user_ns)); then
	check_user_ns ||
		warn "i'm trusting that you knew what you were doing when you set that -U | --force-user-ns flag (see $0 -h). proceeding anyway even though this may not work"

	install_user_ns || {
		err "we couldn't install with user namespaces. due to -U | --force-user-ns flag (see $0 -h) we can't proceed with any alternative methods. exiting."
		exit 1
	}
elif check_has_root; then
	install_root
elif check_user_ns; then
	install_user_ns
else
	err "we don't have root or kernel support for unpriveleged user namespaces. exiting."
	exit 1
fi

main
(($also_setup)) && setup
