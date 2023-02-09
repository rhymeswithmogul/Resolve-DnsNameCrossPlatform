## Version 2.0.0-alpha (in progress)
Major rewrite:
- Results are now returned as objects of type `[DnsRecord_Base]` or a subclass...
- ...which allows for custom formatting rules to better mimic the output of `DnsClient\Resolve-DnsName`.
- The cmdlet will now search for the `dig` command, in case it's not in `/usr/bin`.  It still must be located in `$env:Path`, though.
- Resolved a bug where dig's output might not be captured correctly (GitHub Issue #1 -- thanks, GitCouth!).

## Version 1.0.1 (January 24, 2023)
- Initial stable release.  Version 1.0.0 was pushed with a bug that got missed during testing.