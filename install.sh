#!/bin/bash
#  This script install docker, docker-compose, vault, awscli, gomplate, 
#              shibboleth, ldapsearch, python oracle driver.
#  via proxy server

export PROXYSERVER=your-proxy-server:8080
export PROXYURL="http://${PROXYSERVER}"

echo "Installing ldapsearch with GSSAPI support"
   yum install -y openldap-clients
   yum install -y libgssapi*

echo "Installing awscli version 2"
  cd /tmp
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
       -o "awscliv2.zip" -x $PROXYURL
  unzip awscliv2.zip
  ./aws/install
  rm -rf aws

echo "Installing Vault"
  cd /usr/local/bin
  curl -o vault.zip https://releases.hashicorp.com/vault/1.4.0/vault_1.4.0_linux_amd64.zip \
       -x psxferdev01:8080
  unzip vault.zip
  chmod 755 /usr/local/bin/vault
  rm vault.zip

echo "Installing gomplate"
  curl -o /usr/local/bin/gomplate -sSL \
       https://github.com/hairyhenderson/gomplate/releases/download/v3.6.0/gomplate_linux-amd64 \
       -x $PROXYSERVER
  chmod 755 /usr/local/bin/gomplate

echo "Installing shibbolet 3.x"
echo "   Adding /etc/yum.repos.d/shibboleth.repo"
cp shibboleth.repo /etc/yum.repos.d
echo "Installing shibboleth"
yum update -y
yum install -y shibboleth.x86_64

echo "Installing docker compose ..."
echo "  See document from https://github.com/docker/compose/releases"
  curl -o /usr/local/bin/docker-compose -x $PROXYSERVER \
    -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" 
  chmod +x /usr/local/bin/docker-compose

echo "Updating /etc/yum.conf to include proxy server url"
echo "proxy=$PROXYURL" >> /etc/yum.conf

echo "Installing container-selinux ..."
yum install -y http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.107-3.el7.noarch.rpm
echo "Installing docker-ce ..."
yum install -y docker-ce
systemctl start docker

echo "Adding http-proxy.conf file ..."
mkdir -p /etc/systemd/system/docker.service.d
cat <<EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=$PROXYURL"
Environment="HTTPS_PROXY=$PROXYURL"
EOF

echo "Creating /etc/docker/daemon.json file"
cat <<EOF2 > /etc/docker/daemon.json
{
 "default-address-pools":
 [
 {"base":"192.168.0.0/16","size":23}
 ]
}
EOF2

echo "Restarting the docker..."
systemctl daemon-reload
systemctl restart docker
systemctl show docker --property Environment

echo "Dont forget to add your developers to the docker group"
echo "      usermod -a -G docker username"

cat <<EOF3 -
Setting GIT to use proxy ...this should do manually on your account
git config --global http.https://domain.com.sslVerify false
git config --global http.proxy $PROXYURL
git config --global https.proxy $PROXYURL
EOF3

cat <<EOF4 -
Installing Python driver for Oracle
  Check out the document at 
        https://yum.oracle.com/oracle-linux-python.html#InstantClientEnv
        http://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient/x86_64/index.html
EOF4

echo "Install Python Oracle driver ..."
  python -m pip install cx_Oracle --proxy=$PROXYURL --upgrade

echo "Download Oracle Client Basic 19.3 RPM..."
  curl -o oracle-client.rpm -x $PROXYSERVER \
     http://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient/x86_64/getPackage/oracle-instantclient19.3-basic-19.3.0.0.0-1.x86_64.rpm 

echo "Installing Oracle CLient under /usr/lib/oracle/19.3/client64"
  yum install oracle-client.rpm
