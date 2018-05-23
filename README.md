# Bash script for a custom ISO

Need packages (checked in the script):

    sudo
    rsync
    xorriso
    isolinux


# How to use 
```bash
bash -c "$(curl https://raw.githubusercontent.com/lalalolo49/script-debian-preseed/master/preseed-script.sh)" _ "<put_your_iso_path_here>"

Options
-h	Show help
-clean	Delete folder isoorig and isonew
```

