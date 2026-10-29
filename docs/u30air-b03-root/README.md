# ZTE U30 Air B03: one verified Magisk root experiment

This is an independent field report added by this fork. It is not an upstream project feature, a supported installer, or a general guide for all F50/U30 firmware. The upstream project requires an already-rooted device and explicitly does not provide rooting or unlocking support.

**Risk: this procedure writes the active boot chain. A mistake, unsupported firmware, power loss, signature mismatch, or rejected restoration can permanently prevent boot. Recovery on the active slot was prepared but never tested after a failed boot. Backups alone do not prove recoverability. Do not use this report as an unattended flasher.**

## Result and scope

One U30 Air, software `U30Air_XCBZV1.0.0B03`, Android 13, kernel `5.4.254-android12-9-g9444efdc6885`, stock A/B boot images with Android boot header v4, active slot `a`, bootloader reported locked, verified-boot property reported green. This is a single-device result, not proof the bootloader is unlocked or that a green property means the modified chain is securely verified.

Magisk 31.1 booted after device-derived patched `trustos_a` and `boot_a` were written through BROM/FDL2. Both were read back and matched the intended bytes. The Magisk manager performed additional setup and rebooted; its daemon was running. A local one-purpose Magisk module registered `uid=2000` policy `2` so the Android ADB shell could obtain root. The exact verification was:

```text
adb shell /debug_ramdisk/su -c id
uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0
```

`/debug_ramdisk` is device-specific; query `adb shell /debug_ramdisk/magisk --path` when applicable. `getenforce` returned **Permissive**. That is a material reduction in security; no claim is made that this method preserves SELinux enforcement. USB-debugging authorization and ADB-shell root should be protected: the policy has no expiry. Revoke it when finished in Magisk or via its SQLite policy interface. The bootloader remained reported locked.

## Device and firmware compatibility

The only **verified success in this fork** is the single U30 Air B03 unit described above. A similar product name or SoC is not proof that this exact TrustOS patch, FDL, partition layout, signing chain or recovery method will work. No probability of success has been measured for other devices.

