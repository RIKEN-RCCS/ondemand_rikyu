cd /var/www/ood/apps/sys
mv bc_desktop bc_desktop.bak
mv projects projects.bak
mv system-status system-status.bak
mv myjobs myjobs.bak
mv module-browser module-browser.bak

git clone git@github.com:OpenOnDemandJP/SshPublicKeyManager.git

---
Initial Installation

ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/rikyu.yml /etc/ood/config/clusters.d/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/global_bc_items.yml /etc/ood/config/ondemand.d/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/ondemand.yml /etc/ood/config/ondemand.d/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/apps /etc/ood/config/
