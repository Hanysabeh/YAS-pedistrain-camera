#!/bin/bash

# Define variables
PACKAGE_URL="http://example.com/path/to/your/application/package.tar.gz"
INSTALL_DIR="/opt/your_application"

# Create install directory if it doesn't exist
mkdir -p $INSTALL_DIR

# Download the package
wget -O $INSTALL_DIR/package.tar.gz $PACKAGE_URL

# Extract the package
tar -xzvf $INSTALL_DIR/package.tar.gz -C $INSTALL_DIR

# Make the main executable script executable
chmod +x $INSTALL_DIR/your_application_executable

# Create a desktop shortcut (optional)
cat <<EOF > ~/.local/share/applications/your_application.desktop
[Desktop Entry]
Name=Your Application
Exec=$INSTALL_DIR/your_application_executable
Icon=$INSTALL_DIR/icon.png
Terminal=false
Type=Application
EOF

echo "Installation complete!"

# chmod +x ped.sh
# sudo ./ped.sh


# tar -czf my_app.tar.gz /path/to/your/app/files /path/to/your/config.json install.sh
# wget https://example.com/my_app.tar.gz && tar -xzf my_app.tar.gz && sudo ./install.sh


# cd /home/hany/Desktop/Work/Finished/Deployment/ped/ped/pedstrain_service/
# tar -czf package.tar.gz /home/hany/Desktop/Work/Finished/Deployment/ped/ped/pedstrain_service/ /home/hany/Desktop/Work/Finished/Deployment/ped/ped/pedstrain_service/config.json /home/hany/Desktop/Work/Finished/Deployment/ped/ped/pedstrain_service/install.sh
