# Shell Style Guide

This is a collection of best practices for writing shell scripts.

---

## General Guidelines

1. **Shebang**: Always start scripts with `#!/usr/bin/env bash` for portability.
2. **File Permissions**: Ensure scripts have executable permissions.
3. **Error Handling**: Use `set -e` to exit immediately on error.
4. **Comments**: Use comments generously to explain the purpose and
   functionality of the script.

## Naming Conventions

1. **File Names**: Use lowercase letters and hyphens to separate words (e.g.,
   `example-script.sh`).
2. **Variables**: Use lowercase letters and underscores to separate words (e.g.,
   `target_org`).

## Script Structure

1. **Header Comments**: Include a comment block at the beginning of the script
   explaining its purpose and usage.

   ```bash
   ##
   # Script Description
   #
   # Usage:
   #   script_name.sh <arg1> <arg2>
   #
   ```

2. **Set Options**: Use `set -e` to terminate the script on errors. Optionally,
   add `set -u` to treat unset variables as an error.

   ```bash
   set -e
   ```

3. **Parameter Validation**: Validate required parameters and provide meaningful
   error messages.

   ```bash
   if [[ -z "${param}" ]]; then
     echo "Parameter 'param' is required."
     exit 1
   fi
   ```

4. **Variable Initialization**: Initialize variables at the beginning of the
   script.

   ```bash
   target_org="${1}"
   module_dir="${2}"
   ```

## Coding Practices

1. **Use Functions**: Encapsulate reusable code in functions.

   ```bash
   my_function() {
     # Function code
   }
   ```

2. **Consistent Indentation**: Use 2 spaces for indentation.
3. **Quoting**: Always quote variables to prevent word splitting and globbing
   issues.

   ```bash
   echo "${variable}"
   ```

4. **Lowercase Conversions**: Convert input to lowercase for consistency.

   ```bash
   operation=$(echo "${operation}" | tr '[:upper:]' '[:lower:]')
   ```

5. **File Checks**: Check for the existence of required files and provide error
   messages.

   ```bash
   if [[ ! -f "${file_path}" ]]; then
     echo "Error: file not found at ${file_path}."
     exit 1
   fi
   ```

## Example Template

Here is an example template that follows these guidelines:

```bash
#!/usr/bin/env bash

##
# Example Script
#
# This script demonstrates the shell script style guide.
#
# Usage:
#   example_script.sh <arg1> <arg2>
#

set -e

# Validate parameters
arg1="${1}"
if [[ -z "${arg1}" ]]; then
  echo "First parameter arg1 is required."
  exit 1
fi
arg2="${2}"
if [[ -z "${arg2}" ]]; then
  echo "Second parameter arg2 is required."
  exit 1
fi

# Function example
example_function() {
  local param="${1}"
  echo "Parameter: ${param}"
}

# Main execution
example_function "${arg1}"
example_function "${arg2}"
```
