#!/bin/bash

#parameters 
{
    moodleVersion=$1
    glusterNode=$2
    glusterVolume=$3 
    moodledbapwd=$4
    siteFQDN=$5
    # create gluster mount point


# GLuster CLient

wget -P /etc/yum.repos.d http://download.gluster.org/pub/gluster/glusterfs/LATEST/CentOS/glusterfs-epel.repo

yum -y install glusterfs glusterfs-fuse git

# mount gluster files system

echo -e '\n\rInstalling GlusterFS on '$glusterNode':/'$glusterVolume '/moodle\n\r' 

mount -t glusterfs $glusterNode:/$glusterVolume /moodle

#create html directory for storing moodle files
mkdir -p /moodle/html

# create directory for apache ssl certs
mkdir -p /moodle/certs

# create moodledata directory
mkdir -p /moodle/moodledata

# install Moodle 
echo '#!/bin/bash
      cd /tmp
      # downloading moodle 
      curl -k --max-redirs 10 https://github.com/moodle/moodle/archive/'$moodleVersion'.zip -L -o moodle.zip
      unzip moodle.zip
      echo -e \n\rMoving moodle files to Gluster\n\r 
      mv -v moodle-'$moodleVersion' /moodle/html/moodle
      # install Office 365 plugins
      if [ "$installOfficePlugins" = "True" ]; then
            curl -k --max-redirs 10 https://github.com/Microsoft/o365-moodle/archive/'$moodleVersion'.zip -L -o o365.zip
            unzip o365.zip
            cp -r o365-moodle-'$moodleVersion'/* /moodle/html/moodle
            rm -rf o365-moodle-'$moodleVersion'
     fi
    ' > /tmp/setup-moodle.sh
    
     chmod +x /tmp/setup-moodle.sh
    
    /tmp/setup-moodle.sh


# create cron entry
# It is scheduled for once per day. It can be changed as needed.
echo '0 0 * * * php /moodle/html/moodle/admin/cli/cron.php > /dev/null 2>&1' > cronjob
crontab cronjob

# Enable VirtualHost

mkdir /etc/httpd/sites-available

mkdir /etc/httpd/sites-enabled

echo -e "\n\rUpdating PHP and site configuration\n\r" 
    #update virtual site configuration 
    echo -e '
    <VirtualHost *:80>
            #ServerName www.example.com
            ServerAdmin webmaster@localhost
            DocumentRoot /moodle/html/moodle
            #LogLevel info ssl:warn
            ErrorLog ${APACHE_LOG_DIR}/error.log
            CustomLog ${APACHE_LOG_DIR}/access.log combined
            #Include conf-available/serve-cgi-bin.conf
    </VirtualHost>' > /etc/httpd/sites-enabled/eadunibr.conf


sudo ln -s /etc/httpd/sites-available/eadunibr.conf /etc/httpd/sites-enabled/eadunibr.conf

echo "IncludeOptional sites-enabled/*.conf" >> /etc/httpd/conf/httpd.conf

chown -R www-data /moodle/html/moodle
chown -R apache /moodle/certs
chown -R apache /moodle/moodledata
chmod -R 770 /moodle/html/moodle
chmod -R 770 /moodle/certs
chmod -R 770 /moodle/moodledata

# restart Apache
echo -e "\n\rRestarting Apache2 httpd server\n\r"
systemctl restart httpd 
    
echo -e "sudo -u apache /usr/bin/php /moodle/html/moodle/admin/cli/install.php --chmod=770 --lang=pt_br --wwwroot=http://"$siteFQDN" --dataroot=/var/www/moodledata --dbhost=172.18.2.5 --dbpass="$moodledbapwd" --dbtype=mariadb --fullname='Moodle LMS' --shortname='Moodle' --adminuser=admin --adminpass="$moodledbapwd" --adminemail=admin@"$siteFQDN" --non-interactive --agree-license --allow-unstable || true "

sudo -u apache /usr/bin/php /moodle/html/moodle/admin/cli/install.php --chmod=770 --lang=pt_br --wwwroot=http://$siteFQDN --dataroot=/var/www/moodledata --dbhost=172.18.2.5 --dbpass=$moodledbapwd --dbtype=mariadb --fullname='Moodle LMS' --shortname='Moodle' --adminuser=admin --adminpass=$moodledbapwd --adminemail=admin@$siteFQDN --non-interactive --agree-license --allow-unstable || true

echo -e "\n\rDone! Installation completed!\n\r"
}  > /tmp/install.log
