#!/bin/bash

# append newline since loop will not process last line without it??
if [[ $(tail -c1 watched_contracts.txt | wc -l) -eq 0 ]] ; then
  echo >> watched_contracts.txt
fi

# copy contract_latest.json to contract.json for each contract in watched_contracts.txt

# Open the file for reading using cat
cat watched_contracts.txt | while read -r LINE; do
  # Loop over the list of strings
  for i in "${LINE[@]}"; do
    # Skip empty strings
    if [ -z "$i" ]; then
      continue
    fi
    # Interpolate the string in a command
    cp storage_layouts/"$i"_latest.json storage_layouts/"$i".json
  done
done
