#!/usr/bin/env bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
INSTALL_DIR="$HOME/minecraft"

# Prerequisites
sudo apt-get update
sudo apt-get install -y libpam-systemd wget curl unzip tar screen

# Stop server if it is still running
"$SCRIPT_DIR/stop.sh" > /dev/null

# Download and unpack OpenJDK 17
echo
read -r -p "Install OpenJDK 17? (Y/N): " 
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then

    JAVA_HOME="/opt/jdk-17"
    JDK_ZIP="openjdk-17_linux-x64_bin.tar.gz"
    [ ! -f "$JDK_ZIP" ] && wget "https://download.java.net/java/GA/jdk17/0d483333a00540d886896bac774ff48b/35/GPL/$JDK_ZIP"
    sudo tar xvf "$JDK_ZIP"
    sudo rm -rf "$JAVA_HOME"
    sudo mv "./jdk-17" "/opt/"
    sudo rm -rf "./jdk-17"
    rm -i "$JDK_ZIP"

    # Add Java executables to PATH
    WRITE="export JAVA_HOME=\"$JAVA_HOME\"\nexport PATH=\"\$PATH:\$JAVA_HOME/bin\"\n"
    FILE="/etc/profile.d/java-path.sh"
    echo -e "$WRITE" | sudo tee "$FILE" > /dev/null
    sudo chmod a+x "$FILE"

    source "/etc/profile"

    echo "Java has been installed to $JAVA_HOME"
    java -version
    echo

fi

# Install Gradle build system
echo
read -r -p "Install Gradle 7.4.2? (Y/N): " 
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then

    GRADLE_HOME="/opt/gradle/gradle-7.4.2"
    GRADLE_ZIP="gradle-7.4.2-bin.zip"
    [ ! -f "$GRADLE_ZIP" ] && wget "https://downloads.gradle-dn.com/distributions/$GRADLE_ZIP"
    sudo mkdir -p "/opt/gradle"
    sudo rm -rf "$GRADLE_HOME"
    sudo unzip "$GRADLE_ZIP" -d "/opt/gradle"
    rm -i "$GRADLE_ZIP"

    # Add Gradle executables to PATH
    WRITE="export GRADLE_HOME=\"$GRADLE_HOME\"\nexport PATH=\"\$PATH:\$GRADLE_HOME/bin\"\n"
    FILE="/etc/profile.d/gradle-path.sh"
    echo -e "$WRITE" | sudo tee "$FILE" > /dev/null
    sudo chmod a+x "$FILE"

    source "/etc/profile"

    echo "Gradle has been installed to $GRADLE_HOME"
    gradle -version
    echo

fi

# Clone Paper Minecraft Server Repo
echo
echo "The server will install to \"$INSTALL_DIR\"."
echo "If a server already exists at this location it will be updated to the latest version."
echo "Existing world files and configuration will not be affected."
echo
read -r -p "Continue to download and install Paper MC Server? (Y/N): " 
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then

    mkdir -p "$INSTALL_DIR/systemctl"
    cd "$INSTALL_DIR"
    cp -f "$SCRIPT_DIR/console.sh" "./"
    cp -f "$SCRIPT_DIR/start.sh" "./"
    cp -f "$SCRIPT_DIR/status.sh" "./"
    cp -f "$SCRIPT_DIR/stop.sh" "./"
    cp -f "$SCRIPT_DIR/update.sh" "./"
    chmod +x ./*.sh
    rm -rf "./systemctl/*"
    cp -f "$SCRIPT_DIR/systemctl/start_process.sh" "./systemctl/"
    cp -f "$SCRIPT_DIR/systemctl/stop_process.sh" "./systemctl/"
    cp -f "$SCRIPT_DIR/systemctl/stuff_process.sh" "./systemctl/"
    chmod +x ./systemctl/*.sh

    "./update.sh"

fi

# Register as a systemd user service
mkdir -p "$HOME/.config/systemd/user"
cp -f "$SCRIPT_DIR/systemctl/minecraft.service" "$HOME/.config/systemd/user/minecraft.service"
systemctl --user enable minecraft
systemctl --user daemon-reload
echo
read -r -p "Set server to run automatically at boot? (Y/N): " 
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    loginctl enable-linger $USER
else
    loginctl disable-linger $USER
fi

# Reboot
echo
echo "A reboot is required."
read -r -p "Reboot now? (Y/N): " 
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then

    sudo shutdown -r now

fi
