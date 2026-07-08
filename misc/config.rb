require "yaml"
require "erb"

# Load site-specific configuration from config.yml located in the same directory
# as this Ruby file, evaluate embedded ERB, and extract only the values required
# by the application.
#
# Returns:
# - xdg_data_home   (String): Base directory for application data storage
# - container_image (String): Container image name used for job execution
#
def load_app_config
  config_path = File.join(__dir__, "config.yml")
  config = YAML.safe_load(
    ERB.new(File.read(config_path)).result,
    aliases: true
  )

  [
    config["xdg_data_home"],
    config["container_image"]
  ]
end

# Generate the Xfce startup shell script used by Open OnDemand applications.
#
# This method returns a Bash script that initializes the Xfce desktop
# environment inside the interactive session. 
#
# When is_virtualgl is true, the script enables VirtualGL support for
# hardware-accelerated OpenGL rendering (e.g., for visualization workloads).
#
def set_xfce(is_virtualgl = false)
  <<~BASH
#!/usr/bin/env bash
  
# Change working directory to user's home directory
cd "${HOME}"

# Use a separate XDG config directory for OOD XFce
export XDG_CONFIG_HOME="${HOME}/.ood-config-xfce"
mkdir -p "${XDG_CONFIG_HOME}"
cat > "${XDG_CONFIG_HOME}/user-dirs.conf" <<'EOF'
enabled=False
EOF

cat > "${XDG_CONFIG_HOME}/user-dirs.dirs" <<'EOF'
XDG_DESKTOP_DIR="$HOME"
XDG_DOWNLOAD_DIR="$HOME"
XDG_TEMPLATES_DIR="$HOME"
XDG_PUBLICSHARE_DIR="$HOME"
XDG_DOCUMENTS_DIR="$HOME"
XDG_MUSIC_DIR="$HOME"
XDG_PICTURES_DIR="$HOME"
XDG_VIDEOS_DIR="$HOME"
EOF

mkdir -p "${XDG_CONFIG_HOME}/xfce4"
sed -i '/^WebBrowser=/d' "${XDG_CONFIG_HOME}/xfce4/helpers.rc" 2>/dev/null || true
echo "WebBrowser=firefox" >> "${XDG_CONFIG_HOME}/xfce4/helpers.rc"
    
# Reset module environment (may require login shell for some HPC clusters)
#module purge && module restore
  
# Ensure that the user's configured login shell is used
export SHELL="$(getent passwd $USER | cut -d: -f7)"
  
# use a safe PATH to boot the desktop because dbus-launch can be
# in another location from a python/conda installation and that will
# conflict and cause issues. See https://github.com/OSC/ondemand/issues/700 for more.
#SAFE_PATH="/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/bin"
  
# Start up desktop
#PATH="$SAFE_PATH" source "<%= session.staged_root.join("xfce.sh") %>"

# Remove any preconfigured monitors
if [[ -f "${XDG_CONFIG_HOME}/monitors.xml" ]]; then
  mv "${XDG_CONFIG_HOME}/monitors.xml" "${XDG_CONFIG_HOME}/monitors.xml.bak"
fi
  
# Copy over default panel if doesn't exist, otherwise it will prompt the user
PANEL_CONFIG="${XDG_CONFIG_HOME}/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
if [[ ! -e "${PANEL_CONFIG}" ]]; then
  mkdir -p "$(dirname "${PANEL_CONFIG}")"
  cp "/etc/xdg/xfce4/panel/default.xml" "${PANEL_CONFIG}"
fi
  
# Disable startup services
xfconf-query -c xfce4-session -p /startup/ssh-agent/enabled -n -t bool -s false
xfconf-query -c xfce4-session -p /startup/gpg-agent/enabled -n -t bool -s false
  
# Disable useless services on autostart
AUTOSTART="${XDG_CONFIG_HOME}/autostart"
rm -fr "${AUTOSTART}"    # clean up previous autostarts
mkdir -p "${AUTOSTART}"
for service in "pulseaudio" "rhsm-icon" "spice-vdagent" "tracker-extract" "tracker-miner-apps" "tracker-miner-user-guides" "xfce4-power-manager" "xfce-polkit"; do
  echo -e "[Desktop Entry]\nHidden=true" > "${AUTOSTART}/${service}.desktop"
done

# Run Xfce4 Terminal as login shell (sets proper TERM)
TERM_CONFIG="${HOME}/.config/xfce4/terminal/terminalrc"
if [[ ! -e "${TERM_CONFIG}" ]]; then
  mkdir -p "$(dirname "${TERM_CONFIG}")"
  sed 's/^ \{4\}//' > "${TERM_CONFIG}" << EOL
    [Configuration]
    CommandLoginShell=TRUE
EOL
else
  sed -i \
    '/^CommandLoginShell=/{h;s/=.*/=TRUE/};${x;/^$/{s//CommandLoginShell=TRUE/;H};x}' \
    "${TERM_CONFIG}"
fi
  
# launch dbus first through eval becuase it can conflict with a conda environment
# see https://github.com/OSC/ondemand/issues/700
eval $(dbus-launch --sh-syntax)

# Enable VirtualGL
_VIRTUALGL=""
[ "#{is_virtualgl}" = "true" ] && _VIRTUALGL="vglrun -d egl"

BASH
end

# Generate YAML in submit.sh.erb
def script(name, hours, gpus, processes, email = "")
  yaml =  "  job_name: #{name}\n"
  yaml << "    native:\n"
  yaml << "      - \"--time=#{hours}:00:00\"\n"
  yaml << "      - \"--gpus=#{gpus}\"\n"
  yaml << "      - \"--ntasks=#{processes}\"\n"	unless processes.blank?
  unless email.blank?
    yaml << "    email: #{email}\n"
    yaml << "    email_on_started: true\n"
  end

  yaml
end
