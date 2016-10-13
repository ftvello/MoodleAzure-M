

# Comando para atualizacao S.O

yum update -y

# Instalacao repositorio Galera - Cluster

cat >> /etc/yum.repos.d/mariadb.repo << EOF
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/centos6-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

# Disable SELINUX
setenforce 0

# Install SOCAT
yum install socat -y

# Remover pacote default maria-db
yum remove mariadb-libs -y

# Instalando Glaera-CLuster
yum install MariaDB-Galera-server MariaDB-client rsync galera -y

# Iniciando Servico MYsql
service mysql start

# Configurar parametros de Banco

mysql -u root <<EOF
CREATE DATABASE moodle;
GRANT ALL PRIVILEGES ON moodle.* TO 'moodledba'@'%'
IDENTIFIED BY '$USERPASSWORD';
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES on *.* TO 'sst_user'@'localhost' IDENTIFIED BY '$CENTOSPASSWORD' WITH GRANT OPTION;
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQLPASSWORD');
CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQLPASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Parar Servico Mysql
service mysql stop

# Criar configuracao My.Cnf
cat >> /etc/my.cnf.d/server.cnf << EOF

binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
innodb_locks_unsafe_for_binlog=1
query_cache_size=0
query_cache_type=0
bind-address=0.0.0.0
datadir=/var/lib/mysql
innodb_log_file_size=100M
innodb_file_per_table
innodb_flush_log_at_trx_commit=2
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://IPLIST"
wsrep_cluster_name='CLUSTERNAME'
wsrep_node_address='MYIP'
wsrep_node_name='MYNAME'
wsrep_sst_method=rsync
wsrep_sst_auth=sst_user:CENTOSPASSWORD
EOF

if [ "$FIRSTNODE" = "$MYIP" ];
then
   sed -i "s/#wsrep_on=ON/wsrep_on=ON/g;s/IPLIST//g;s/MYIP/$MYIP/g;s/MYNAME/$MYNAME/g;s/CLUSTERNAME/$CNAME/g" /etc/my.cnf.d/server.cnf
else
   sed -i "s/#wsrep_on=ON/wsrep_on=ON/g;s/IPLIST/$IPLIST/g;s/MYIP/$MYIP/g;s/MYNAME/$MYNAME/g;s/CLUSTERNAME/$CNAME/g" /etc/my.cnf/server.cnf
fi

