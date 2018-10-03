#!/bin/sh

# ZFS Snapshot generation script. "Library"
#
# This script generates ZFS snapshots on a periodic basis and should
# be installed in /etc/periodic/zfssnap.sh with 555 permissions

# Internal function to create a new ZFS snapshot
# Parameters:
#   $1 Dataset name
#   $2 type (monthly, daily)

zfssnap_create()
{
    case "$2" in
	daily)
		fnpart=`date +"daily-%Y%m%d"`
		;;
        weekly)
		fnpart=`date +"weekly-%Y%U"`
		;;
        monthly)
		fnpart=`date +"monthly-%Y%m"`
		;;
        *)
		echo "zfssnap: Unknown snapshot type $2"
		return 1
    esac

    snapname=$1@$fnpart

    # Check we dont recreate a snapshot

    if /sbin/zfs list $snapname > /dev/null 2>&1; then
	    echo "zfssnap: $snapname already exists"
	    return 2
    else
	    echo "zfssnap: Creating snapshot $snapname"
	    zfs snapshot $snapname
    fi
}

# Internal function to destroy
# a ZFS snapshot with given name
# Parameters:
#   $1 Snapshot name

zfssnap_destroy()
{
    snapname=$1

    # Validate our snapshot name at least contains an @

    if ! echo $snapname | grep -q @; then
	    echo "zfssnap: Will not destroy datasets without @ in their name ($snapname)"
	    return 1
    fi

    zfs destroy -r $snapname
}

# Creating snapshots function
#
# Argument 1: dataset name
# Argument 2: Type (daily, weekly, monthly)
# Argument 3: Number of snapshots to keep

zfssnap_createsnaps()
{
    dsname=$1
    type=$2
    keepcount=$3

    case "${type}" in
	    daily)
		    fnpart=`date +"daily-%Y%m%d"`
		    matcher="^$dsname@daily-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$"
		    ;;
	    weekly)
		    fnpart=`date +"weekly-%Y%U"`
		    matcher="^$dsname@weekly-[0-9][0-9][0-9][0-9][0-9][0-9]$"
		    ;;
	    monthly)
		    fnpart=`date +"monthly-%Y%m"`
		    matcher="^$dsname@monthly-[0-9][0-9][0-9][0-9][0-9][0-9]$"
		    ;;
	    *)
		    echo "zfssnap: Unknown snapshot type $2"
		    return 2
    esac

    # First check this dataset really exists ...
    if ! /sbin/zfs list $dsname > /dev/null 2>&1; then
	    echo "zfssnap: Dataset name $dsname does not exist. Skipping"
	    return 1
    fi

    # Create new snapshot
    if ! zfssnap_create $dsname $type; then
	    echo "zfssnap: Failed to create snapshot for $dsname. Skipping deletion of old snapshots"
	    return 3
    fi


    oldsnaps=`/sbin/zfs list -H -o name -t snapshot | /usr/bin/sort | /usr/bin/grep $matcher`
    numsnaps=`echo $oldsnaps | wc -w`

    if [ $numsnaps -ge 0 ]; then
	    # There ARE snapshots ...
	    deletecount=`expr $numsnaps - $keepcount`
	    count=0
	    for snapshot in $oldsnaps; do
		    if [ $count -ge $deletecount ]; then
			    break
		    fi
		    zfssnap_destroy $snapshot
		    count=`expr $count + 1`
	    done
    fi
}

# Arguments:
#   $1: zfssnap_datasets
#   $2: type
#   $3: Number of snaps to take

zfssnap_runsnaps()
{
    for dataset in $1; do
        zfssnap_createsnaps "${dataset}" $2 $3
    done
}
