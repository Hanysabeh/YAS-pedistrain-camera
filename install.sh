#!/bin/bash

# Define variables
REPO_URL="https://api.github.com/repos/Hanysabeh/YAS-pedistrain-camera/releases/latest"
DOWNLOAD_DIR="/opt/YAS-pedistrain-camera"
SERVICE_NAME="YAS-pedistrain-camera"

# Create download directory if it doesn't exist
mkdir -p $DOWNLOAD_DIR

# Download the latest release archive
curl -s $REPO_URL | jq -r '.assets[] | select(.name | contains("tar.gz")) | .browser_download_url' | xargs wget -P $DOWNLOAD_DIR

# Extract the package
tar -xzvf $DOWNLOAD_DIR/package.tar.gz -C $DOWNLOAD_DIR

# Make the main executable script executable
chmod +x $DOWNLOAD_DIR/YAS-pedistrain-camera/install.sh

# Create a desktop shortcut (optional)
cat <<EOF > ~/.local/share/applications/your_application.desktop
[Desktop Entry]
Name=YAS-pedistrain-camera
Exec=$DOWNLOAD_DIR/YAS-pedistrain-camera/install.sh
Icon=$DOWNLOAD_DIR/icon.png
Terminal=false
Type=Application
EOF

# Create a systemd service
cat <<EOF > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=YAS-pedistrain-camera
After=network.target

[Service]
ExecStart=$DOWNLOAD_DIR/your_application_executable
WorkingDirectory=$DOWNLOAD_DIR
Restart=always
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd manager configuration
systemctl daemon-reload

# Enable the service to start on boot
systemctl enable $SERVICE_NAME

# Start the service
systemctl start $SERVICE_NAME

echo "Installation and service setup complete!"



# tar -czf my_app.tar.gz /path/to/your/app/files /path/to/your/config.json install.sh
# wget https://example.com/my_app.tar.gz && tar -xzf my_app.tar.gz && sudo ./install.sh


# cd /home/hany/Desktop/Work/Finished/Deployment/ped/ped/pedstrain_service/
# tar -czf package.tar.gz /home/hany/Desktop/Work/Finished/Deployment/ped/ped/pedstrain_service/ /home/hany/Desktop/Work/Finished/Deployment/ped/ped/pedstrain_service/config.json /home/hany/Desktop/Work/Finished/Deployment/ped/ped/pedstrain_service/install.sh
