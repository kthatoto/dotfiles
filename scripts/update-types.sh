update-types() {
  de app bin/update_types
  echo "======== update_types finished ========"

  # Check if there are any changes
  if [[ -n "$(git status --porcelain)" ]]; then
    git status
    echo -n "Changes detected. Commit? [Y/n]: "
    read -r answer

    if [[ "$answer" == "Y" || "$answer" == "y" || -z "$answer" ]]; then
      git add .
      git commit -m "update types"
    else
      echo "Skipped commit."
    fi
  else
    echo "No changes detected. Nothing to commit."
  fi
}
