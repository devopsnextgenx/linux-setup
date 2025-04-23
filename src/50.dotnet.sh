#!/bin/bash

# curl -s -o dotnet-install.sh https://dot.net/v1/dotnet-install.sh
# chmod +x dotnet-install.sh
# ./dotnet-install.sh --channel 9.0

sudo nala install -y dotnet-sdk-9.0 powershell

# /etc/environment

echo """
edit /etc/environment and add the following lines:

DOTNET_ROOT="/usr/lib/dotnet" 
PATH="$PATH:/opt/dotnet:$DOTNT_ROOT/tools"

"""