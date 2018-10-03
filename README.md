# Really simple FreeBSD snapshot periodic scripts

This simple shell scripts provide a simple method to create periodic snapshots of a configureable list of ZFS datasets on a daily, weekly or monthly basis. They only accept a global configuration how many snapshots to keep (no per filesystem configuration).

## Installation

This scripts consist of multiple parts. There is a library
*zfssnap.sh* script that is shared by all periodic scripts.
The current periodic scripts expect this library to be available
at */etc/periodic/zfssnap.sh* (which is of course not the right
place).

The other parts are the periodic scripts themselves which
are contained in the respective *daily/600.zfssnap*,
*weekly/600.zfssnap* and *monthly/600.zfssnap* files - these
should be installed in the corresponding */etc/periodic/daily*,
*/etc/periodic/weekly* and */etc/periodic/monthly* directories.

All script files should have either 755 or 555 permissions set.

## Configuration

The ZFS snapshot script is controlled by variables set in
*/etc/periodic.conf*. The scripts can be enabled or disabled
via the

```
zfssnap_enable="YES"
```

variable. Two other configureable variables specify how many
snapshots should be kept on a daily, weekly and monthly basis.
For example

```
zfssnap_keep_daily="31"
zfssnap_keep_monthly="12"
```

would keep a snapshot for the previous 31 days and monthly
snapshots for the previous year. Because *zfssnap_keep_weekly*
has not been set there won't be any weekly snapshots.

Finally zfssnap_filesystems is a space separated list of
ZFS filesystems for which periodical snapshots should
be created

```
zfssnap_filesystems="zroot/usr/home/userA zroot/usr/home/userB"
```

would create snapshots as configured previously.