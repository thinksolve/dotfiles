when modifying the base emacs binary (e.g. emacs@29 to emacs@30 most recently) need to do the following in terminal:


# backup the existing Emacs.icns file
mv /opt/homebrew/Cellar/emacs-plus@30/30.1/Emacs.app/Contents/Resources/Emacs.icns /opt/homebrew/Cellar/emacs-plus@30/30.1/Emacs.app/Contents/Resources/Emacs.icns.bak

# create new one or symlink from version controlled source 

ln -s ~/.dotfiles/doom/emacs-icons/Emacs.icns /opt/homebrew/Cellar/emacs-plus@30/30.1/Emacs.app/Contents/Resources/Emacs.icns

# refresh dock icons
sudo rm -rf /Library/Caches/com.apple.iconservices.store && killall Dock

