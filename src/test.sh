#!/bin/bash

// store extensions list to a variable
# Store the output of the command in a variable
extensions_list=$(gnome-extensions list)

# loop through the extensions list
for extension in $extensions_list; do
  # Check if the extension is enabled
  if gnome-extensions list --enabled | grep -q "$extension"; then
    gnome-extensions show "$extension" 
  fi
done