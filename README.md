# pstest

A Windows-only smoke test for running a copied PowerShell script with Chef
Client 19's `powershell_script` resource.

## What it does

1. Creates `C:\chef-pstest`.
2. Copies [files/test.ps1](files/test.ps1) to `C:\test.ps1`.
3. Executes `C:\test.ps1` using `powershell_script` on every converge, without
   guards that could hide a reproduction.
4. Runs bare `cmd /c ... | Out-File C:\temp.log`, mirroring
   `amazon-cloudwatch-agent-ctl.ps1`, to write four lines of harmless gibberish.
   `cmd` is resolved through `PATH`, so if Chef's Ruby `msys64\usr\bin\cmd`
   is found first, PowerShell fails with "Cannot run a document in the middle
   of a pipeline". The script also fails if CMD returns a nonzero exit code or
   the file contents do not match.
5. Writes `C:\chef-pstest\result.json` with a success message, computer name,
   PowerShell version, process ID, CMD exit code, `temp.log` path and line count,
   and UTC execution timestamp.
6. Streams the four `temp.log` lines, JSON, and result path to Chef's console with
   `live_stream true`. A nonzero exit status fails the Chef resource;
   `$ErrorActionPreference = 'Stop'` makes PowerShell errors terminate the script.

The script changes no system settings. It overwrites its own result file and
`C:\temp.log`; the cookbook also replaces `C:\test.ps1`, so use a test server
where those paths are not already used for another purpose. Artifacts remain
available for inspection.

## Run with Chef

Include `recipe[pstest::default]` in the Windows node's run list and make this
cookbook available to Chef. For a local-mode run, place the cookbook in a
`cookbooks\pstest` directory and run from its parent directory in an elevated shell:

```powershell
chef-client -z -o 'recipe[pstest::default]' -l info
Get-Content -LiteralPath C:\chef-pstest\result.json
Get-Content -LiteralPath C:\temp.log
```

Normal Chef output should include `pstest: cmd.exe wrote C:\temp.log`, four
`temp.log:` lines, `pstest script ran successfully`, and
`pstest: wrote C:\chef-pstest\result.json`. Use `-l debug` instead of `-l info`
when collecting a reproduction log. The timestamp is refreshed on every run,
which helps distinguish a new execution from a result left by an earlier run.

## Test Kitchen and InSpec

[kitchen.yml](kitchen.yml) targets Windows Server 2022 and Chef Client 19,
using Vagrant by default. It requires Chef Workstation, Vagrant, a compatible
virtualization provider, and any required Chef license configuration.
An existing `kitchen.local.yml` can override the driver/platforms to use Azure;
keep its credentials local and ensure it selects Chef Client 19.

From this cookbook directory:

```shell
kitchen list
kitchen converge
kitchen verify
```

The [InSpec profile](test/integration/default) verifies that the script was copied,
`C:\temp.log` contains the exact four expected lines, and its JSON result contains
the expected message and execution details. Verification
only reads artifacts; it does not rerun the script. A saved result proves a previous
successful execution, not necessarily the most recent attempted converge; always
check the converge exit status and result timestamp when troubleshooting.

To run the profile directly on a Windows server with InSpec installed:

```powershell
inspec exec test/integration/default
```
