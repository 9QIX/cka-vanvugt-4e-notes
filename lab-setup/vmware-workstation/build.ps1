<#
.SYNOPSIS
  Build the three CKA lab VMs (cp1, w1, w2) in VMware Workstation on Windows from the
  official Ubuntu 24.04 cloud image. Kubernetes is NOT installed: that is lab 01.

.EXAMPLE
  python make_seeds.py --out D:\VMs\_work\_seeds --subnet 192.168.178
  .\build.ps1 -Work D:\VMs\_work -VmRoot D:\VMs\cka

.NOTES
  Hard-won rules (each one cost a failed run):
   * Put the VMs on an INTERNAL drive. A USB drive can drop mid-import and ovftool then
     reports confusing "failed to read" errors.
   * Keep the downloaded OVA and the seed ISOs OUTSIDE $VmRoot. ovftool deletes its target
     directory tree when an import fails.
   * No trailing backslash on the ovftool target path.
   * Do not pass --diskMode to ovftool for a Workstation target.
   * Do not delete the seed ISOs: each .vmx points at them.
   * Check your NAT subnet first (Virtual Network Editor, VMnet8) and use it in make_seeds.py.
#>
param(
  [Parameter(Mandatory)] [string]$Work,      # holds the OVA and the _seeds folder
  [Parameter(Mandatory)] [string]$VmRoot,    # where the VMs are created
  [string]$VmwareDir = 'C:\Program Files\VMware\VMware Workstation',
  [int]$DiskGB = 30
)
$ErrorActionPreference = 'Stop'

$ova    = Join-Path $Work 'noble-server-cloudimg-amd64.ova'
$seeds  = Join-Path $Work '_seeds'
$ovf    = Join-Path $VmwareDir 'OVFTool\ovftool.exe'
$vmrun  = Join-Path $VmwareDir 'vmrun.exe'
$vdisk  = Join-Path $VmwareDir 'vmware-vdiskmanager.exe'
$memMB  = @{ cp1 = 3072; w1 = 2048; w2 = 2048 }

if ($VmRoot.StartsWith($Work, 'OrdinalIgnoreCase') -or $Work.StartsWith($VmRoot, 'OrdinalIgnoreCase')) {
  throw "Work and VmRoot must be separate, non-nested folders."
}
foreach ($n in $memMB.Keys) { if (-not (Test-Path (Join-Path $seeds "$n-seed.iso"))) { throw "Missing $seeds\$n-seed.iso (run make_seeds.py first)" } }

# 1. Download and verify the image
$base = 'https://cloud-images.ubuntu.com/noble/current'
if (-not (Test-Path $ova)) { curl.exe -fsSL -o $ova "$base/noble-server-cloudimg-amd64.ova" }
$want = ((curl.exe -fsSL "$base/SHA256SUMS") | Select-String 'noble-server-cloudimg-amd64.ova$').Line.Split(' ')[0].ToLower()
$have = (Get-FileHash $ova -Algorithm SHA256).Hash.ToLower()
if ($want -ne $have) { throw "Checksum mismatch for $ova (the image changes occasionally: delete it and re-run)." }

# 2. Import, size, attach the seed ISO, grow the disk
New-Item -ItemType Directory -Force $VmRoot | Out-Null
foreach ($n in $memMB.Keys) {
  & $ovf --acceptAllEulas --name=$n --net:"VM Network"=nat $ova $VmRoot
  if ($LASTEXITCODE -ne 0) { throw "ovftool failed for $n" }

  $vmx = Join-Path $VmRoot "$n\$n.vmx"
  $set = @{ 'memsize' = "$($memMB[$n])"; 'numvcpus' = '2'
            'ide1:0.deviceType' = 'cdrom-image'; 'ide1:0.fileName' = (Join-Path $seeds "$n-seed.iso"); 'ide1:0.startConnected' = 'TRUE' }
  $out = foreach ($l in Get-Content $vmx) {
    $k = ($l -split '\s*=\s*', 2)[0]
    if ($set.ContainsKey($k)) { $v = $set[$k]; $set.Remove($k); "$k = `"$v`"" } else { $l }
  }
  foreach ($k in $set.Keys) { $out += "$k = `"$($set[$k])`"" }
  [IO.File]::WriteAllLines($vmx, $out, (New-Object Text.UTF8Encoding($false)))

  & $vdisk -x "${DiskGB}GB" (Join-Path $VmRoot "$n\$n-disk1.vmdk") | Out-Null   # cloud-init grows the partition on first boot
}

# 3. Boot all three, then snapshot the clean OS once SSH answers
foreach ($n in $memMB.Keys) { & $vmrun -T ws start (Join-Path $VmRoot "$n\$n.vmx") nogui }
Write-Host "VMs started. Wait for SSH (about 2 minutes), check with 'ssh <node> hostname', then:"
Write-Host "  vmrun -T ws snapshot <path-to>\<node>.vmx base-os     (for each node; takes a few minutes while running)"
