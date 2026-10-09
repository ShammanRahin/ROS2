# Machine setup — dual boot Windows + Ubuntu 24.04

How my PC was set up for this repo, and the problems I hit on the way (with what actually fixed them).

## Hardware

| Part | What |
|---|---|
| Motherboard | Gigabyte X570 UD |
| GPU | AMD Radeon (open-source driver built into Ubuntu — no extra driver needed) |
| Drive 1 | Samsung 980 250 GB NVMe — Windows (C:) |
| Drive 2 | HP S700 500 GB SATA SSD — Ubuntu + a shared NTFS data partition (Windows F:) |

HP SSD layout:

| Partition | Size | Use |
|---|---|---|
| sda1 | 1 GB, FAT32 | EFI boot partition for Ubuntu |
| sda2 | ~117 GB, ext4 | Ubuntu `/` |
| sda5 | ~348 GB, NTFS | shared data drive (F: in Windows) |

## Installing Ubuntu 24.04

1. Made a USB stick with **Rufus**, *Persistent partition size = 0*.
2. Booted it with **F12** → *Try or Install Ubuntu* → waited for the desktop → *Install Ubuntu*.
3. **Manual installation**: free space → **+** → Ext4, mount point `/`. Boot loader device = the drive Ubuntu goes on.
4. Left *"third-party software for graphics and Wi-Fi"* unticked (AMD GPU doesn't need it).
5. Boot order in the BIOS: Ubuntu first. Windows is in the GRUB menu, or F12 → *Windows Boot Manager*.

After installing:

```bash
timedatectl set-local-rtc 1 --adjust-system-clock   # stop Windows' clock jumping 6 hours
sudo apt update && sudo apt full-upgrade -y
```

## Problems and fixes

### "Broken Desktop File" / snap errors in the USB live session
**Cause:** Rufus' persistent partition. **Fix:** rewrite the USB with *Persistent partition size = 0*.

### Boot failures: `grubx64.efi – Device Error`, `KERNEL PANIC … unknown-block(0,0)`, `failure reading sector … from 'hd1'`
These looked like three different problems but were one: **a loose SATA cable on the HP SSD**.
GRUB (which reads the disk through the motherboard firmware) got read errors while loading Ubuntu's files, then the kernel started without its initrd and panicked. Windows' event log showed the same thing (`storahci` 129 *Reset to device*, `disk` 153 *IO retried*).

**Fix:** power off, reseat the SATA data **and** power cables until they click. After that: 4 clean boots in a row.

**Check for it:**
```bash
sudo dmesg | grep -iE "ata[0-9].*(error|reset|failed)|i/o error"   # should print nothing
```

What did **not** fix it (so don't waste time on it next time): rebuilding the initramfs, making it smaller (`MODULES=dep`), reinstalling Ubuntu.

### If Ubuntu won't boot
- In the GRUB menu: **Advanced options → recovery mode → resume** gets to a desktop in most cases.
- Press **e** on a GRUB entry to edit its boot options for one boot (Ctrl+X to boot).
- A USB live session + `chroot` can repair an installed system.

## Apps

**Claude Desktop (Linux beta)** — official guide: <https://code.claude.com/docs/en/desktop-linux>
```bash
sudo apt install -y curl gnupg
sudo curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc https://downloads.claude.ai/claude-desktop/key.asc
gpg --show-keys /usr/share/keyrings/claude-desktop-archive-keyring.asc   # fingerprint 31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" | sudo tee /etc/apt/sources.list.d/claude-desktop.list
sudo apt update && sudo apt install -y claude-desktop
```
