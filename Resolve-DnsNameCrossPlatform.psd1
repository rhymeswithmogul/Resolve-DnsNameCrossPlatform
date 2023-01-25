#
# Module manifest for module 'Resolve-DnsNameCrossPlatform'
#
# Generated by: Colin Cogle
#
# Generated on: 4/7/2020
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'src/Resolve-DnsNameCrossPlatform.psm1'

# Version number of this module.
ModuleVersion = '1.0.0'

# Supported PSEditions.
CompatiblePSEditions = @("Core", "Desktop")

# ID used to uniquely identify this module.
GUID = '20218a91-1eb1-4952-952d-b8f3398ea621'

# Author of this module.
Author = 'Colin Cogle'

# Copyright statement for this module.
Copyright = '(c) 2020, 2023 Colin Cogle. All rights reserved.'

# Description of the functionality provided by this module.
Description = 'A cross-platform implementation of the Resolve-DnsName cmdlet.'

# Minimum version of the PowerShell engine required by this module.
# (This is only set to version 5.1 to support marking this as Core-compatible.)
PowerShellVersion = '5.1'

# Script files (.ps1) that are run in the caller's environment prior to
# importing this module.
# ScriptsToProcess = @()

# Functions to export from this module; for best performance, do not use
# wildcards and do not delete the entry, and use an empty array if there
# are no functions to export.
FunctionsToExport = @("Resolve-DnsNameCrossPlatform")

# Cmdlets to export from this module; for best performance, do not use
# wildcards and do not delete the entry, and use an empty array if there
# are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = ''

# Aliases to export from this module; for best performance, do not use
# wildcards and do not delete the entry, and use an empty array if there
# are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
DscResourcesToExport = @()

# List of all modules packaged with this module
ModuleList = @()

# List of all files packaged with this module
FileList = @(
    "AUTHORS",
    "CODE_OF_CONDUCT.md",
    "CONTRIBUTING.md",
    "LICENSE",
    'README.md',
    "Resolve-DnsNameCrossPlatform.psd1",
    "src/Resolve-DnsNameCrossPlatform.psm1"
)

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @("dig", "DNS", "nslookup", "DnsClient")

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/rhymeswithmogul/Resolve-DnsNameCrossPlatform/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rhymeswithmogul/Resolve-DnsNameCrossPlatform'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'Linux users should install the bind-utils package, so that the dig (domain information grouper) command is available.  dig is available on macOS since at least High Sierra.'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        RequireLicenseAcceptance = $false

        # External dependent modules of this module
        ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

