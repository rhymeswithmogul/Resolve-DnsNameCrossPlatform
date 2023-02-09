#Requires -Version 5.0

Function Resolve-DnsNameCrossPlatform
{
	[CmdletBinding()]
	[OutputType([DnsRecord_Base[]])]
	[Alias('Resolve-DnsName')]
	Param(
		[Parameter(Mandatory=$true, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias('InputObject', 'DomainName')]
		[String] $Name,

		[Switch] $DnsOnly,

		[Switch] $DnssecCd,

		[Switch] $DnssecOk,

		[Switch] $NoIdn,

		[Switch] $NoRecursion,

		[String[]] $Server,

		[Switch] $TcpOnly,

		[Parameter(Position=1)]
		[ValidateSet("UNKNOWN", "A_AAAA", "A", "AAAA", "CNAME", "MX", "NS", "SOA", "SRV", "TXT")]
		[String] $Type = "A_AAAA"
	)

	Write-Verbose "Performing a DNS lookup for $Name ($Type)."

	# Check and see if the Resolve-DnsName cmdlet is available.  If so, just
	# pass all of our parameters to it.
	#
	# It and the DnsClient module has been available since PowerShell 3.0,
	# but only when running on Windows 8/Windows Server 2012 or newer.
	If (Get-Command -Module 'DnsClient' -Name 'Resolve-DnsName' -ErrorAction SilentlyContinue)
	{
		$Parameters = @{
			"Debug" = $DebugPreference;
			"DnssecCd" = $DnssecCd;
			"DnssecOk" = $DnssecOk;
			"ErrorAction" = $ErrorActionPreference;
			"Name" = $Name;
			"NoIdn" = $NoIdn;
			"NoRecursion" = $NoRecursion;
			"Server" = $Server;
			"TcpOnly" = $TcpOnly;
			"Type" = $Type;
			"Verbose" = $VerbosePreference
		}
		Return (DnsClient\Resolve-DnsName @Parameters)
	}

	# If Resolve-DnsName is not available, we need to use the system's copy of
	# dig, and try to emulate the style of output that Resolve-DnsName creates.
	Else
	{
		# Find dig.  By default, we will use /usr/bin/dig.
		$DigApp = (Get-Command 'dig' -ErrorAction Stop).Source

		# Build our dig command by translating Resolve-DnsName parameters
		# into dig options.
		$CommandLine = [String[]]@()
		If ($null -ne $Server)
		{
			If ($Server.Count -gt 1)
			{
				Write-Warning "Multiple DNS servers are not yet supported.  Only the first one will be tried."
				$CommandLine += "@$($Server[0])"
			}
			Else
			{
				$CommandLine += "@$Server"
			}
		}

		$CommandLine += $Name
		$CommandLine += $Type
		$CommandLine += '-r'		# don't read ~/.digrc
		$CommandLine += '+noall'	# don't show anything...
		$CommandLine += '+answer'	# ...but do show answer lines
		
		If ($DnssecCd)
		{
			$CommandLine += "+cdflag"
		}
		If ($DnssecOk)
		{
			$CommandLine += "+dnssec"
		}
		If ($NoIdn)
		{
			$CommandLine += "+noidnout"
		}
		If ($NoRecursion)
		{
			$CommandLine += "+norecurse"
		}
		If ($TcpOnly)
		{
			$CommandLine += "+tcp"
		}


		# Resolve-DnsName supports the "meta-type" A_AAAA, which returns both
		# A records and AAAA records.  dig does not support that natively, so
		# we will need to call it twice.
		If ($Type -eq "A_AAAA")
		{
			# Explicitly cast it to String[] so we add to the array properly.
			[String[]] $dnsLookup  = @()

			$ALookup = $CommandLine -Replace $Type,'A'
			[String[]] $dnsLookup += (Invoke-Dig $ALookup -DigPath $DigApp)

			$AAAALookup = $CommandLine -Replace $Type,'AAAA'
			[String[]] $dnsLookup += (Invoke-Dig $AAAALookup -DigPath $DigApp)
		}
		# If the user specified a real RR type, then we'll just call dig
		# normally.
		Else
		{
			$dnsLookup = (Invoke-Dig $CommandLine -DigPath $DigApp)
		}

		If (-Not $dnsLookup)
		{
			Write-Debug "DNS record not found."
			Return $null
		}

		# Our result.
		$ResourceRecords = [DnsRecord_Base[]]@()

		# To best mimic Resolve-DnsName, return results as custom objects with
		# the same properties.  This makes things as similar as possible.
		$dnsLookup | ForEach-Object {
			$DigOutputLine = $_
			Write-Debug "DIG output line: $DigOutputLine"

			# The DNS record type will be the fourth token:
			# e.g., "example.com. 3600 IN AAAA 2001:db8::1"
			#                             ^^^^
			$RRType = ($_ -Split "\s+",5)[3]
			Switch ($RRType)
			{
				"A"
				{
					$DnsRecord = [DnsRecord_A]::new($Name)
					Set-InstanceProperties $DnsRecord -DigOutputLine $DigOutputLine
					Write-Debug "$Name has the IPv4 address $($DnsRecord.IPAddress)."
					$ResourceRecords += $DnsRecord
				}

				"AAAA"
				{
					$DnsRecord = [DnsRecord_AAAA]::new($Name)
					Set-InstanceProperties $DnsRecord -DigOutputLine $DigOutputLine
					Write-Debug "$Name has the IPv6 address $($DnsRecord.IPAddress)."
					$ResourceRecords += $DnsRecord
				}

				{$_ -in @("A_AAAA", "UNKNOWN")}
				{
					If ($_ -Match "\bAAAA\b")
					{
						$DnsRecord = [DnsRecord_AAAA]::new()
						Set-InstanceProperties $DnsRecord -DigOutputLine $DigOutputLine
						Write-Debug "$Name has the IPv6 address $($DnsRecord.IPAddress)."
					}
					Else
					{
						$DnsRecord = [DnsRecord_A]::new()
						Set-InstanceProperties $DnsRecord -DigOutputLine $DigOutputLine
						Write-Debug "$Name has the IPv4 address $($DnsRecord.IPAddress)."
					}

					# Append it to our results.
					$ResourceRecords += $DnsRecord
				}

				"CNAME"
				{
					$DnsRecord = [DnsRecord_CNAME]::new()
					Set-InstanceProperties $DnsRecord -DigOutputLine $DigOutputLine
					Write-Debug "$Name is an alias for $($DnsRecord.NameHost)."
					$ResourceRecords += $DnsRecord
				}

				"MX"
				{
					$DnsRecord = [DnsRecord_MX]::new()
					Set-InstanceProperties $DnsRecord -DigOutputLine $DigOutputLine
					Write-Debug "$Name has a mail exchanger $($DnsRecord.NameExchange) at priority $($DnsRecord.Preference)."
					$ResourceRecords += $DnsRecord
				}

				"NS"
				{
					$DnsRecord = [DnsRecord_NS]::new()
					Set-InstanceProperties $DnsRecord -DigOutputLine $DigOutputLine
					Write-Debug "$Name has the nameserver $($DnsRecord.NameHost)."
					$ResourceRecords += $DnsRecord
				}

				'RRSIG'
				{
					$DnsRecord = [DnsRecord_RRSIG]::new()
					Set-InstanceProperties $DnsRecord -DigOutputLine $DigOutputLine
					Write-Debug "$Name has RRSIG data: $($DnsRecord.Signature)"
					$ResourceRecords += $DnsRecord
				}

				"SOA"
				{
					$DnsRecord = [DnsRecord_SOA]::new()
					Set-InstanceProperties $DnsRecord -DigOutputLine $DigOutputLine
					Write-Debug "$Name has an SOA record: MNAME $($DnsRecord.PrimaryServer), RNAME $($DnsRecord.NameAdministrator), serial $($DnsRecord.SerialNumber), refresh $($DnsRecord.TimeToZoneRefresh), retry $($DnsRecord.TimeToZoneFailureRetry)), expire $($DnsRecord.TimeToExpiration), default TTL $($DnsRecord.DefaultTTL)."
					$ResourceRecords += $DnsRecord
				}

				"SRV"
				{
					$DnsRecord = [DnsRecord_SRV]::new()
					Set-InstanceProperties $DnsRecord -DigOutputLine $DigOutputLine
					If ($DnsRecord.NameTarget = '.') {
						Write-Debug "$Name is a service that does not exist."
					}
					Else {
						Write-Debug "$Name is a service on $($DnsRecord.NameTarget):$($DnsRecord.Port), priority $($DnsRecord.Priority), weight $($DnsRecord.Weight)."
					}
					$ResourceRecords += $DnsRecord
				}

				"TXT"
				{
					$DnsRecord = [DnsRecord_TXT]::new()
					Set-InstanceProperties $DnsRecord -DigOutputLine ($DigOutputLine -Replace '" "','')
					Write-Debug "$Name has text data: $($DnsRecord.Strings)"
					$ResourceRecords += $DnsRecord
				}

				default
				{
					Write-Error "$RRType records are not yet implemented."
				}
			}
		}
	}

	# We're sorting by preference or priority/weight, to make our MX and SRV
	# records appear in "order."
	If ($Type -eq "SRV")
	{
		Return $ResourceRecords | Sort-Object -Property Priority,Weight
	}
	ElseIf ($Type -eq "MX")
	{
		Return $ResourceRecords | Sort-Object -Property Preference
	}
	Else
	{
		Return $ResourceRecords
	}
}

Function Invoke-Dig {
	[CmdletBinding()]
	[OutputType([String[]])]
	Param(
		[Parameter(Mandatory, Position=0)]
		[ValidateNotNullOrEmpty()]
		[String[]] $ArgumentList,

		[ValidateNotNullOrEmpty()]
		[Alias('DigPath')]
		[String] $FilePath = '/usr/bin/dig'
	)

	Write-Debug "Running command: $FilePath $($ArgumentList -Join ' ')"
	$DigOutput = (Invoke-Command -ScriptBlock {. $FilePath $ArgumentList}) -Split "[\r\n]+"

	Write-Debug "Results: $DigOutput"
	Return $DigOutput
}

Function Set-InstanceProperties {
	[CmdletBinding()]
	[OutputType([Void])]
	Param(
		[Parameter(Mandatory)]
		[DnsRecord_Base]
		[ref]$InputObject,

		[ValidateNotNullOrEmpty()]
		[String] $DigOutputLine
	)

	$Tokens = $DigOutputLine -Split "\s+",5
	Write-Debug "Tokens: $($Tokens -Join ',')"

	$InputObject.Name  = $Tokens[0]
	$InputObject.TTL   = $Tokens[1]
	$InputObject.Class = $Tokens[2]
	$InputObject.Type  = $Tokens[3]
	$InputObject.SetData($Tokens[4])
}