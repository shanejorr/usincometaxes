#!/bin/bash
file1_hash=$(shasum "$1" | awk '{print $1}')
file2_hash=$(shasum "$2" | awk '{print $1}')

if [ "$file1_hash" == "$file2_hash" ]; then
  echo "The files are identical."
else
  echo "The files are different."
fi
