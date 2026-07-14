# Common

```sh
cd /var/www/ood/apps/sys
for app in bc_desktop projects system-status myjobs module-browser; do
  rm -rf "${app}.bak"
  mv "${app}" "${app}.bak"
done

for app in shell activejobs files; do
  cp "${app}/manifest.yml" "${app}/manifest.yml.bak"
  cat >> "${app}/manifest.yml" <<'EOF'

tile:
  sub_caption: |
EOF
done
```

# Initial Installation

```sh
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/rikyu.yml /etc/ood/config/clusters.d/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/global_bc_items.yml.erb /etc/ood/config/ondemand.d/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/ondemand.yml /etc/ood/config/ondemand.d/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/apps /etc/ood/config/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/locales /etc/ood/config/
ln -s /var/www/ood/apps/sys/ondemand_rikyu/misc/update/rikyu.css /var/www/ood/public/rikyu.css

cd /var/www/ood/apps/sys
git clone git@github.com:OpenOnDemandJP/SshPublicKeyManager.git
git clone git@github.com:RIKEN-RCCS/OpenComposer.git
```

# Apply changes

```sh
touch /var/www/ood/apps/sys/dashboard/tmp/restart.txt
```