| Device and software | Evidence | Status for this B03-derived procedure |
| --- | --- | --- |
| ZTE U30 Air, `U30Air_XCBZV1.0.0B03` | One device in this report booted Magisk and returned `uid=0` to ADB. | Verified on one unit only; not independently replicated. |
| Other ZTE U30 Air units with the exact same B03 build | Same model and build are the closest candidate; matching actual boot chain, partition layout, FDL acceptance and recovery are still required. | Plausible candidate, **untested**. Even identical display IDs need not guarantee identical hardware or signing configuration. |
| ZTE F50 / MU300 or U30 Air, B16 | The [F50 B16 project](https://github.com/Xio-Shark/f50-b16) describes a separate B16-only root package for these models. Our B03 candidate's modified payload matched its published B16 reference. | Related research, **not a test of this B03 procedure on B16**. Follow version-specific evidence and never flash its B16 boot image on B03. |
| ZTE F50 / MU300, B09 | A [separate F50 B09 toolkit](https://github.com/dikeckaan/zte-f50-toolkit) describes B09-specific TrustOS and boot images. | Related method, **not evidence of compatibility** with this B03 procedure. Its downgrade flow can erase user data. |
| Other U30 Air revisions (including B33), regional variants, and other firmware on F50 / MU300 | Upstream describes U30 Air and F50 as sharing a board/chip, but boot chains and protections can differ. A [U30 Air B33 report](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/issues/340) documents rejection of modified U-Boot, not this TrustOS test. | **Unknown; do not assume compatibility.** B33's U-Boot rejection cannot by itself establish whether this TrustOS approach works or fails. |
| U30 Pro, U50, MU5001/MU5002 and other routers | No device-specific evidence for this exact workflow was established here. | **Not assessed; no compatibility claim.** |

Before treating an untested unit as a candidate, independently verify its exact firmware, hardware, boot-chain backups, relevant hashes and instruction/layout checks, FDL behavior, active slot and a device-specific recovery path. The offline builder's acceptance is only one check; it does not establish successful boot or safe recovery. Do not share NV, serial numbers, or private partition dumps when asking others for help.

## Before starting: preserve and verify your own device

* Record the exact `ro.build.display.id`, kernel, boot slot, `ro.boot.flash.locked`, verified boot state, Android version, partition layout and hardware. Do not use our offsets or images on a different layout. Check permissions and license terms for every third-party tool and binary.
* Back up **your own** boot chain (`splloader`, both slots of `uboot`, `sml`, `trustos`, `teecfg`, `vbmeta`, `boot`, `vendor_boot`, `init_boot`, `dtbo`), `misc`, modem/NV and all other data you need. Our 19 boot-chain images were independently read in two BROM sessions and matched byte-for-byte. GPT header/table CRCs and raw offsets were checked. We also read the important raw NV partitions twice; some named NV1 reads were inconsistent and must not be treated as valid backups. A tested restore of NV or the active boot chain was **not** achieved.
* Keep all original and patched files private and intact; use `umask 077`, unique directories, hashes and off-device copies. Never publish backups, logs, serial numbers, IMEI or calibration data. Confirm your backup size and log completion for every partition; a process exit code alone is insufficient.
* Establish BROM access and have a recovery plan before writing. FDL images must be compatible with the exact target. Successful reads do not imply writes or recovery will work. Our working Mac setup used a locally compiled modified `spd_dump` and device-compatible `fdl1-dl.bin`, `fdl2-dl.bin` and `custom_exec_no_verify_65012f48.bin`; those proprietary/vendor components and the modified binary are **not** distributed here. The generic raw-reading source was modified to avoid NV1-to-NV2 substitution and add a guarded raw read. Do not assume a different `spd_dump` behaves identically.

## What was done

### 1. Back up and prepare a patched boot

A stock `boot_a` from the target was read twice and checked. On the device, the official Magisk 31.1 boot patcher was run against that image with `BOOTMODE=true`, `KEEPVERITY=true`, `KEEPFORCEENCRYPT=true`, and `PATCHVBMETAFLAG=false`. The resulting image was 64 MiB, its kernel matched the stock kernel bytes, and Magisk's ramdisk test identified a patch. It was derived from this device, not a downloaded boot for another model. Install the official Magisk APK only from [the official project](https://topjohnwu.github.io/Magisk/install.html) and follow its boot patch instructions; patching itself is not evidence that a locked device will boot the result.

`fastboot boot` returned OKAY but no root was observed afterward, so we do not claim the modified image actually executed. `fastboot flash boot_b` sent the file but failed at the write step with `Flashing Lock Flag is locked`; a subsequent full read of `boot_b` matched stock.

### 2. Prepare the experimental TrustOS image offline

The B16 research approach was assessed on the B03 device's own stock TrustOS and SML. The included Python scripts require `cryptography` and were used in our experiment; the builder writes a **new** file and refuses to overwrite an existing path:

```sh
python3 -m venv .venv-b03
. .venv-b03/bin/activate
python -m pip install cryptography
python docs/u30air-b03-root/prepare-f50-trustos.py \
  /private/backups/trustos_a.bin /private/backups/sml_a.bin \
  /private/work/trustos-b03-experimental.bin
```

The builder checks exact image structure, source instructions at offsets `0x758e8` and `0x774d4`, sizes and embedded RSA-PSS signatures, then patches two instructions and retains the original SML signature. A successful result verifies internal packaging and signatures against keys carried inside the images; it does **not** prove device root-of-trust acceptance, correctness of patch semantics, secure boot status or cross-device compatibility. The candidate for this B03 device matched the B16 reference payload. Never substitute a whole B16/B09 TrustOS or boot image for the target's own backup. The two scripts are derived from our offline analysis of the published [F50 B16 research](https://github.com/Xio-Shark/f50-b16) and [DashPlay preparation logic](https://github.com/yizhixiaoheigou/DashPlay/blob/main/scripts/prepare-f50-trustos.py).

### 3. BROM write/readback trial and recovery evidence

The tested Mac download-mode invocation used `--wait 900 --verbose 1 --kickto 2`, `exec_addr 0x65012f48`, `fdl fdl1-dl.bin 0x65000800`, `fdl fdl2-dl.bin 0xb4fffe00`, and `exec`. For each connection the powered-off hotspot was connected directly over USB while holding power for approximately five seconds; connection was sometimes unreliable. These settings and the FDLs are observations, not a verified universal recipe. Using an incompatible FDL, tool or address can brick a device.

The experimental `trustos_b` and Magisk-patched `boot_b` were written individually and read back in full. Our tool logged `Write Part Done` and `Read Part Done`; byte-for-byte hashes matched their respective intended files. To boot slot `b`, a full 1 MiB `misc` backup was taken, the 32-byte boot-control record at offset `0x800` was validated by CRC, and the tool's `set_active b` wrote back the entire `misc` partition. The resulting full readback showed differences only within that record and a valid CRC. Do not assume another tool preserves the rest of `misc`.

The device attempted `b` but fell back to `a`: saved pstore showed `system_b` had zero extents and first-stage init failed to mount it. `lpdump --all` showed other `_b` logical partitions also had no extents. The device reports Virtual A/B metadata; manually switching a boot slot is not an OTA update and does not create an OTA snapshot. We did not change `super`.

The original stock `trustos_b` and `boot_b` were then restored from the verified backups, read in full again and matched. **This demonstrates restoration of the inactive slot on this device only. It does not demonstrate recovery of the active boot chain after a brick.**

For reproducibility, the following shows the **observed command structure**, not a copy-and-run installer. Run from a private working directory containing the three device-compatible FDL/exec files, the audited `spd_dump`, and the named images. Ensure the currently running slot and all files are independently verified immediately before use. `read_part` sizes below are specific to our device. The utility may return success even after a protocol error: inspect the complete log and compare full readbacks. Never select `a` or write active partitions based on this example without understanding the risk.

```sh
# Format used for writing the experimental images to the then-inactive b slot:
spd_dump --wait 900 --verbose 1 --kickto 2 \
  exec_addr 0x65012f48 fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0xb4fffe00 exec \
  write_part trustos_b /private/work/trustos-b03-experimental.bin \
  write_part boot_b /private/work/magisk-patched-boot.img \
  path /private/readback \
  read_part trustos_b 0 6291456 trustos_b.bin \
  read_part boot_b 0 67108864 boot_b.bin reset
# Compare the full readback files to the images, for example with shasum -a 256.
```

The active-slot write used the same structure with `trustos_a` and `boot_a`. Inactive-slot restore used the same exact partition names, but wrote this unit's original `trustos_b.bin` and `boot_b.bin` backup files. For active-slot recovery we prepared the equivalent write of the device's original `trustos_a` and `boot_a`; **we did not execute that recovery**, so BROM availability or restore success after a real failure is unknown. `set_active b` is deliberately not supplied as an automated step: the utility used here rewrites the full `misc`, and the `b` boot failed on this device.

### 4. Active-slot experiment and verification

With `a` booting normally, the patched TrustOS and patched boot were written to `trustos_a` and `boot_a` through the same download-mode tool, then fully read back and compared to the candidate files. The device booted Android on `a`, reported green and locked, and Magisk's daemon started. The corresponding stock `trustos_a` and `boot_a` were kept and a BROM recovery script prepared. No active-slot failure or restoration was tested. Successful readback proves bytes written, not successful boot; successful boot proves this one device worked, not that recovery or other firmware will work.

The Magisk app requested its additional setup and reboot. Because this firmware lacked a standard document picker and the ADB shell policy was denied, a temporary local picker delivered a one-purpose Magisk module to the manager. Its source is in [adb-shell-policy](adb-shell-policy/): at install it grants only UID 2000 using `magisk --sqlite`. It changes persistent security policy and should be used only by the device owner who explicitly wants ADB root. Magisk 31.1's default for an unregistered policy is deny; `policy=2` is allow. The temporary picker was uninstalled afterward. The daemon rejects unrelated copies of the Magisk binary, so use the daemon's own applet, not a copied executable.

The included module source is an experiment, not a signed release. To prepare the zip, put `module.prop` and `customize.sh` at the zip root, inspect the contents and install through the official Magisk app. Different ROMs may require a document picker. The module grants ADB shell root permanently until revoked; it does not give every Android app root. To verify and later remove the policy after obtaining root:

```sh
adb shell /debug_ramdisk/su -c id
adb shell /debug_ramdisk/su -c '/debug_ramdisk/magisk --sqlite "SELECT uid,policy,until FROM policies WHERE uid=2000;"'
adb shell /debug_ramdisk/su -c '/debug_ramdisk/magisk --sqlite "DELETE FROM policies WHERE uid=2000;"'
```

After revocation the shell may lose access immediately. Do not enable blanket root grants or publish a module that installs silently. Treat Magisk modules from others as arbitrary root code.

## Outstanding limitations and OTA

* One physical unit, one firmware build and one Mac workflow; no independent reproduction or validated cross-version support.
* Active-slot restoration, NV restoration, an actual OTA update, and behavior after a boot-chain failure remain untested. Do not infer them from inactive-slot readback.
* `verifiedbootstate=green` and `flash.locked=1` were observed properties, not a cryptographic attestation. The TrustOS modification changes the trust chain.
* An OTA can overwrite a patched boot chain or modify slots and dynamic partitions. Follow the official [Magisk OTA guidance](https://topjohnwu.github.io/Magisk/ota.html); this specific modified TrustOS configuration has not been validated with OTA. Preserve your verified backups and plan recovery before updates.
* [Upstream MU300 Linux](https://github.com/dikeckaan/mu300-linux) requires root before installation. Linux installation is a separate operation with its own backups and instructions.
