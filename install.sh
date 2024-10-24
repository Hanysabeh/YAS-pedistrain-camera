#!/bin/bash

# Define variables
REPO_URL="https://api.github.com/repos/Hanysabeh/YAS-pedistrain-camera/releases/latest"
DOWNLOAD_DIR="/opt/YAS-pedistrain-camera"
SERVICE_NAME="YAS-pedistrain-camera"
PACKAGE_NAME="package.tar.gz"
PYTHON_VERSION="3.10"

# Function to install dependencies
install_dependencies() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update
        sudo apt-get install -y curl jq wget tar python3 python3-pip python3-venv
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew update
        brew install curl jq wget python3
    else
        echo "Unsupported OS for automated dependency installation."
        exit 1
    fi
}

# Function to install Python
install_python() {
    if ! command -v python3 &> /dev/null; then
        echo "Python3 not found. Installing Python $PYTHON_VERSION..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get install -y python$PYTHON_VERSION python3-pip
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install python3
        else
            echo "Unsupported OS for Python installation."
            exit 1
        fi
    else
        echo "Python3 is already installed."
    fi
}

# Create download directory if it doesn't exist
mkdir -p $DOWNLOAD_DIR

# Install dependencies
install_dependencies

# Download the latest release archive
DOWNLOAD_URL=$(curl -s $REPO_URL | jq -r '.assets[] | select(.name | endswith("tar.gz")) | .browser_download_url')

# Check if the URL retrieval was successful
if [ -z "$DOWNLOAD_URL" ]; then
    echo "Failed to retrieve the download URL. Please check your internet connection and try again."
    exit 1
fi

# Download the package
wget -O $DOWNLOAD_DIR/$PACKAGE_NAME $DOWNLOAD_URL

# Verify the download
if [ ! -f $DOWNLOAD_DIR/$PACKAGE_NAME ]; then
    echo " Download failed or the file does not exist. Please check your internet connection and try again."
    exit 1
fi

# Extract the package
tar -xzvf $DOWNLOAD_DIR/$PACKAGE_NAME -C $DOWNLOAD_DIR

# Install Python if necessary
install_python

# Create virtual environment and activate it
python3 -m venv $DOWNLOAD_DIR/venv
source $DOWNLOAD_DIR/venv/bin/activate

# Check if the requirements file exists
if [ ! -f $DOWNLOAD_DIR/YAS-pedistrain-camera/requirements.txt ]; then
    echo "Requirements file not found. Please ensure the package is correctly extracted."
    exit 1
fi

# Install required Python libraries
pip install -r $DOWNLOAD_DIR/YAS-pedistrain-camera/requirements.txt

# Make the main executable script executable
if [ ! -f $DOWNLOAD_DIR/YAS-pedistrain-camera/install.sh ]; then
    echo "Main executable script not found. Please ensure the package is correctly extracted."
    exit 1
fi

chmod +x $DOWNLOAD_DIR/YAS-pedistrain-camera/install.sh

# Create a desktop shortcut (optional, for Linux/macOS)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    mkdir -p ~/.local/share/applications
    cat <<EOF > ~/.local/share/applications/YAS-pedistrain-camera.desktop
[Desktop Entry]
Name=YAS-pedistrain-camera
Exec=$DOWNLOAD_DIR/YAS-pedistrain-camera/install.sh
Icon=$DOWNLOAD_DIR/YAS-pedistrain-camera/openart.jpg
Terminal=false
Type=Application
EOF
fi

# Create a systemd service (for Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo bash -c "cat <<EOF > /etc/systemd/system/$SERVICE_NAME.service
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
EOF"
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
    sudo systemctl start $SERVICE_NAME
fi

echo "Installation and service setup complete!"



# tar -czf my_app.tar.gz /path/to/your/app/files /path/to/your/config.json install.sh
# wget https://example.com/my_app.tar.gz && tar -xzf my_app.tar.gz && sudo ./install.sh


# cd /home/hany/Desktop/Work/Finished/Deployment/ped/ped/pedstrain_service/
# tar -czf package.tar.gz /home/hany/Desktop/Work/Finished/Deployment/ped/ped/pedstrain_service/ /home/hany/Desktop/Work/Finished/Deployment/ped/ped/pedstrain_service/config.json /home/hany/Desktop/Work/Finished/Deployment/ped/ped/pedstrain_service/install.sh
