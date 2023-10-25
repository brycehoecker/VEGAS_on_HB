#!/bin/bash
#TODO VEGAS INSTALLER SCRIPT checklist
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#1 Need to load conda module
#2 In conda environment need to install VEGAS required programs cmake, gcc, etc...
#3 In conda environment need to install ROOT (software from CERN)
#4 Install veritas related software (vdb & vbf)
#5 Actually install VEGAS software
#6 ADD ADDITONAL STEPS HERE.....
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#!/bin/bash

## MAY NOT BE REQUIRED ON HUMMINGBIRD SINCE MODULES IS ALREADY ACTIVE
## Check if the 'module' command is already available in the current shell
## If not, try to source the environment for modules
#if [ -z "$(type -t module)" ]; then
#    # Source the modules initialization script to make the 'module' command available
#    source /etc/profile.d/lmod.sh
#fi

# Define a function to compare version numbers
# This function returns true if the first version is greater than the second version
version_gt() {
    # Use 'sort -V' to sort version numbers and check the smallest (head -n 1)
    # If the smallest version isn't the first argument, then the first argument is greater
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Read the 'requirements.list' file line by line
while read -r line; do
    # Extract the package name and minimum version from the current line
    package=$(echo "$line" | awk '{print $1}')
    min_version=$(echo "$line" | awk '{print $3}')

    # Check if the package command is available in the terminal using 'command -v'
    # If it is, get its version using the '--version' option and extract the actual version number
    terminal_version=$(command -v "$package" > /dev/null 2>&1 && "$package" --version 2>&1 | head -n1 | awk '{print $NF}' | sed 's/[^0-9.]//g')

    # If the package isn't available in the terminal, check if it's available as a module
    if [ -z "$terminal_version" ]; then
        # Search for the package in the module's available list
        # Extract the version of the module using 'grep' and 'sed'
        module_version=$(module avail 2>&1 | grep "$package" | sed -n 's/.*\('"$package"'\/[^ ]*\).*/\1/p' | sed 's/[^0-9.]//g')
    fi

    # If the package isn't available in either the terminal or as a module, print a message
    if [ -z "$terminal_version" ] && [ -z "$module_version" ]; then
        echo "$package is not available."
    # If the package is available in the terminal but its version is less than required, print a message
    elif [ -n "$terminal_version" ] && version_gt "$min_version" "$terminal_version"; then
        echo "$package version ($terminal_version) is less than the required ($min_version)."
    # If the package is available as a module but its version is less than required, print a message
    elif [ -n "$module_version" ] && version_gt "$min_version" "$module_version"; then
        echo "$package module version ($module_version) is less than the required ($min_version)."
    fi
# Redirect the input of the 'while' loop to the 'requirements.list' file
done < requirements.list
