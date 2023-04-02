# Bootstrap: 
This Bootstrap script is designed to get your bright and shiny new macOS ready for use via a *private* set of GitLab scripts. 
It will walk you through the generation of RSA keys and open GitLab (via Safari) to add the key to your profile.
From there, it will proceed to clone a dotFiles folder that can be further processed/executed.

```
sudo softwareupdate -i -a
xcode-select --install
git clone https://gitlab.com/heymarkarana/bootstrap.git $HOME/.bootstrap
$HOME/.bootstrap/bootstrap install
```
**Commands:**<BR>
**install**     - Fresh install of .dotfiles<BR>
**refresh**     - Removes existing .dotfiles and provides a refresh<P>


This is primarily built off Lars Kappert's excellent [work](https://medium.com/@webprolific/getting-started-with-dotfiles-43c3602fd789). 