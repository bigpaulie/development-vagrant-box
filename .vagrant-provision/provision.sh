#!/bin/bash
#
# Vagrant Provisioning Script
# OS : Ubuntu 14.04 64bit
# Author: Paul P <paul@paul-resume.com>

PROVISION_LOG="/vagrant/.vagrant-provision/logs/provision.log"

# Database configuration
DATABASE_PASSWORD="1q2w3e4r"

echo "+-----------------------------------------------+"
echo "| Vagrant development VM                        |"
echo "|                                               |"
echo "| Provisioning:                                 |"
echo "| LAMP Stack, RVM, Node.js NPM, Bower, Composer |"
echo "|                                               |"
echo "+-----------------------------------------------+"


# Updating system repositories
updateSystem() {
    echo "Updating system repositrories and installing updates"
    sudo apt-get update > /dev/null 2>&1
}

# Provision basic packages
basicPackages() {
    echo "Installing basic packages: vim, tmux, htop, git-core, curl"
    sudo apt-get install -y vim tmux htop git-core curl >> $PROVISION_LOG 2>&1
}

# Provision LAMP
installLAMP() {
    echo "Installing LAMP stack"
    sudo apt-get install -y build-essential apache2 apache2-utils php5 php5-cli libapache2-mod-php5 \
        php5-gd php5-intl php5-curl php-pear php5-mysql php5-dev memcached php5-memcache php5-memcached \
        mcrypt php5-mcrypt >> $PROVISION_LOG 2>&1

    echo "mysql-server mysql-server/root_password password $DATABASE_PASSWORD" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password $DATABASE_PASSWORD" | debconf-set-selections && \
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections && \
    echo "phpmyadmin phpmyadmin/app-password-confirm password $DATABASE_PASSWORD" | debconf-set-selections && \
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DATABASE_PASSWORD" | debconf-set-selections && \
    echo "phpmyadmin phpmyadmin/mysql/app-pass password $DATABASE_PASSWORD" | debconf-set-selections && \
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections && \
    sudo apt-get -y install mysql-server phpmyadmin >> $PROVISION_LOG 2>&1
}

# Provision Ruby
installRVM() {
    echo "Installing RVM"
    cd ~
    curl -#LO https://rvm.io/mpapis.asc >> $PROVISION_LOG 2>&1
    gpg --import mpapis.asc >> $PROVISION_LOG 2>&1
    curl -sSL https://get.rvm.io | bash -s stable >> $PROVISION_LOG 2>&1
    source /etc/profile.d/rvm.sh >> $PROVISION_LOG 2>&1
    rvm requirements >> $PROVISION_LOG 2>&1
    rvm install 2.3.0 >> $PROVISION_LOG 2>&1
    rvm use 2.3.0 --default >> $PROVISION_LOG 2>&1
}

# Provision Node.js
installNode() {
    echo "Installing Node.js"
    cd ~
    wget https://nodejs.org/dist/v4.4.7/node-v4.4.7-linux-x64.tar.xz >> $PROVISION_LOG 2>&1
    tar -xf node-v4.4.7-linux-x64.tar.xz && cd node-v4.4.7-linux-x64/
    cp -R bin/ include/ share/ lib/ /usr/
    rm -rf ~/node-4.4.7-linux-x64 ~/node-v4.4.7-linux-x64.tar.xz >> $PROVISION_LOG 2>&1 
}

# Provision Package Managers
installPackageManagers() {
    echo "Installing package managers: composer, bower"
    cd ~
    wget http://getcomposer.org/composer.phar >> $PROVISION_LOG 2>&1
    echo "Installing Composer"
    chmod +x composer.phar && mv composer.phar /usr/bin/composer
    echo "Installing Bower"
    npm install -g bower >> $PROVISION_LOG 2>&1
}

# Provision mailcatcher

# Provision SQL
provisionSQL() {
    FILE_COUNT=$(wc -l /vagrant/.vagrant-provision/provision-sql/*.sql)
    if [ $FILE_COUNT -g 0 ]; then
        echo "Provisioning $FILE_COUNT databases"
        for dump in /vagrant/.vagrant-provision/provision-sql/*.sql
        do
            echo "Importing $dump"
            mysql -u root --password=$DATABASE_PASSWORD < $dump
            echo "Finished import of $dump"
        done
    fi
}

# Post install 
postInstall() {
    echo "Provisioning finished"
    echo "You now have :"
    echo "PHP $(php -v)"
    echo "Node $(node -v)"
    echo "NPM $(npm -v)"
    echo "Composer $(composer --version)"
    echo "Bower $(bower --version)"
}

# Initialization
init() {
    echo "Initializing ..."
    updateSystem
    basicPackages
    installLAMP
    installRVM
    installNode
    installPackageManagers
    postInstall
}

# Start Provisioning
init
exit 0
