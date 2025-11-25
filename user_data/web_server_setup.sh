#!/bin/bash
set -e
for i in {1..10}; do
    yum update -y && yum install -y httpd
    if [ $? -eq 0 ]; then
        break
    fi
    echo "YUM failed, retrying in 10 seconds..."
    sleep 10
done

echo "===== Updating System ====="


echo "===== Enabling and Starting Apache ====="
sudo systemctl enable httpd
sudo systemctl start httpd


echo "ec2-user:${my_password}" | chpasswd

sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

echo "===== Fetching EC2 Instance ID ====="
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

echo "===== Creating HTML Page ====="
cat <<EOF | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>SERVER PAGE</title>
    <link
      href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"
      rel="stylesheet"
    />
    <style>
      body {
        font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
        background-color: #e0e7ff;
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
      }

      .card {
        background: linear-gradient(135deg, #667eea, #764ba2);
        color: white;
        width: 320px;
        padding: 25px;
        border-radius: 15px;
        box-shadow: 0 8px 20px rgba(0, 0, 0, 0.2);
        transition: transform 0.3s, box-shadow 0.3s;
      }

      .card:hover {
        transform: translateY(-10px);
        box-shadow: 0 12px 25px rgba(0, 0, 0, 0.3);
      }

      .card h2 {
        margin-top: 0;
        text-align: center;
        font-size: 1.8em;
      }

      .card .info {
        margin: 15px 0;
        display: flex;
        align-items: center;
        font-size: 1em;
      }

      .card .info i {
        margin-right: 12px;
        color: #ffd700;
        width: 25px;
        text-align: center;
      }

      .card .info span {
        flex: 1;
      }
    </style>
  </head>
  <body>
    <div class="card">
      <h2>Server Page Info</h2>
      <div class="info">
        <i class="fas fa-user"></i> <span><h3>Emmanuel Ezeoyiri</h3></span>
      </div>

      <div class="info">
        <i class="fas fa-id-badge"></i>
        <span><h3>ID: ALT/SOE/025/1060</h3></span>
      </div>
      <div class="info">
        <i class="fas fa-book"></i>
        <span><h3>Course: Cloud Engineering</h3></span>
      </div>
      <div class="info">
        <i class="fas fa-envelope"></i>
        <span><h3>ezeoyiri92@gmail.com</h3></span>
      </div>
      <div class="info">
        <i class="fas fa-network-wired"></i>
        <span><h3>Private IP: $INSTANCE_ID</h3></span>
      </div>
    </div>
  </body>
</html>

EOF

echo "===== Setting Permissions ====="
sudo chown -R apache:apache /var/www

echo "===== Apache Web Server Setup Complete ====="


systemctl restart sshd

