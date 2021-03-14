#!/usr/bin/env bash

PACKAGE_MANAGER="brew"
PACKAGE_MANAGER_UPDATE_CMD="$PACKAGE_MANAGER update"
PACKAGE_MANAGER_INSTALL_CMD="$PACKAGE_MANAGER install"


is_port_free() {
    sudo lsof -i TCP:$1 | grep LISTEN
    if [ $? = 0 ]; then
        echo false
    else
        echo true
    fi
}


# install libraries
$PACKAGE_MANAGER_UPDATE_CMD
$PACKAGE_MANAGER_INSTALL_CMD \
    cmake make gcc \
    curl git \
    npm \
    openssl \
    pkg-config



# install rust
install_or_update_rust

# install tonos se node
rm -rf $TONOS_SE_TEMP_PATH
setup_tonos_se_node
chmod +x $TONOS_SE_NODE_PATH/run.sh

# install q-server
rm -rf $Q_SERVER_PATH
git clone --recursive --branch $Q_SERVER_GITHUB_REV $Q_SERVER_GITHUB_REPO_HTTPS $Q_SERVER_PATH
cd $Q_SERVER_PATH

$PACKAGE_MANAGER upgrade node
npm install --production

cp $THIS_SCRIPT_BASE_PATH/shared/run_q_server.sh $Q_SERVER_PATH/run.sh
chmod +x $Q_SERVER_PATH/run.sh


# install arangodb
if [ -z "$(brew ls --versions arangodb)" ]; then
    $PACKAGE_MANAGER_INSTALL_CMD arangodb
    brew services start arangodb
fi


# install nginx
if [ -z "$(brew ls --versions nginx)" ]; then
    say_status "arangodb3: setting up and installing"

    $PACKAGE_MANAGER_INSTALL_CMD nginx
    sudo cp $THIS_SCRIPT_BASE_PATH/shared/nginx.tonos_se.conf /usr/local/etc/nginx/servers/.

    # TODO
    brew services start nginx
    say_status "arangodb3: done"
fi


# install honcho
sudo apt install --yes python3-pip
pip3 install --upgrade pip
pip3 install honcho

if [ ! -d $HOME/honcho-cfg ]; then
    mkdir $HOME/honcho-cfg
fi
cd $HOME/honcho-cfg
cp $THIS_SCRIPT_BASE_PATH/shared/procfile.macos_osx Procfile

honcho start
