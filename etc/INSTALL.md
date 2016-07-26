# Deployment on server

Copying sources onto the server can be cumbersome, but it is possible to leverage git to help you with this. You do so by initializing a bare git repository on the server itself:

* sudo mkdir -p /space/projects/kpmg-dashboard.git
* sudo mkdir -p /space/projects/kpmg-dashboard.live
* sudo chown $USER:sshuser /space/projects/kpmg-dashboard.git
* sudo chown $USER:sshuser /space/projects/kpmg-dashboard.live
* cd /space/projects/kpmg-dashboard.git
* git init --bare

Note: you can omit :sshuser in the chown, or replace that with a different group shared by users. It is meant to make deployment by colleagues easier.

Last but not least, enable a post-receive hook:

* vi hooks/post-receive
* Insert:

    #!/bin/sh
    in=$(cat)
    branch=${in##*/}
    GIT_WORK_TREE=/space/projects/kpmg-dashboard.live git checkout -f $branch

* Save/quit vi
* chmod +x hooks/post-receive

The .git directory will be a true git repository, with the complete changes. That enables sending over only differences between your local machine, and the server. A clean/forced checkout will be put in the .live directory each time changes are pushed into the git repository on the server. Be careful with manual changes, they get overwritten easily by the post-receive script.

Once a local git repo has been setup on the server, add it as a remote to the git clone on your local machine:

* git remote add prod USERNAME@your.demoserver.com:/space/projects/kpmg-dashboard.git

Then run the following each time you want to update code on the demo server:

* git push prod

Once done that, you can run all above deployment steps on the server, just go to /space/projects/kpmg-dashboard.live/. A few ml commands might return an error, but only after having done what needed to be done. You can run the ml tasks remotely as well, might be a bit slower.

Note: .git and .live files on the server are 'owned' by $USER:sshuser. You may need to chown them to yourself to be able to push things. Also make sure to run `npm install` and `bower install` if dependencies changes, and `gulp build` on the server each time UI changes are applied.

# Installing services

The code includes a service script, and a service config to make installing an express server service as easy as possible. The following files are involved:

- etc/init.d/node-express-service (generic express server service script)
- etc/{env}/conf.sh (application specific service configuration, any application name allowed)
- boot.js (entry point for express service, calls out to server.js)
- node-app.js (required by boot.js)

The conf.sh is 'sourced' by the service script, and allows overriding the built-in defaults. Usually you only need to override SOURCE\_DIR, APP\_PORT, and ML\_PORT. Make sure they match the appropriate environment.

Next install [forever](https://www.npmjs.com/package/forever) globally if it is not already installed.

- `$ [sudo] npm install forever -g`

Next, push all source files to the appropriate server. The following assumes it was dropped under /space/projects/ in a folder called kpmg-dashboard.live. Take these steps to install the services:

- cd /space/projects/kpmg-dashboard.live
- gulp build # this will create the ./dist/ folder with all the required assests and code
- cd /etc
- sudo ln -s /space/projects/kpmg-dashboard.live/etc/{env} kpmg-dashboard
- cd /etc/init.d
- sudo ln -s /space/projects/kpmg-dashboard.live/etc/init.d/node-express-service kpmg-dashboard
- sudo chkconfig --add kpmg-dashboard
- sudo chkconfig --levels 2345 kpmg-dashboard on

Or, slightly shorter:

- cd /space/projects/kpmg-dashboard.live/etc
- ./install.sh (not as sudo!)

Next to start it, use the following commands (from any directory):

- sudo service kpmg-dashboard start

These services will also print usage without param, but they support info, restart, start, status, and stop. The info param is very useful to check the settings.

# Initializing httpd

Next to this, you likely want to enable the httpd daemon. Often only very limited ports are exposed on servers, and we usually deliberately configure the application outside that scope. Add a forwarding rule for the appropriate dns:

- sudo chkconfig --levels 2345 httpd on
- sudo service httpd stop
- sudo vi /etc/httpd/conf/httpd.conf, uncomment the line with:

NameVirtualHost *:80

- and append:

<VirtualHost *:80>
  ServerName kpmg-dashboard.demoserver.com
  RewriteEngine On
  RewriteRule ^(.*)$ http://localhost:9100$1 [P]
</VirtualHost>

- sudo service httpd start
