#!/usr/bin/env bash

PACKAGE_MANAGER="brew"
PACKAGE_MANAGER_UPDATE_CMD="$PACKAGE_MANAGER update"
PACKAGE_MANAGER_INSTALL_CMD="$PACKAGE_MANAGER install"

# install libraries
sudo $PACKAGE_MANAGER_UPDATE_CMD
sudo $PACKAGE_MANAGER_INSTALL_CMD \
    cmake make clang gcc g++ \
    curl ca-certificates git \
    musl musl-dev \
    npm \
    openssh-client  openssl \
    libssl-dev pkg-config



# install rust
install_or_update_rust


if [ -d $TONOS_SE_TEMP_PATH ]; then
    if [ -d $TONOS_SE_TEMP_PATH/ton-node-se/target/release ]; then
        while true; do
            read -p "the path '${TONOS_SE_TEMP_PATH}/ton-node-se' and a release in it already exist; remove and build it again? (y/n): " yn
            case $yn in
                [Yy]* )
                    rm -rf $TONOS_SE_TEMP_PATH
                    build_tonos_se_node
                    break
                ;;

                [Nn]* )
                    break
                    ;;

                * )
                    echo "please answer 'y' (yes) or 'n' (no)."
                    ;;
            esac
        done
    else
        rm -rf $TONOS_SE_TEMP_PATH
        build_tonos_se_node
    fi
else
    build_tonos_se_node
fi

chmod +x $TONOS_SE_NODE_PATH/run.sh



# install q-server
rm -rf $Q_SERVER_PATH
git clone --recursive --branch $Q_SERVER_GITHUB_REV $Q_SERVER_GITHUB_REPO_HTTPS $Q_SERVER_PATH
cd $Q_SERVER_PATH
npm install --production
cp $THIS_SCRIPT_BASE_PATH/shared/run_q_server.sh $Q_SERVER_PATH/run.sh
chmod +x $Q_SERVER_PATH/run.sh


# install arangodb
if [ -z $(dpkg -l | grep arangodb3) ]; then
    sudo $PACKAGE_MANAGER_UPDATE_CMD
    sudo $PACKAGE_MANAGER_INSTALL_CMD arangodb3

    # steps to go through manually:

    # set root password and repeart it
    # set 'automatically upgrade database files' - yes
    # set 'the database storage engine to use.' - auto
    # set 'backup database before doing an upgrade.' - yes

    # TODO
    sudo service arangodb3 start
fi


# install nginx
if [ -z $(dpkg -l | grep nginx) ]; then
    sudo $PACKAGE_MANAGER_INSTALL_CMD nginx
    sudo cp $THIS_SCRIPT_BASE_PATH/shared/nginx.tonos_se.conf /etc/nginx/conf.d/.

    # TODO
    sudo service nginx start
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
