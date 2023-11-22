# check if root (Don't need it if the script is not run with sudo)
# if [ "$EUID" -ne 0 ]; then
#   echo "Please run as root"
#   exit
# fi

# Get home directory of user
if [ "$(id -u)" -eq 0 ]; then
  USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
fi

# Get the directory where the plugin is installed(System or local)
if [ -e "$USER_HOME/.local/share/gnome-shell/extensions/gsconnect@andyholmes.github.io/service/" ]; then
  extension_dir="$USER_HOME/.local/share/gnome-shell/extensions/gsconnect@andyholmes.github.io/service/"
else
  extension_dir="/usr/share/gnome-shell/extensions/gsconnect@andyholmes.github.io/service/"
fi

echo ""
block_of_code="this block of code is not part of gsconnect connect extension"
if grep -q "$block_of_code" "$extension_dir/plugins/sftp.js"; then
  echo "Patch is already applied"
  echo "To Update, Reinstall gsconnect extension and Try Again"
  exit 1
fi

# changing directory to the script directory
script_dir=$(dirname "$0")
cd "$script_dir" || exit # Exit the script if cd doesn't work, prevents following commands from running

# putting files in place
cp -f ./mountInfoHandler.js "$extension_dir/utils/"
mkdir -p "$USER_HOME/.config/gsconnect-mount-manager/" && cp -f ./run.py "$USER_HOME/.config/gsconnect-mount-manager/"
[ -e /etc/systemd/user/gsconnect-mount-manager.service ] || sudo touch /etc/systemd/user/gsconnect-mount-manager.service

# update service file
# Change > to " | sudo tee " because shell doesn't have to permission to redirect to system file
# ( It would work if the whole script is run with sudo )
#
echo "Creating a user systemd service"
echo " "
sudo ./update_servicefile.py "$USER_HOME" "$script_dir" | sudo tee /etc/systemd/user/gsconnect-mount-manager.service

# editing sftp.js in gsconnect extension
#

echo " "
echo "Editing sftp.js in gsconnect extension"
sudo ./update_sftp.py "$USER_HOME"

echo " "
echo "====================DONE!===================="
echo "============================================="
echo "Be Sure to run ./enableService.sh after this"
