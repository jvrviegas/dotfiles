# Windows VM Setup for Trading (KVM/QEMU)

Setup guide for running a Windows VM with NinjaTrader trading bot on a Linux host (CachyOS) with maximum VM performance.

## Hardware

- CPU: Intel i5-1135G7 (4 cores / 8 threads)
- RAM: 8GB (upgrade to 16GB+ recommended)
- GPU: Intel Iris Xe (integrated only)

## Resource Allocation

| Resource | Windows VM | Linux (headless) |
|---|---|---|
| RAM | 6GB (hugepages) | 2GB |
| CPU | 6 threads (pinned) | 2 threads |

## 1. Kernel Parameters (GRUB)

Add to `GRUB_CMDLINE_LINUX_DEFAULT`:

```
intel_iommu=on iommu=pt isolcpus=1-3,5-7 hugepagesz=2M hugepages=3072
```

- `isolcpus=1-3,5-7` — reserves 6 threads for the VM (leaves threads 0,4 for Linux)
- `hugepages=3072` — preallocates 6GB as 2MB hugepages

After editing `/etc/default/grub`:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo reboot
```

## 2. Install Packages

```bash
sudo pacman -S qemu-full libvirt virt-manager dnsmasq iptables-nft
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER
```

## 3. VM Configuration

Key libvirt XML settings:

```xml
<memory unit='GiB'>6</memory>
<memoryBacking>
  <hugepages/>
  <locked/>
</memoryBacking>
<vcpu placement='static'>6</vcpu>
<cputune>
  <vcpupin vcpu='0' cpuset='1'/>
  <vcpupin vcpu='1' cpuset='5'/>
  <vcpupin vcpu='2' cpuset='2'/>
  <vcpupin vcpu='3' cpuset='6'/>
  <vcpupin vcpu='4' cpuset='3'/>
  <vcpupin vcpu='5' cpuset='7'/>
</cputune>
<cpu mode='host-passthrough'>
  <topology sockets='1' cores='3' threads='2'/>
</cpu>
```

### Disk

Use a raw partition or LVM for best I/O performance:

```xml
<disk type='block' device='disk'>
  <driver name='qemu' type='raw' cache='none' io='native'/>
  <source dev='/dev/vg0/windows'/>
  <target dev='vda' bus='virtio'/>
</disk>
```

### Network

```xml
<interface type='network'>
  <source network='default'/>
  <model type='virtio'/>
</interface>
```

### Display

```xml
<graphics type='spice' autoport='yes'/>
<video>
  <model type='qxl' ram='65536' vram='65536'/>
</video>
```

## 4. Windows Optimizations

### Use Windows 10 LTSC

Lightest official Windows version. No Store, no bloatware.

### Disable unnecessary services

- Windows Defender (replace with nothing — isolated VM)
- Windows Update (set to manual only)
- Windows Search / Indexing
- Superfetch / SysMain
- Telemetry (all of it)
- Visual effects (set to "Adjust for best performance")
- Background apps

### Power plan

Set to **High Performance** in Windows power settings.

### Virtio drivers

Download and install [virtio-win drivers](https://github.com/virtio-win/virtio-win-pkg-scripts) during Windows installation for disk, network, and balloon devices.

## 5. Libvirt Hooks (Day/Night Resource Management)

Create `/etc/libvirt/hooks/qemu`:

```bash
#!/bin/bash
if [ "$1" = "windows-trading" ]; then
  if [ "$2" = "started" ]; then
    # VM started — set performance governor on VM cores
    for cpu in 1 2 3 5 6 7; do
      cpufreq-set -c $cpu -g performance
    done
  elif [ "$2" = "stopped" ]; then
    # VM stopped — release cores back to powersave
    for cpu in 1 2 3 5 6 7; do
      cpufreq-set -c $cpu -g powersave
    done
  fi
fi
```

```bash
sudo chmod +x /etc/libvirt/hooks/qemu
```

## 6. Linux Host Optimizations

Keep the host minimal during VM operation:

- No desktop environment running during the day (TTY or SSH only)
- Disable unnecessary services:

```bash
sudo systemctl disable bluetooth
sudo systemctl disable cups
```

- 2GB is enough for CachyOS base + KVM daemon

## 7. Daily Workflow

```bash
# Morning — start VM
virsh start windows-trading

# Evening — stop VM, reclaim all resources for Linux
virsh shutdown windows-trading
```

## Notes

- 6GB for Windows + NinjaTrader is functional but tight. Avoid opening anything extra in the VM.
- If RAM is upgradeable to 16GB+, allocate 10-12GB to the VM for comfortable headroom.
- No GPU passthrough possible with integrated-only graphics. SPICE/QXL is sufficient for NinjaTrader (not GPU-intensive).
