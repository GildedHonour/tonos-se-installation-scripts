# TONOS installation scripts

A script that facilitates installation of TONOS SE node, without Docker.


#### pre-installation for windows

On Windows WSL (Windows Subsystem Linux ) if not installed or activated already will have to be: https://docs.microsoft.com/en-us/windows/wsl/install-win10
Select "Ubuntu 21.x" distribution.

Then activate WSL, preferably the 2nd version rather than the 1st one.

#### installation

Clone the repository and run an installation script as a non-privileged, not root, user.

```
REPO_NAME="??todo"
TMP_PATH=/tmp/$REPO_NAME

cd /tmp
git clone https://github.com/$REPO_NAME
cd $REPO_NAME

./setup.sh
```

However, your user has to have the permission to run "sudo" commands, preferably without password, this way you won't have to enter password during installation multiple times. This is set up via "visudo" command.


#### supported OS:

  * Linux (Ubuntu 21.x)
  * MacOS (Catalina)
  * Windows (via WSL2)
