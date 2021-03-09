#!/usr/bin/env bash

PACKAGE_MANAGER="apt"
PACKAGE_MANAGER_UPDATE_CMD="$PACKAGE_MANAGER update"
PACKAGE_MANAGER_INSTALL_CMD="$PACKAGE_MANAGER install --yes"

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
            say "the path '${TONOS_SE_TEMP_PATH}/ton-node-se' and a release in it already exist;"
            read -p "remove and rebuild it? (y/n): " yn
            case $yn in
                [Yy]* )
                    rm -rf $TONOS_SE_TEMP_PATH
                    setup_tonos_se_node
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
        setup_tonos_se_node
    fi
else
    setup_tonos_se_node
fi




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
    say_status "arangodb3: installing"

    wget -q https://download.arangodb.com/arangodb34/DEBIAN/Release.key -O- | sudo apt-key add -
    echo 'deb https://download.arangodb.com/arangodb34/DEBIAN/ /' | sudo tee /etc/apt/sources.list.d/arangodb.list

    sudo $PACKAGE_MANAGER_UPDATE_CMD
    sudo $PACKAGE_MANAGER_INSTALL_CMD arangodb3

    # steps to go through manually:

    # set root password and repeart it
    # set 'automatically upgrade database files' - yes
    # set 'the database storage engine to use.' - auto
    # set 'backup database before doing an upgrade.' - yes
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

    # TODO use systemd

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
        -e "s|{{NAME}}|q_server|" \
        -e "s|{{USER_NAME}}|$(whoami)|" \
        ton_q_server.systemd.service.template > ton_q_server.service

    sudo mv ton_q_server.service /etc/systemd/system/.


    # generate systemd files for node and q-server
    # copy them into /systemd
    # sudo systemctl daemon-reload 

    # sudo systemctl start ton_q_server
    # sudo systemctl start ton_node_01


    say_status "running services"

    sudo systemctl daemon-reload

    sudo systemctl enable arangodb3
    sudo systemctl start arangodb3

    sudo systemctl enable nginx
    sudo systemctl start nginx

    say_status "done"

elif [ $IS_NATIVE_UBUNTU_LINUX = false]; then
    # install honcho
    say "hongo: installing and setting up"

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