#!/usr/bin/env bash

set -e

BIN_TARGET="ton_node_startup"
UNREACHABLE_POINT_ERR_MSG="how have you even reached installation thus far !?!1"
IS_NATIVE_UBUNTU_LINUX=
PACKAGE_MANAGER=
PACKAGE_MANAGER_INSTALL_CMD=

TONOS_SE_USER="tonos_user"
TONOS_SE_NODE_PATH="$HOME/ton-node_01"
TONOS_SE_TEMP_PATH="/tmp/tonos-se"
TONOS_SE_REPO_GIT_HTTPS="https://github.com/tonlabs/tonos-se.git"

Q_SERVER_GITHUB_REPO_HTTPS="https://github.com/tonlabs/ton-q-server"
Q_SERVER_GITHUB_REV="master"
Q_SERVER_PATH="$HOME/ton-q-server"


say() {
    printf '[TON SE node installer] %s\n' "$1"
}

say_status() {
    printf '===>  %s\n' "$1"
}


err() {
    say "$1" >&2
    exit 1
}

detect_os() {
    if [[ $OSTYPE =~ linux-gnu ]]; then
        local _distro=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
        if [[ ${_distro} =~ Ubuntu ]]; then
            if uname -a | grep -q '^Linux.*Microsoft'; then
                echo "windows_ubuntu_wsl"
            else
                echo "native_linux_ubuntu"
            fi
        else
            echo "${_distro}"
        fi
    elif [[ $OSTYPE =~ darwin ]]; then
        echo "macos_osx"
    else
        echo "?"
    fi
}

check_cmd() {
    command -v "$1" > /dev/null 2>&1
}

require_cmd() {
    if ! check_cmd "$1"; then
        err "require '$1' (command not found)"
    fi
}

install_or_update_rust() {
    if ! check_cmd rustup; then
        say "rust: installing"
        curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
    else
        say "rust: already installed"
        say_status "updating"
        rustup update
    fi

    say_status "done"

    source $HOME/.cargo/env
    rustup --version
    cargo --version
    rustc --version
}

build_tonos_se_node() {
    say "building tonos se node..."

    # run tests 1
    say_status "running tests #1"
    export PKG_CONFIG_ALLOW_CROSS=1
    export RUSTFLAGS="-C target-feature=-crt-static"
    git clone $TONOS_SE_REPO_GIT_HTTPS $TONOS_SE_TEMP_PATH
    cd $TONOS_SE_TEMP_PATH/ton-node-se/poa
    source $HOME/.cargo/env && cargo test


    # run tests 2
    say_status "running tests #2"
    cd $TONOS_SE_TEMP_PATH/ton-node-se/ton_node
    cargo test --features "ci_run"


    # build release
    say_status "building release"
    cd $TONOS_SE_TEMP_PATH/ton-node-se
    cargo build --release


    # copy files that have been built
    rm -rf $TONOS_SE_NODE_PATH && mkdir -p $TONOS_SE_NODE_PATH
    cp -R \
        $TONOS_SE_TEMP_PATH/ton-node-se/target/release/${BIN_TARGET} \
        $TONOS_SE_NODE_PATH/ton-node

    cp \
        config/log_cfg.yml \
        config/cfg_startup \
        config/key01 \
        config/pub01 \
        $TONOS_SE_NODE_PATH/


    cp $THIS_SCRIPT_BASE_PATH/shared/run_ton_node.sh $TONOS_SE_NODE_PATH/run.sh

    mkdir $TONOS_SE_NODE_PATH/create-msg
    cp -R $TONOS_SE_TEMP_PATH/ton-node-se/target/release/create-msg $TONOS_SE_NODE_PATH/create-msg/.

    say_status "done"
}

is_systemd_enabled() {
    [[ -d /run/systemd/system ]]
}

is_package_installed() {
    apt list $1 2>/dev/null | grep -qi installed
}


#
# the entry point
#

main() {
    if [[ "$EUID" -eq 0 ]]; then
        err "it may not be run as root; use a non-privileged user"
    fi

    THIS_SCRIPT_BASE_PATH=$(pwd)

    local _os_distro=$(detect_os)
    if [ $_os_distro = "macos_osx" ]; then
        say "your OS is Mac OSX"
      . ./shared/setup_macos_osx.sh
    elif [ $_os_distro = "native_linux_ubuntu" ]; then
        say "your OS is Linux Ubuntu"

        # TODO
        # verify that systemd is supported, otherwise error
        # require_cmd systemctl
        if [[ is_systemd_enabled = false ]]; then
            err "systemd is not supported or not enabled"
        fi


        IS_NATIVE_UBUNTU_LINUX=true
      . ./shared/setup_linux.sh
    elif [ $_os_distro = "windows_ubuntu_wsl" ]; then
        say "your OS is Linux Ubuntu under Windows WSL"
        IS_NATIVE_UBUNTU_LINUX=false
      . ./shared/setup_linux.sh
    else
        err "your platform or OS is unsupported: ${_os_distro}"
    fi

    say "done"
}


main || exit 1
