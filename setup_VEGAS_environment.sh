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

# Check if the 'module' command is already available in the current shell.
# 'module' is a system that provides a convenient way to dynamically change the users' environment through modulefiles.
if [ -z "$(type -t module)" ]; then
    # If the 'module' command isn't present, we source its initialization script.
    source /etc/profile.d/lmod.sh
fi

# Define a function to compare version numbers.
version_gt() {
    # The function uses 'sort -V' to handle version number sorting.
    # It checks if the smallest version (found by `head -n 1`) is not equal to the first argument.
    # If so, it means the first argument is greater than the second.
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# If the `missing_packages.list` file exists, remove it to start fresh.
# This ensures we don't append to an old version of the file.
rm -f missing_packages.list

# Process the 'requirements.list' file line by line.
while read -r line; do
    # Extract the package name and its required version from the line.
    package=$(echo "$line" | awk '{print $1}')
    min_version=$(echo "$line" | awk '{print $3}')

    # Check if the package is available in the terminal.
    # If so, get its version. If not, `$terminal_version` remains empty.
    terminal_version=$(command -v "$package" > /dev/null 2>&1 && "$package" --version 2>&1 | head -n1 | awk '{print $NF}' | sed 's/[^0-9.]//g')

    # If the package isn't found in the terminal, we'll search if it's available as a module.
    if [ -z "$terminal_version" ]; then
        module_version=$(module avail 2>&1 | grep "$package" | sed -n 's/.*\('"$package"'\/[^ ]*\).*/\1/p' | sed 's/[^0-9.]//g')
    fi

    # Handle various conditions based on the package's availability and its version:

    # If neither terminal nor module version is found, it's considered missing.
    if [ -z "$terminal_version" ] && [ -z "$module_version" ]; then
        echo "$package >= $min_version" >> missing_packages.list
        echo -e "\033[31m$package is not installed.\033[0m"
    # If found in the terminal but its version doesn't meet the requirement.
    elif [ -n "$terminal_version" ] && version_gt "$min_version" "$terminal_version"; then
        echo "$package >= $min_version" >> missing_packages.list
        echo -e "\033[31m$package installed version ($terminal_version) does not meet the required version ($min_version).\033[0m"
    # If found as a module but its version doesn't meet the requirement.
    elif [ -n "$module_version" ] && version_gt "$min_version" "$module_version"; then
        echo "$package >= $min_version" >> missing_packages.list
        echo -e "\033[31m$package module version ($module_version) does not meet the required version ($min_version).\033[0m"
    # If the package meets the requirements (either in terminal or as a module).
    else
        version_to_display=${terminal_version:-$module_version}
        echo -e "\033[32m$package is installed with version $version_to_display.\033[0m"
    fi
done < requirements.list
