Function Resolve-DNSNameCrossPlatform
{
	[CmdletBinding()]
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
	If (Get-Command 'Resolve-DnsName' -ErrorAction SilentlyContinue)
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
		Return (Resolve-DnsName @Parameters)
	}

	# If Resolve-DnsName is not available, we need to use the system's copy of
	# dig, and try to emulate the style of output that Resolve-DnsName creates.
	Else
	{
		# Build our dig command by translating Resolve-DnsName parameters
		# into dig options.
		$CommandLine = "/usr/bin/dig -t $Type $Name +short"
		If ($DnssecCd)
		{
			$CommandLine += " +cdflag"
		}
		If ($DnssecOk)
		{
			$CommandLine += " +dnssec"
		}
		If ($NoIdn)
		{
			$CommandLine += " +noidnout"
		}
		If ($NoRecursion)
		{
			$CommandLine += " +norecurse"
		}
		If ($null -ne $Server)
		{
			If ($Server.Count -gt 1)
			{
				Write-Warning "Multiple DNS servers are not yet supported.  Only the first one will be tried."
				$CommandLine += " @$($Server[0])"
			}
			Else
			{
				$CommandLine += " @$Server"
			}
		}
		If ($TcpOnly)
		{
			$CommandLine += " +tcp"
		}

		# Resolve-DnsName supports the "meta-type" A_AAAA, which returns both
		# A records and AAAA records.  dig does not support that natively, so
		# we will need to call it twice.
		If ($Type -eq "A_AAAA")
		{
			# Explicitly cast it to String[] so we add to the array properly.
			[String[]] $dnsLookup  = @()
			[String[]] $dnsLookup  = Invoke-Expression ($CommandLine -Replace $Type,"A")
			[String[]] $dnsLookup += Invoke-Expression ($CommandLine -Replace $Type,"AAAA")
		}
		# If the user specified a real RR type, then we'll just call dig
		# normally.
		Else
		{
			$dnsLookup = Invoke-Expression $CommandLine
		}

		If (-Not $dnsLookup)
		{
			Write-Debug "DNS record not found."
			Return $null
		}

		# Our result.
		$ResourceRecords = @()

		# To best mimic Resolve-DnsName, return results as custom objects with
		# the same properties.  This makes things as similar as possible.
		Switch ($Type)
		{
			"A"
			{
				$dnsLookup | ForEach-Object `
				{
					Write-Debug "$Name has the IPv4 address $_."
					$DnsRecord = [PSCustomObject]@{
						"Name" = $Name;
						"Type" = $Type;
						"Section" = "Answer";
						"IP4Address" = $_
					}

					# On Windows, Resolve-DnsName will return object(s) of type
					# Microsoft.DnsClient.Commands.DnsRecord_A.  Try to add as
					# many matching properties as we can.
					$DnsRecord `
					| Add-Member -MemberType AliasProperty -Name "Address" -Value "IP4Address" -PassThru `
					| Add-Member -MemberType AliasProperty -Name "IPAddress" -Value "IP4Address" -PassThru `
					| Add-Member -MemberType AliasProperty -Name "QueryType" -Value "Type" -PassThru `
					| Add-Member -MemberType MethodProperty -Name "GetType" -Value {$_.Type}

					# Append it to our results.
					$ResourceRecords += $DnsRecord
				}
			}

			"AAAA"
			{
				$dnsLookup | ForEach-Object `
				{
					Write-Debug "$Name has the IPv6 address $_."
					$DnsRecord = [PSCustomObject]@{
						"Name" = $Name;
						"Type" = $Type;
						"Section" = "Answer";
						"IP6Address" = $_
					}

					# On Windows, Resolve-DnsName will return object(s) of type
					# Microsoft.DnsClient.Commands.DnsRecord_AAAA.  Try to add
					# as many matching properties as we can.
					$DnsRecord `
						| Add-Member -MemberType AliasProperty -Name "Address" -Value "IP6Address" -PassThru `
						| Add-Member -MemberType AliasProperty -Name "IPAddress" -Value "IP6Address" -PassThru `
						| Add-Member -MemberType AliasProperty -Name "QueryType" -Value "Type" -PassThru `
						| Add-Member -MemberType MethodProperty -Name "GetType" -Value {$_.Type}

					# Append it to our results.
					$ResourceRecords += $DnsRecord
				}
			}

			{$_ -in @("A_AAAA", "UNKNOWN")}
			{
				$dnsLookup | ForEach-Object `
				{
					$DnsRecord = [PSCustomObject]@{
						"Name" = $Name;
						"Type" = "A";
						"Section" = "Answer";
					}
					$DnsRecord `
						| Add-Member -MemberType AliasProperty -Name "QueryType" -Value "Type" -PassThru `
						| Add-Member -MemberType MethodProperty -Name "GetType" -Value {$_.Type}

					If ($_ -Match ':')
					{
						Write-Debug "$Name has the IPv6 address $_."
						$DnsRecord.Type = "AAAA"
						$DnsRecord `
							| Add-Member -MemberType NoteProperty -Name "IP6Address" -Value $_ -PassThru `
							| Add-Member -MemberType AliasProperty -Name "IPAddress" -Value "IP6Address" -PassThru `
							| Add-Member -MemberType AliasProperty -Name "Address" -Value "IP6Address"
					}
					Else
					{
						Write-Debug "$Name has the IPv4 address $_."
						$DnsRecord `
							| Add-Member -MemberType NoteProperty -Name "IP4Address" -Value $_ -PassThru `
							| Add-Member -MemberType AliasProperty -Name "IPAddress" -Value "IP4Address" -PassThru `
							| Add-Member -MemberType AliasProperty -Name "Address" -Value "IP4Address"
					}

					# Append it to our results.
					$ResourceRecords += $DnsRecord
				}
			}

			"CNAME"
			{
				$dnsLookup | ForEach-Object `
				{
					Write-Debug "$Name has the CNAME $_"
					$DnsRecord = [PSCustomObject]@{
						"Name" = $Name;
						"Type" = $Type;
						"Section" = "Answer";
						"NameHost" = $_ -Replace "\.$"  # to emulate Resolve-DnsName
					}
					$DnsRecord `
						| Add-Member -MemberType AliasProperty -Name "Server" -Value "NameHost" -PassThru `
						| Add-Member -MemberType MethodProperty -Name "GetType" -Value {$_.Type}

					# Append it to our results.
					$ResourceRecords += $DnsRecord
				}
			}

			"MX"
			{
				$dnsLookup | ForEach-Object `
				{
					$splits = $_ -Split ' '
					Write-Debug "$Name has a mail exchanger $($splits[1]) at priority $($splits[0])."
					$DnsRecord = [PSCustomObject]@{
						"Name" = $Name;
						"Type" = $Type;
						"Section" = "Answer";
						"Preference" = $splits[0]
						"NameExchange" = $splits[1] -Replace "\.$"  # to emulate Resolve-DnsName
					}

					$DnsRecord `
						| Add-Member -MemberType AliasProperty -Name "Exchange" -Value "NameExchange" -PassThru `
						| Add-Member -MemberType MethodProperty -Name "GetType" -Value {$_.Type}

					# Append it to our results.
					$ResourceRecords += $DnsRecord
				}
			}

			"NS"
			{
				$dnsLookup | ForEach-Object `
				{
					Write-Debug "$Name has a nameserver $_"
					$DnsRecord = [PSCustomObject]@{
						"Name" = $Name;
						"Type" = $Type;
						"Section" = "Answer";
						"NameHost" = $_ -Replace "\.$"  # to emulate Resolve-DnsName
					}
					$DnsRecord `
						| Add-Member -MemberType AliasProperty -Name "Server" -Value "NameHost" -PassThru `
						| Add-Member -MemberType MethodProperty -Name "GetType" -Value {$_.Type}

					# Append it to our results.
					$ResourceRecords += $DnsRecord
				}
			}

			"SOA"
			{
				$dnsLookup | ForEach-Object `
				{
					$splits = $_ -Split ' '
					Write-Debug "$Name has an SOA record: MNAME $($splits[0]), RNAME $($splits[1]), serial $($splits[2]), refresh $($splits[3]), retry $($splits[4]), expire $($splits[5]), negative cache TTL $($splits[6])."
					$DnsRecord = [PSCustomObject]@{
						"Name"                   = $Name;
						"Type"                   = $Type;
						"Section"                = "Authority";
						"PrimaryServer"          = $splits[0] -Replace "\.$"
						"NameAdministrator"      = $splits[1] -Replace "\.$"
						"SerialNumber"           = [UInt32]$splits[2]
						"TimeToZoneRefresh"      = [UInt32]$splits[3]
						"TimeToZoneFailureRetry" = [UInt32]$splits[4]
						"TimeToExpiration"       = [UInt32]$splits[5]
						"DefaultTTL"             = [UInt32]$splits[6]
					}

					$DnsRecord `
						| Add-Member -MemberType AliasProperty -Name "Administrator" -Value "NameAdministrator" -PassThru `
						| Add-Member -MemberType MethodProperty -Name "GetType" -Value {$_.Type}

					# Append it to our results.
					$ResourceRecords += $DnsRecord
				}
			}

			"SRV"
			{
				$dnsLookup | ForEach-Object `
				{
					$splits = $_ -Split ' '
					Write-Debug "$Name is a service on $($splits[3]):$($splits[2]), priority $($splits[0]), weight $($splits[1])."
					$DnsRecord = [PSCustomObject]@{
						"Name"       = $Name;
						"Type"       = $Type;
						"Section"    = "Answer";
						"Priority"   = [UInt16]($_ -Split ' ')[0]
						"Weight"     = [UInt16]($_ -Split ' ')[1]
						"Port"       = [UInt16]($_ -Split ' ')[2]
						"NameTarget" = [String]($_ -Split ' ')[3] -Replace "\.$"  # to emulate Resolve-DnsName
					}

					$DnsRecord `
						| Add-Member -MemberType AliasProperty -Name "Target" -Value "NameTarget" -PassThru `
						| Add-Member -MemberType MethodProperty -Name "GetType" -Value {$_.Type}

					# Append it to our results.
					$ResourceRecords += $DnsRecord
				}
			}

			"TXT"
			{
				$dnsLookup | ForEach-Object `
				{
					Write-Debug "$Name has a text record: $_"
					$DnsRecord = [PSCustomObject]@{
						"Name"    = $Name;
						"Type"    = $Type;
						"Section" = "Answer";
						"Strings" = $_
					}

					$DnsRecord `
						| Add-Member -MemberType AliasProperty -Name "Text" -Value "Strings" -PassThru `
						| Add-Member -MemberType MethodProperty -Name "GetType" -Value {$_.Type}

					# Append it to our results.
					$ResourceRecords += $DnsRecord
				}
			}

			default
			{
				Write-Error "$Type records are not yet implemented."
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