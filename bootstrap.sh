#!/bin/sh

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

# check file
gpg --keyserver pgpkeys.mit.edu --recv-key 2F6059E7
gpg --verify apache-tomcat-$TOMCAT_VERSION.tar.gz{.asc,}
tar xzf apache-tomcat-$TOMCAT_VERSION.tar.gz
mv apache-tomcat-$TOMCAT_VERSION $CATALINA_HOME

# get tomcat users set up correctly
cat /vagrant/tomcat-users.xml > $CATALINA_HOME/conf/tomcat-users.xml

echo "Boot Tomcat"
$CATALINA_HOME/bin/startup.sh

echo "Download CLIFF"
curl https://github.com/c4fcm/CLIFF/releases/download/v$CLIFF_VERSION/cliff-$CLIFF_VERSION.war \
	-o $CATALINA_HOME/webapps/cliff-$CLIFF_VERSION.war

echo "Downloading CLAVIN..."
git clone https://github.com/Berico-Technologies/CLAVIN.git
cd CLAVIN

  git checkout 2.0.0
  echo "Downloading placenames file from Geonames..."
  curl -O http://download.geonames.org/export/dump/allCountries.zip
  unzip -qq allCountries.zip
  echo "Compiling CLAVIN"
  mvn compile
  echo "Building Lucene index of placenames--this is the slow one, ~11M places total, ~20 minutes"
  MAVEN_OPTS="-Xmx3g" mvn exec:java -Dexec.mainClass="com.bericotech.clavin.index.IndexDirectoryBuilder"
popd # CLAVIN

# XXX surely this must be configurable..?
sudo mkdir /etc/cliff2
sudo ln -s /home/vagrant/CLAVIN/IndexDirectory /etc/cliff2/IndexDirectory
cat /vagrant/settings.xml > $HOME/.m2/settings.xml

$CATALINA_HOME/bin/shutdown.sh
$CATALINA_HOME/bin/startup.sh
