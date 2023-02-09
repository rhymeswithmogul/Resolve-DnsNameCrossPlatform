#Requires -Version 5.0

Class DnsRecord_Base {
	[ValidateSet('Question','Answer','Authority')]
	[String] $Section = 'Answer'

	[ValidateNotNullOrEmpty()]
	[String] $Name

	[ValidateRange(0, 2147483647)]
	[UInt32] $TTL = 0	

	[ValidateSet('IN', 'CH')]
	[String] $Class = 'IN'

	[Alias('QueryType')]
	[String] $Type = 'ANY'

	[Void] SetData([String] $Data) {}

	[String] ToString() {
		Return "$($this.Name) $($this.TTL) $($this.Class) $($this.Type)"
	}
	[String] ToString([String] $data) {
		Return "$($this.ToString()) $data"
	}
}

Class DnsRecord_A : DnsRecord_Base {
	[Alias('IP4Address')]
	[Net.IPAddress] $IPAddress

	[Void] SetData([String] $Data) {
		$this.IPAddress = [Net.IPAddress]::Parse($Data)
	}

	[String] ToString() {
		Return ([DnsRecord_Base]$this).ToString($this.IPAddress)
	}
}

Class DnsRecord_AAAA : DnsRecord_Base {
	[Alias('IP6Address')]
	[Net.IPAddress] $IPAddress

	[Void] SetData([String] $Data) {
		$this.IPAddress = [Net.IPAddress]::Parse($Data)
	}

	[String] ToString() {
		Return ([DnsRecord_Base]$this).ToString($this.IPAddress)
	}
}

Class DnsRecord_CNAME : DnsRecord_Base {
	[Alias('Server')]
	[String] $NameHost

	[Void] SetData([String] $Data) {
		$this.NameHost = $Data
	}

	[String] ToString() {
		Return ([DnsRecord_Base]$this).ToString($this.NameHost)
	}
}

Class DnsRecord_MX : DnsRecord_Base {
	[Alias('Exchange')]
	[String] $NameExchange

	[Alias('Priority')]
	[UInt16] $Preference = 0


	[Void] SetData([String] $Data) {
		$this.Preference, $this.NameExchange = $Data -Split "\s+",2
	}

	[String] ToString() {
		Return ([DnsRecord_Base]$this).ToString($this.Preference + ' ' + $this.NameExchange)
	}
}

Class DnsRecord_NS : DnsRecord_Base {
	[Alias('Server', 'NameServer')]
	[String] $NameHost


	[Void] SetData([String] $Data) {
		$this.NameHost = $Data
	}

	[String] ToString() {
		Return ([DnsRecord_Base]$this).ToString($this.NameHost)
	}
}

Class DnsRecord_RRSIG : DnsRecord_Base {
	[String] $Signature
	[PSCustomObject] $SignatureData

	static [PSObject] ToTimestamp([String] $InputDate) {
		Try {
			$DateData = @{
				'AsUTC'  = $true
				'Year'   = [Int32]($InputDate.Substring( 0,4))
				'Month'  = [Int32]($InputDate.Substring( 4,2))
				'Day'    = [Int32]($InputDate.Substring( 6,2))
				'Hour'   = [Int32]($InputDate.Substring( 8,2))
				'Minute' = [Int32]($InputDate.Substring(10,2))
				'Second' = [Int32]($InputDate.Substring(12,2))
			}
			Return (Get-Date @DateData)
		}
		Catch {
			Return $InputDate
		}
	}

	[Void] SetData([String] $Data) {
		$Tokens = $Data -Split "\s+",8
		$Expires = [DnsRecord_RRSIG]::ToTimestamp($Tokens[4])
		$Signed  = [DnsRecord_RRSIG]::ToTimestamp($Tokens[5])

		$this.Signature = $Data
		$this.SignatureData = [PSCustomObject][Ordered]@{
			RRType = $Tokens[0]
			KeyType = $Tokens[1]
			HashType = $Tokens[2]
			TTL = $Tokens[3]
			Expires = $Expires
			Signed  = $Signed
			KeyID = $Tokens[6]
			RRName = $Tokens[7]
			Signature = $Tokens[8]
		}
	}

	[String] ToString() {
		Return ([DnsRecord_Base]$this).ToString($this.Signature)
	}
}

Class DnsRecord_SOA : DnsRecord_Base {
	[Alias('MNAME')]   [String] $PrimaryServer
	[Alias('RNAME','Administrator')]   [String] $NameAdministrator
	[Alias('Serial')]  [UInt32] $SerialNumber
	[Alias('Refresh')] [UInt32] $TimeToZoneRefresh
	[Alias('Retry')]   [UInt32] $TimeToZoneFailureRetry
	[Alias('Expire')]  [UInt32] $TimeToExpiration
	[Alias('Minimum')] [UInt32] $DefaultTTL

	DnsRecord_SOA() {
		$this.Section = 'Authority'
	}
	
	[Void] SetData([String] $Data) {
		$this.PrimaryServer, $this.NameAdministrator, $this.SerialNumber, `
			$this.TimeToZoneRefresh, $this.TimeToZoneFailureRetry, `
			$this.TimeToExpiration, $this.DefaultTTL = ($Data -Split "\s+",7)
		
		$this.PrimaryServer = $this.PrimaryServer -Replace "\.$"
		                      # to mimic Resolve-DnsName output
	}

	[String] ToString() {
		Return ([DnsRecord_Base]$this).ToString(
			$this.PrimaryServer +
			' ' + $this.NameAdministrator +
			' ' + $this.SerialNumber +
			' ' + $this.TimeToZoneRefresh +
			' ' + $this.TimeToZoneFailureRetry +
			' ' + $this.TimeToExpiration +
			' ' + $this.DefaultTTL
		)
	}
}

Class DnsRecord_SRV : DnsRecord_Base {
	[String] $Service
	[String] $Protocol
	[UInt16] $Priority
	[Uint16] $Weight
	[UInt16] $Port
	[String] $NameTarget

	[Void] SetData([String] $Data) {
		$this.Priority, $this.Weight, $this.Port, $this.NameTarget = ($Data -Split "\s+",4)

		$this.NameTarget = $this.NameTarget -Replace "\.$"
		                   # to mimic Resolve-DnsName output
	}

	[Void] SetServicePriority([String] $Query) {
		$this.Service, $this.Protocol, $this.Name = ($Query -Split "\.",3)
	}

	[String] ToString() {
		Return ([DnsRecord_Base]$this).ToString(
			$this.Priority +
			' ' + $this.Weight +
			' ' + $this.Port +
			' ' + $this.NameTarget
		)
	}
}

Class DnsRecord_TXT : DnsRecord_Base {
	[Alias('Text')]
	[String] $Strings

	[Void] SetData([String] $Data) {
		$this.Strings = $Data
	}

	[String] ToString() {
		Return ([DnsRecord_Base]$this).ToString($this.Strings)
	}
}

