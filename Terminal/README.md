# Batch Connect Shell

This application is obtain from https://code.oscer.ou.edu/OnDemand/ood-apps-nmsu/-/tree/main/shell

## Security
- ttyd password is visible in /proc (ps command) due to the password being passed directly in the call.
  - To mitigate this impliment the 'hidepid' mount option to '/proc' in order to prevent users from seeing processes that do not belong to them.
    - [RHEL 7+ reccomends against using hidepid](https://access.redhat.com/solutions/6704531) so another solution is likely needed.
- To solve this problem, -m 1 is added to the ttyd option. This option ensures that only one client can connect.

## Note
The tmux in Rocky 8 is old and may cause some errors. Please use Rocky 9 or later, or build it from source code with the following command.
```
$ wget https://github.com/tmux/tmux/archive/refs/tags/3.6a.tar.gz
$ tar xfz 3.6a.tar.gz
$ cd tmux-3.6a
$ sh autogen.sh
$ ./configure --prefix=<INSTALL_PATH>
$ make
$ sudo make install
```

How to generate static files using cross-compilation. Run the following commands in an x86_64 environment.
```
cd ${HOME}
git clone https://github.com/OpenOnDemandJP/ttyd.git
cd ttyd/
cp /var/www/ood/apps/sys/ondemand_rikyu/Terminal/misc/CMakeLists.txt .
cp /var/www/ood/apps/sys/ondemand_rikyu/Terminal/misc/cross-build.sh scripts/
CROSS_ROOT="$HOME/ttyd_tmp/local" BUILD_ROOT="$HOME/ttyd_tmp/build" STAGE_ROOT="$HOME/ttyd_tmp/stage" BUILD_TARGET=arm64 ./scripts/cross-build.sh
cp build/ttyd /home/ondemand/softwares/oodjp_ttyd/bin/ttyd
```
