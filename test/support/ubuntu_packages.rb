=begin

#=========================================================
Install the packages
#=========================================================
sudo apt-get update
sudo apt-get -y install fluxbox xorg unzip vim default-jre rungetty firefox
sudo apt-get install libqt4-dev libqtwebkit-dev

#=========================================================
Packages for Capybara
VIRTUAL FRAMEBUFFER WITH XVFB, browser for Launchy gem, etc
#=========================================================
sudo apt-get install qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x
sudo apt-get install xvfb
sudo apt-get install iceweasel
sudo apt-get install build-essential chrpath libssl-dev libxft-dev
sudo apt-get install libnss3
sudo apt-get install libxi6 libgconf-2-4

#=========================================================
Download latest selenium server
#=========================================================
SELENIUM_VERSION=$(curl "https://selenium-release.storage.googleapis.com/" | perl -n -e'/.*<Key>([^>]+selenium-server-standalone[^<]+)/ && print $1')
wget "https://selenium-release.storage.googleapis.com/${SELENIUM_VERSION}" -O selenium-server-standalone.jar
chown vagrant:vagrant selenium-server-standalone.jar

#=========================================================
Download latest chrome driver
#=========================================================
CHROMEDRIVER_VERSION=$(curl "http://chromedriver.storage.googleapis.com/LATEST_RELEASE")
wget "http://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip"
unzip chromedriver_linux64.zip
sudo rm chromedriver_linux64.zip
chown vagrant:vagrant chromedriver

chromedriver --version 
=> ChromeDriver 2.25.426924 (649f9b868f6783ec9de71c123212b908bf3b232e)

#=========================================================
Install the stable Chromium version
#=========================================================
sudo add-apt-repository ppa:canonical-chromium-builds/stage
sudo apt-get install chromium-browser

chromium-browser --version 
=> Chromium 53.0.2785.143 Built on Ubuntu , running on Ubuntu 14.04

=end
