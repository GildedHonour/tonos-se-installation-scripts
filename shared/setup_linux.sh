#!/usr/bin/env bash

PACKAGE_MANAGER="apt"
PACKAGE_MANAGER_UPDATE_CMD="$PACKAGE_MANAGER update"
PACKAGE_MANAGER_INSTALL_CMD="$PACKAGE_MANAGER install --yes"

ARANGODB_VERSION="35"
ARANGODB_PKG_VERSION="3.5.3-1"

SYSTEMD_TONOS_NODE_SERVICE_NAME="tonos_se_node_01"


is_package_installed() {
    apt list $1 2>/dev/null | grep -qi installed
}

is_systemd_enabled() {
    [[ -d /run/systemd/system ]]
}

is_port_free() {
    ss -t -l 'sport = $1' | grep LISTEN
    if [ $? = 0 ]; then
        echo false
    else
        echo true
    fi
}


# install libraries
sudo $PACKAGE_MANAGER_UPDATE_CMD
sudo $PACKAGE_MANAGER_INSTALL_CMD \
    cmake make clang gcc g++ \
    ca-certificates git \
    musl musl-dev \
    npm \
    openssh-client  openssl \
    libssl-dev pkg-config \
    curl wget


# install rust
install_or_update_rust

# install tonos se node
rm -rf $TONOS_SE_TEMP_PATH
setup_tonos_se_node

# install q-server
say "q-server: installing"
rm -rf $Q_SERVER_PATH

say_status "q-server: getting the source code"
git clone --recursive --branch $Q_SERVER_GITHUB_REV $Q_SERVER_GITHUB_REPO_HTTPS $Q_SERVER_PATH
cd $Q_SERVER_PATH

say_status "q-server: building"
npm install --production
say_status "q-server: done"



# install arangodb
if is_package_installed "arangodb3"; then
    say "arangodb3 is already installed, nothing to do"
else
    say_status "arangodb3: downloading and installing"

    cd /tmp
    local _deb_file_name="arangodb3_${ARANGODB_PKG_VERSION}_amd64.deb"
    wget "https://download.arangodb.com/arangodb${ARANGODB_VERSION}/Community/Linux/${_deb_file_name}"
    sudo DEBIAN_FRONTEND=noninteractive dpkg -i $_deb_file_name

    say_status "arangodb3: done"
fi



# install nginx
if is_package_installed "nginx"; then
    say "nginx: already installed, nothing to do"
else
    say "nginx: installing"
    sudo $PACKAGE_MANAGER_INSTALL_CMD nginx
    say_status "nginx: done"
fi

sudo cp $THIS_SCRIPT_BASE_PATH/shared/nginx.tonos_se.conf /etc/nginx/conf.d/tonos_se.conf



# set up systemd services
if [ $IS_NATIVE_UBUNTU_LINUX = true ]; then
    say "systemd: setting up services"
    cd $THIS_SCRIPT_BASE_PATH/shared

    # ton node
    sed \
        -e "s|{{HOME_PATH}}|${HOME}|" \
        -e "s|{{TONOS_SE_NODE_PATH}}|${TONOS_SE_NODE_PATH}|" \
        -e "s|{{NAME}}|tonos_se_node_01|" \
        -e "s|{{USER_NAME}}|$(whoami)|" \
        tonos_se_node.systemd.service.template > tonos_se_node_01.service

    sudo mv tonos_se_node_01.service /etc/systemd/system/.


    # q-server
    sed \
        -e "s|{{HOME_PATH}}|${HOME}|" \
        -e "s|{{Q_SERVER_PATH}}|${Q_SERVER_PATH}|" \
        -e "s|{{Q_DATA_MUT}}|${Q_DATA_MUT}|" \
        -e "s|{{NAME}}|q_server|" \
        -e "s|{{USER_NAME}}|$(whoami)|" \
        ton_q_server.systemd.service.template > ton_q_server.service

    sudo mv ton_q_server.service /etc/systemd/system/.


    say_status "running services"

    sudo systemctl daemon-reload

    # TODO: check if some have  already been enabled and are running?


    sudo systemctl enable arangodb3
    sudo systemctl start arangodb3

    sudo systemctl enable nginx
    sudo systemctl start nginx

    sudo systemctl enable $SYSTEMD_TONOS_NODE_SERVICE_NAME
    sudo systemctl start $SYSTEMD_TONOS_NODE_SERVICE_NAME

    say_status "done"

elif [ $IS_NATIVE_UBUNTU_LINUX = false]; then
    # install honcho
    say "honcho: installing and setting up"

    sudo $PACKAGE_MANAGER_INSTALL_CMD python3-pip
    pip3 install --upgrade pip
    pip3 install honcho

    if [ ! -d $HOME/honcho-cfg ]; then
        mkdir $HOME/honcho-cfg
    fi

    cd $HOME/honcho-cfg
    cp $THIS_SCRIPT_BASE_PATH/shared/procfile.windows_wsl_linux Procfile

    cp $THIS_SCRIPT_BASE_PATH/shared/run_q_server.sh $Q_SERVER_PATH/run.sh
    chmod +x $Q_SERVER_PATH/run.sh
    chmod +x $TONOS_SE_NODE_PATH/run.sh

    honcho start
else
    err $UNREACHABLE_POINT_ERR_MSG
fi