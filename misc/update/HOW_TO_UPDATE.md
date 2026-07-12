# Update

```sh
cd /var/www/ood/apps/sys
mv bc_desktop bc_desktop.bak
mv projects projects.bak
mv system-status system-status.bak
mv myjobs myjobs.bak
mv module-browser module-browser.bak

git clone git@github.com:OpenOnDemandJP/SshPublicKeyManager.git
git clone git@github.com:RIKEN-RCCS/OpenComposer.git
```

# Initial Installation

```sh
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/rikyu.yml /etc/ood/config/clusters.d/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/global_bc_items.yml /etc/ood/config/ondemand.d/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/ondemand.yml /etc/ood/config/ondemand.d/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/apps /etc/ood/config/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/locales /etc/ood/config/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/rikyu.css /var/www/ood/public/rikyu.css
```

# Apply changes

```sh
touch /var/www/ood/apps/sys/dashboard/tmp/restart.txt
```
