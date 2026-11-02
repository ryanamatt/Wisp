set default-list := true

# Build All, or Specific Module
build module="":
    ./tools/build.sh {{module}}

# Run Format or Check Formatting
[arg("check", long="check", value="--check")]
format check="":
    ./tools/format.sh {{ check }}

# Run Dev Version of Wisp
run:
    ./run.sh

# Install Wisp
install:
    ./install.sh

# Uninstall Wisp
uninstall:
    ./uninstall.sh

