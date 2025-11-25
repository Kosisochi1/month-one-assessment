#!/bin/bash
set -e
yum update -y

amazon-linux-extras install postgresql14 -y
yum install -y postgresql-server postgresql-contrib

postgresql-setup --initdb

systemctl start postgresql
systemctl enable postgresql 

cp /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf.backup
cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.backup

sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf

cat >> /var/lib/pgsql/data/pg_hba.conf << EOF

# Allow connections from VPC
host    all             all             10.0.0.0/16             md5
EOF

systemctl restart postgresql

echo "ec2-user:${my_password}" | chpasswd

sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd




