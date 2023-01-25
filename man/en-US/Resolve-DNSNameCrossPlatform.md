---
external help file: Resolve-DnsNameCrossPlatform-help.xml
Module Name: Resolve-DnsNameCrossPlatform
online version: https://github.com/rhymeswithmogul/Resolve-DnsNameCrossPlatform/blob/master/man/en-US/Resolve-DnsNameCrossPlatform.md
schema: 2.0.0
---

# Resolve-DNSNameCrossPlatform

## SYNOPSIS
Performs a DNS name query resolution for the specified name.

## SYNTAX

```
Resolve-DNSNameCrossPlatform [-Name] <String> [-DnsOnly] [-DnssecCd] [-DnssecOk] [-NoIdn] [-NoRecursion]
 [-Server <String[]>] [-TcpOnly] [[-Type] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Resolve-DnsNameCrossPlatform cmdlet performs a DNS query for the specified name.  This cmdlet is functionally similar to the nslookup tool or the Windows-only Resolve-DnsName cmdlet, both of which allow users to query for names.

This cmdlet is meant to be a cross-platform implementation of as much of the Resolve-DnsName cmdlet as possible.

## EXAMPLES

### Example 1
```powershell
PS C:\> Resolve-DnsNameCrossPlatform -Name www.bing.com
```

This example resolves a name using the default options.

### Example 2
```powershell
PS C:\> Resolve-DnsNameCrossPlatform -Name www.bing.com -Server 10.0.0.1
```

This example resolves a name against the DNS server at 10.0.0.1.

### Example 3
```powershell
PS C:\> Resolve-DnsNameCrossPlatform -Name www.bing.com -Type A
```

This example queries for A type records for name www.bing.com.

## PARAMETERS

### -DnsOnly
Resolves this query using only the DNS protocol.  This is the only option supported by this cmdlet, and is implied; specifying it changes nothing.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DnssecCd
Sets the DNSSEC checking-disabled bit for this query.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DnssecOk
Sets the DNSSEC OK bit for this query.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Specifies the name to be resolved.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -NoIdn
Specifies not to use IDN encoding logic for the query.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoRecursion
Instructs the server to not use recursion when resolving this query.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
Specifies the IP addresses or host name of the DNS servers to be queried.  By default the interface DNS servers are queried if this parameter is not supplied.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TcpOnly
Uses only TCP for this query.  By default, this cmdlet will try UDP first, and fall back to TCP if needed, or if EDNS0 queries fail.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
The DNS resource record type which to query.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: UNKNOWN, A_AAAA, A, AAAA, CNAME, MX, NS, SOA, SRV, TXT

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
## OUTPUTS

### System.PSCustomObject
The PSCustomObject (similar to Microsoft.DnsClient.Commands.DnsRecord) contains all of the records returned from the wire for the specified DNS query.

## NOTES
On Windows, this cmdlet simply calls Resolve-DnsName.  On macOS and Linux, the dig (domain information grouper) tool must be installed.  It's included with recent versions of macOS, but Linux users will need to install the bind-utils package to make this work.

## RELATED LINKS

[GitHub](https://github.com/rhymeswithmogul/Resolve-DnsNameCrossPlatform)
[Resolve-DnsName]()
