#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Usage: ./rename.sh <new_package_name>"
    exit 1
fi

PACKAGE_NAME="$1"

echo "Renaming project to: $PACKAGE_NAME"

# Replace all instances of {{package_name}} in files
grep -rl '{{package_name}}' . | xargs sed -i "s/{{package_name}}/$PACKAGE_NAME/g"

# Rename the package directory
mv src/{{package_name}} "src/$PACKAGE_NAME"

# Update .env IMAGE_BASE_NAME
sed -i "s/IMAGE_BASE_NAME=.*/IMAGE_BASE_NAME=$PACKAGE_NAME/" .env

# Optional: Create sentinel file so Makefile knows rename was run
touch .renamed

echo "Rename complete!"
echo "Next: run 'make init'"

