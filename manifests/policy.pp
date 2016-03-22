# Define a traffic policy between two zones
#
# Attributes:
#
#  * `source` (string, required)
#
#     The name of the zone from which traffic must be sourced in order to be affected by
#     this policy.  It must be either the name of a zone defined by a `shorewall::zone`
#     resource, or else the special values `"fw"` (meaning the machine itself), or
#     `"all"` (meaning all zones not otherwise covered by a preceding policy directive).
#
#  * `dest` (string; required)
#
#     The name of the zone to which traffic must be destined in order to be affected by
#     this policy.  Its valid values are as per the `source` attribute.
#
#  * `policy` (string; optional; default `"REJECT"`)
#
#     The policy to apply to traffic matching the given `source` and `dest`.  This must
#     be one of the strings `"REJECT"`, `"ACCEPT"`, `"DROP"`, `"CONTINUE"`, `"QUEUE"`,
#     `"NFQUEUE[:<queuenumber>]"`, `"CONTINUE"`, or `"NONE"`.  The meaning of each of these
#     values is defined in http://www.shorewall.net/manpages/shorewall-policy.html.
#
#  * `reciprocal` (boolean; optional; default `false`)
#
#     Whether or not to make this policy bi-directional.  If set, a second policy resource
#     will be created which swaps the `source`/`dest` and applies the same `policy` value.
#
#  * `log` (string; optional; default `undef`)
#
#     If defined, then a log level will be defined for traffic which matches
#     this policy.  Valid values are any of the logging severity
#     values`"debug"`, `"info"`, `"notice"`, `"warning"`, `"err"`, `"crit"`,
#     `"alert"`, `"emerg"`, or `"panic"`, or one of the iptables logging
#     targets `"ULOG"` or `"NFLOG"`.
#
#  * `ordinal` (integer; optional; default varies)
#
#     Policies are matched in the order they are defined, the first match
#     wins.  This means that you will sometimes need to adjust the ordering
#     of policies to get the outcome you desire.
#
#     The default value for this attribute varies, based on the source and
#     destination you specify.  Policies which specify `"all"` as a source
#     or destination get an ordinal of `66`, a policy which specifies
#     `"all"` as both source *and* destination gets an ordinal of `99`, and
#     everything else gets an ordinal of `33`.  This will usually get the
#     ordering correct, but you may need to occasionally fiddle with this.
#
#  * `v4_only` (boolean; optional; default `false`)
#
#     Specify that this firewall rule is *only* to be defined for IPv4.
#     This sort of thing is usually determined heuristically, but there are
#     some cases where you want to be explicit about it.  Note that setting
#     this attribute overrides the normal heuristics, so you can end up
#     assploding shorewall if you (for example) use IPv6 addresses in a rule
#     marked `v4_only`.  So be careful.
#
#  * `v6_only` (boolean; optional; default `false`)
#
#     The IPv6 equivalent of `v4_only`.
#
define shorewall::policy(
		$source,
		$dest,
		$policy     = "REJECT",
		$reciprocal = false,
		$log        = undef,
		$ordinal    = undef,
		$v4         = true,
		$v6         = true,
) {
	if $reciprocal {
		shorewall::policy { "${name} -- reciprocal":
			source    => $dest,
			dest      => $source,
			policy    => $policy,
			log       => $log,
			ordinal   => $ordinal,
			v4        => $v4,
			v6        => $v6,
		}
	}

	if $ordinal == undef {
		if $source == "all" and $dest == "all" {
			$_ordinal = 99
		} elsif $source == "all" or $dest == "all" {
			$_ordinal = 66
		} else {
			$_ordinal = 33
		}
	} else {
		$_ordinal = $ordinal
	}

	if $v4 {
		bitfile::bit {
			"shorewall::policy ${name}":
				path    => "/etc/shorewall/policy",
				content => "$source $dest $policy $log",
				ordinal => $_ordinal;
		}
	}

	if $v6 {
		bitfile::bit {
			"shorewall6::policy ${name}":
				path    => "/etc/shorewall6/policy",
				content => "$source $dest $policy $log",
				ordinal => $_ordinal;
		}
	}
}
