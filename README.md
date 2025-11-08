# ssi-bash-assessment
Repository for the technical assessment of the Automation Engineer application process at SSI.
Includes bash scripts automating hardware resource checkups.

## Development Environment
- VM: Oracle Virtual Box
- Host OS: Windows 11
- Guest OS: CentOS Stream 10

## Dependencies/Submodules
- bats (for unit testing)
- epel-release (repo for installing msmtp on CentOS)
- mailx/s-nail (for email formatting)
- msmtp (for email sending)

## Current Limitations
- Non-compatible with non-gmail accounts
- Thresholds are non-negative whole numbers only
