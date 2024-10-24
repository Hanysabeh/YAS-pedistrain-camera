#!/bin/bash

# Define variables
REPO_URL="https://api.github.com/repos/Hanysabeh/YAS-pedistrain-camera/releases/latest"
DOWNLOAD_DIR="/opt/YAS-pedistrain-camera"
SERVICE_NAME="YAS-pedistrain-camera"
PACKAGE_NAME="package.tar.gz"
PYTHON_VERSION="3.9.20"

# Function to install Python
install_python() {
    if ! command -v python3 &> /dev/null; then
        echo "Python3 not found. Installing Python $PYTHON_VERSION..."
        apt-get update
        apt-get install -y python$PYTHON_VERSION python3-pip
    else
        echo "Python3 is already installed."
    fi
}

# Create download directory if it doesn't exist
mkdir -p $DOWNLOAD_DIR

# Download the latest release archive
curl -s $REPO_URL | jq -r '.assets[] | select(.name | contains("tar.gz")) | .browser_download_url' | xargs wget -O $DOWNLOAD_DIR/$PACKAGE_NAME

# Extract the package
tar -xzvf $DOWNLOAD_DIR/$PACKAGE_NAME -C $DOWNLOAD_DIR

# Install Python if necessary
install_python

# Create virtual environment and activate it
python3 -m venv $DOWNLOAD_DIR/venv
source $DOWNLOAD_DIR/venv/bin/activate

# Install required Python libraries
pip install -r $DOWNLOAD_DIR/YAS-pedistrain-camera/requirements.txt

# Make the main executable script executable
chmod +x $DOWNLOAD_DIR/YAS-pedistrain-camera/install.sh

# Create a desktop shortcut (optional)
cat <<EOF > ~/.local/share/applications/YAS-pedistrain-camera.desktop
[Desktop Entry]
Name=YAS-pedistrain-camera
Exec=$DOWNLOAD_DIR/YAS-pedistrain-camera/install.sh
Icon=$DOWNLOAD_DIR/YAS-pedistrain-camera/openart.jpg
Terminal=false
Type=Application
EOF

# Create a systemd service
cat <<EOF > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=YAS-pedistrain-camera Service
After=network.target

[Service]
ExecStart=$DOWNLOAD_DIR/venv/bin/python $DOWNLOAD_DIR/YAS-pedistrain-camera/install.sh
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
