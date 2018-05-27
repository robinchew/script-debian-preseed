Only tested on Debian 9
Doesn't work on Centos since there is no "xorriso"

# Bash script for a custom ISO

Need packages (checked in the script):

    isolinux
    rsync
    sudo
    sed
    xorriso


# How to use 
```bash
sudo bash -c "$(curl https://raw.githubusercontent.com/lalalolo49/script-debian-preseed/master/preseed-script.sh)" _ "<put_your_iso_path_here>"

Options
-h	Show help
-clean	Delete folder isoorig and isonew
```

