#!/bin/bash

# https://wiki.ubuntu.com/PbuilderHowto

target_distro=precise # :)
source_distro=trusty
host_pkgs="ubuntu-dev-tools dput mini-dinstall"

dependencies="debhelper dpkg dpkg-dev"
package=libproc-processtable-perl

export DEBIAN_FRONTEND=noninteractive

cd /home/vagrant
if [ "$(find /var/lib/apt/periodic/update-success-stamp -mmin +180)" ]
then
  apt-get update
  apt-get upgrade -y
fi
for pkg in $host_pkgs
do
  apt-get install -y $pkg
done

sudo -iu vagrant tee ~vagrant/.mini_dinstall.conf <<EOF_MINI_DINSTALL
[DEFAULT]
architectures = all, i386, amd64, powerpc
archivedir = /var/cache/archive/
use_dnotify = 0
verify_sigs = 0
#extra_keyrings = ~/.gnupg/pubring.gpg
mail_on_success = 0
archive_style = flat
poll_time = 10
mail_log_level = NONE

[precise-backports]

EOF_MINI_DINSTALL

sudo -iu vagrant tee ~vagrant/.dput.cf << EOF_DPUT_CF
[local]
method = local
incoming = /var/cache/archive/mini-dinstall/incoming
allow_non-us_software = 1
run_dinstall = 0
post_upload_command = mini-dinstall --batch -c /home/vagrant/.mini_dinstall.conf
EOF_DPUT_CF

mkdir -p /var/cache/archive/mini-dinstall/incoming
chown -R vagrant /var/cache/archive

sudo -iu vagrant tee -a ~vagrant/.pbuilderrc << EOF_PBUILDERRC
OTHERMIRROR="deb file:///var/cache/archive $target_distro/"
EOF_PBUILDERRC
# Well. It is easier. :)
[ ! -e ~vagrant/pbuilder/$target_distro-base.tgz ] && sudo -iu vagrant pbuilder-dist $target_distro create

for n in $dependencies
do
  [ ! -e ~vagrant/buildresult/$n*.deb ] &&
    yes | sudo -iu vagrant backportpackage -B pbuilder-dist -s $source_distro -d $target_distro -w . -b --dont-sign $n
done
for n in ~vagrant/buildresult/*.changes
do
  sudo -iu vagrant dput -u local $n -c ~vagrant/.mini_dinstall.conf
done

sudo -iu vagrant pbuilder-dist precise execute --save-after-exec /vagrant/install_stuff.sh $dependencies
yes | sudo -iu vagrant backportpackage -B pbuilder-dist -s $source_distro -d $target_distro  -w . -b --dont-sign $package 
cp ~vagrant/buildresult/$package*.deb /vagrant/
