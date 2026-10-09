# Snapshot verification

The `rpm-nobara44-20261008` snapshot was built and installed natively in a
Nobara 44 GNOME x86_64 VM on 2026-10-08. Kernel:
`7.2.0-202.nobara.fc44.x86_64`.

- 89 installed binary RPMs and four source RPMs.
- 325 native Meson tests passed, with zero failures, timeouts or skips.
- 18 additional Write accessibility checks passed.
- 57 visible application launchers mapped the exact application IDs, rendered
  their windows and received focus.
- Write saved a DOCX through the installed portal and reopened its verified text.
- A real libsecret client stored, read and deleted a credential after native
  keyring authentication. An incorrect passphrase left the keyring locked.
- UEFI reboot returned to GDM; Singularity login and four postboot application
  checks passed.
- All 2,620 delivered regular file hashes/modes and symlink targets matched the
  installed payload. RPM verification was clean. All 237 installed ELF files
  resolved their dependencies.
- The private compositor/input library, Singularity portal, PipeWire and
  WirePlumber were active, with no failed system or user units.

The full Meson suite ran before final repackaging. All 334 previously checked
programs/scripts retained their hashes. The changed keyring had additional real
GTK/D-Bus/libsecret regression checks, including an ordinary-user run. The source
spec retains the complete default `%check` procedure.

Window coverage proves launch, rendering and focus. Physical cameras, fingerprint
readers and scanners, external account authorization, and all individual app
features were not exercised. Three NoDisplay helpers were excluded from the
visible launcher sweep. Gesture runtime/model hashes were verified; the VM had
no physical gesture camera.
