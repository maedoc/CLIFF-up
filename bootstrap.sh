#!/bin/sh

set -e

export CLIFF_VERSION=2.3.0
export TOMCAT_VERSION=8.5.9
export CATALINA_HOME=$HOME/tomcat

echo "Installing basic packages..."
sudo apt update
sudo apt-get install -yqq git curl vim unzip htop openjdk-8-jdk maven

echo "Download Tomcat"
tomcat_mirror=http://mirrors.ircam.fr
curl -O $tomcat_mirror/pub/apache/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz
curl -O https://www.apache.org/dist/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc

# # check file
gpg --keyserver pgpkeys.mit.edu --recv-key 2F6059E7
gpg --verify apache-tomcat-$TOMCAT_VERSION.tar.gz.asc apache-tomcat-$TOMCAT_VERSION.tar.gz
tar xzf apache-tomcat-$TOMCAT_VERSION.tar.gz
mv apache-tomcat-$TOMCAT_VERSION $CATALINA_HOME

# get tomcat users set up correctly
mkdir -p $CATALINA_HOME/conf
cat /vagrant/tomcat-users.xml > $CATALINA_HOME/conf/tomcat-users.xml

echo "Download CLIFF"
cd $CATALINA_HOME/webapps
wget https://github.com/c4fcm/CLIFF/releases/download/v$CLIFF_VERSION/cliff-$CLIFF_VERSION.war
cd

# echo "Downloading CLAVIN..."
git clone https://github.com/Berico-Technologies/CLAVIN.git
cd CLAVIN
git checkout 2.0.0
echo "Downloading placenames file from Geonames..."
curl -O http://download.geonames.org/export/dump/allCountries.zip
unzip -qq allCountries.zip
echo "Compiling CLAVIN"
mvn compile
echo "Building Lucene index of placenames--this is the slow one, ~11M places total, ~20 minutes"
MAVEN_OPTS="-Xmx5g" mvn exec:java -Dexec.mainClass="com.bericotech.clavin.index.IndexDirectoryBuilder"
cd

# XXX surely this must be configurable..?
sudo mkdir /etc/cliff2
sudo ln -s $HOME/CLAVIN/IndexDirectory /etc/cliff2/IndexDirectory

#? 
mkdir $HOME/.m2
cat /vagrant/settings.xml > $HOME/.m2/settings.xml

# start tomcat
$CATALINA_HOME/bin/startup.sh
