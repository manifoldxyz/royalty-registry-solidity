#!/bin/bash

# append newline since loop will not process last line without it??
if [[ $(tail -c1 watched_contracts.txt | wc -l) -eq 0 ]] ; then
  echo >> watched_contracts.txt
fi

# Open the file for reading using cat
cat watched_contracts.txt | while read -r LINE; do
  # Loop over the list of strings
  for i in "${LINE[@]}"; do
    # Skip empty strings
    if [ -z "$i" ]; then
      continue
    fi
    # Interpolate the string in a command
    forge inspect $i storage | jq '.["storage"] |= map(. + {_contract: .contract, _type: .type} | del(.contract, .type))' | jq '{_storage: .storage}'  > storage_layouts/"$i"_latest.json
  done
done