# GlusterFS module by James
# Copyright (C) 2010-2013+ James Shubin
# Written by James Shubin <james@shubin.ca>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class gluster::server(
	$vip = '',	# vip of the cluster (optional but recommended)
	$nfs = false,								# TODO
	$repo = true,	# true/false/or pick a specific version (true)
	$shorewall = false,
	$zone = 'net',								# TODO: allow a list of zones
	$ips = false,	# an optional list of ip's for each in hosts[]
	$clients = []	# list of allowed client ip's	# TODO: get from exported resources
) {
	$FW = '$FW'			# make using $FW in shorewall easier

	# ensure these are from a gluster repo
	if $repo {
		$version = $repo ? {
			true => '',	# latest
			default => "${repo}",
		}
		class { '::gluster::repo':
			version => "${version}",
		}
	}

	package { 'glusterfs-server':
		ensure => present,
		require => $repo ? {
			false => undef,
			default => Class['::gluster::repo'],
		},
	}

	# NOTE: not that we necessarily manage anything in here at the moment...
	file { '/etc/glusterfs/':
		ensure => directory,		# make sure this is a directory
		recurse => false,		# TODO: eventually...
		purge => false,			# TODO: eventually...
		force => false,			# TODO: eventually...
		owner => root,
		group => root,
		mode => 644,
		#notify => Service['glusterd'],	# TODO: ???
		require => Package['glusterfs-server'],
	}

	file { '/etc/glusterfs/glusterd.vol':
		content => template('gluster/glusterd.vol.erb'),	# NOTE: currently no templating is being done
		owner => root,
		group => root,
		mode => 644,			# u=rw,go=r
		ensure => present,
		require => File['/etc/glusterfs/'],
	}

	file { '/var/lib/glusterd/':
		ensure => directory,		# make sure this is a directory
		recurse => false,		# TODO: eventually...
		purge => false,			# TODO: eventually...
		force => false,			# TODO: eventually...
		owner => root,
		group => root,
		mode => 644,
		#notify => Service['glusterd'],	# TODO: eventually...
		require => File['/etc/glusterfs/glusterd.vol'],
	}

	file { '/var/lib/glusterd/peers/':
		ensure => directory,		# make sure this is a directory
		recurse => true,		# recursively manage directory
		purge => true,
		force => true,
		owner => root,
		group => root,
		mode => 644,
		notify => Service['glusterd'],
		require => File['/var/lib/glusterd/'],
	}

	if $shorewall {
		# XXX: WIP
		#if type($ips) == 'array' {
		#	#$other_host_ips = inline_template("<%= ips.delete_if {|x| x == '${ipaddress}' }.join(',') %>")		# list of ips except myself
		#	$source_ips = inline_template("<%= (ips+clients).uniq.delete_if {|x| x.empty? }.join(',') %>")
		#	#$all_ips = inline_template("<%= (ips+[vip]+clients).uniq.delete_if {|x| x.empty? }.join(',') %>")

		#	$src = "${source_ips}" ? {
		#		'' => "${zone}",
		#		default => "${zone}:${source_ips}",
		#	}

		#$endport = inline_template('<%= 24009+hosts.count %>')
		#$nfs_endport = inline_template('<%= 38465+hosts.count %>')
		#shorewall::rule { 'gluster-24000':
		#	rule => "
		#	ACCEPT    ${src}    $FW    tcp    24009:${endport}
		#	",
		#	comment => 'Allow 24000s for gluster',
		#	before => Service['glusterd'],
		#}

		#if $nfs {					# FIXME: TODO
		#	shorewall::rule { 'gluster-nfs': rule => "
		#	ACCEPT    $(src}    $FW    tcp    38465:${nfs_endport}
		#	", comment => 'Allow nfs for gluster'}
		#}
	}

	# start service only after the firewall is opened and hosts are defined
	service { 'glusterd':
		enable => true,		# start on boot
		ensure => running,	# ensure it stays running
		hasstatus => false,	# FIXME: BUG: https://bugzilla.redhat.com/show_bug.cgi?id=836007
		hasrestart => true,	# use restart, not start; stop
	}
}

# vim: ts=8
