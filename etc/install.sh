#!/bin/sh

sudo npm -g install bower
sudo npm -g install gulp
sudo npm -g install forever

cd ..
npm install
bower install
gulp build

cd /etc
sudo ln -s /space/projects/kpmg-dashboard.live/etc/prod kpmg-dashboard
cd /etc/init.d
sudo ln -s /space/projects/kpmg-dashboard.live/etc/init.d/node-express-service kpmg-dashboard
sudo chkconfig --add kpmg-dashboard
sudo chkconfig --levels 2345 kpmg-dashboard on
