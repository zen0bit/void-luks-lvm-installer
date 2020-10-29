Voidlinux LUKS + GPG + LVM installer
------------------------------------

Basic install script that replaces completely the standard VoidLinux installer.

### Features

- Full Disk Encryption for all partitions except /boot (see [1]), with
  GnuPG smartcard decryption of the LUKS volume at boot time
- Detects UEFI mode and creates partitions accordingly
- Set options from a config file
- Let's you define your LVs from config file
- Supports execution of custom scripts inside install chroot for easy customization
- Optionally add swap

[1]: /boot needs to remain unencrypted in this setup since it's used as
storage for the LUKS GPG-encrypted key file (/boot/luks.key.gpg).
This is an accepted security trade-off for the flexibility of using a
GnuPG smartcard as a hardware MFA device.


### Usage

- Boot a VoidLinux LiveCD
- Setup your network
- Install Git `xbps-install -S git`

Then:

```
git clone https://github.com/zen0bit/void-luks-lvm-installer.git
cd void-luks-lvm-install
```
Edit `config` to your taste.
If needed put your `.sh` scripts in custom dir - see examples - before running `install.sh`
```
./install.sh <path/to/gpg.pub.key>
```
