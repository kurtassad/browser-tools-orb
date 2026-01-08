#!/bin/bash
if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

retry() {
    local -r -i max_attempts=5
    local -i attempt_num=1

    until "$@"; do
        if (( attempt_num == max_attempts )); then
            echo "Attempt $attempt_num failed and there are no more attempts left!"
            exit 1
        else
            echo "Attempt $attempt_num failed! Trying again..."
            ((attempt_num++))
            $SUDO rm -rf /var/lib/apt/lists/*
            sleep 5
        fi
    done
}

if uname -a | grep Darwin >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "You need brew to install Edge on MacOS"
    exit 1
  fi
  brew install --cask microsoft-edge
  if "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" --version >/dev/null 2>&1; then
    echo "Microsoft Edge version was installed."
  else
    echo "Microsoft Edge could not be installed"
    exit 1
  fi
elif command -v apt >/dev/null 2>&1; then
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge-stable.list
  if [ "$ORB_PARAM_VERSION" != "latest" ]; then
    VERSION="=$ORB_PARAM_VERSION-1"
  fi
  retry $SUDO apt-get update
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "microsoft-edge-stable$VERSION"
  if command -v microsoft-edge >/dev/null 2>&1; then
    echo "Microsoft Edge version $(microsoft-edge --version) was installed."
  else
    echo "Microsoft Edge could not be installed"
    exit 1
  fi
fi
