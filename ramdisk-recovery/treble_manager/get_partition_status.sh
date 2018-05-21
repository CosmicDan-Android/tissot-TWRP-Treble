#!/sbin/sh

# Return values:
# 0 = Unrecognized partition table
# 1 = Stock partition table
# 2 = Treble with System-shrunk
# 3 = Treble with Userdata-shrunk

source /treble_manager/constants.sh

# Initial status var's
system_a_status=invalid
vendor_a_status=invalid
system_b_status=invalid
vendor_b_status=invalid
userdata_status=invalid

# Get system_a info
system_a_partline=`sgdisk --print /dev/block/mmcblk0 | grep -i system_a`
system_a_partnum_current=$(echo "$system_a_partline" | awk '{ print $1 }')
system_a_partstart_current=$(echo "$system_a_partline" | awk '{ print $2 }')
system_a_partend_current=$(echo "$system_a_partline" | awk '{ print $3 }')
system_a_partname=$(echo "$system_a_partline" | awk '{ print $7 }')
if [ "$system_a_partnum_current" == "$system_a_partnum" ]; then
	if [ "$system_a_partstart_current" == "$system_a_partstart" -a "$system_a_partname" == "system_a" ]; then
		if [ "$system_a_partend_current" == "$system_a_treble_partend" ]; then
			system_a_status=treble
		elif [ "$system_a_partend_current" == "$system_a_stock_partend" ]; then
			system_a_status=stock
		fi
	fi
fi

# Get system_b info
system_b_partline=`sgdisk --print /dev/block/mmcblk0 | grep -i system_b`
system_b_partnum_current=$(echo "$system_b_partline" | awk '{ print $1 }')
system_b_partstart_current=$(echo "$system_b_partline" | awk '{ print $2 }')
system_b_partend_current=$(echo "$system_b_partline" | awk '{ print $3 }')
system_b_partname=$(echo "$system_b_partline" | awk '{ print $7 }')
if [ "$system_b_partnum_current" == "$system_b_partnum" ]; then
	if [ "$system_b_partstart_current" == "$system_b_partstart" -a "$system_b_partname" == "system_b" ]; then
		if [ "$system_b_partend_current" == "$system_b_treble_partend" ]; then
			system_b_status=treble
		elif [ "$system_b_partend_current" == "$system_b_stock_partend" ]; then
			system_b_status=stock
		fi
	fi
fi

# Get vendor_a info
vendor_a_partline=`sgdisk --print /dev/block/mmcblk0 | grep -i vendor_a`
vendor_a_partnum_current=$(echo "$vendor_a_partline" | awk '{ print $1 }')
vendor_a_partstart_current=$(echo "$vendor_a_partline" | awk '{ print $2 }')
vendor_a_partend_current=$(echo "$vendor_a_partline" | awk '{ print $3 }')
vendor_a_partname=$(echo "$vendor_a_partline" | awk '{ print $7 }')
if [ "$vendor_a_partnum_current" == "$vendor_a_partnum" ]; then
	if [ -b "$vendor_a_blockdev" -a "$vendor_a_partname" == "vendor_a" ]; then
		if [ "$vendor_a_partstart_current" == "$vendor_a_partstart_system" -a "$vendor_a_partend_current" == "$vendor_a_partend_system" ]; then
			vendor_a_status=treble_after_system
		elif [ "$vendor_a_partstart_current" == "$vendor_a_partstart_userdata" -a "$vendor_a_partend_current" == "$vendor_a_partend_userdata" ]; then
			vendor_a_status=treble_before_userdata
		fi
	fi
elif [ ! -b "$vendor_a_blockdev" ]; then
	vendor_a_status=none
fi

# Get vendor_b info
vendor_b_partline=`sgdisk --print /dev/block/mmcblk0 | grep -i vendor_b`
vendor_b_partnum_current=$(echo "$vendor_b_partline" | awk '{ print $1 }')
vendor_b_partstart_current=$(echo "$vendor_b_partline" | awk '{ print $2 }')
vendor_b_partend_current=$(echo "$vendor_b_partline" | awk '{ print $3 }')
vendor_b_partname=$(echo "$vendor_b_partline" | awk '{ print $7 }')
if [ "$vendor_b_partnum_current" == "$vendor_b_partnum" ]; then
	if [ -b "$vendor_b_blockdev" -a "$vendor_b_partname" == "vendor_b" ]; then
		if [ "$vendor_b_partstart_current" == "$vendor_b_partstart_system" -a "$vendor_b_partend_current" == "$vendor_b_partend_system" ]; then
			vendor_b_status=treble_after_system
		elif [ "$vendor_b_partstart_current" == "$vendor_b_partstart_userdata" -a "$vendor_b_partend_current" == "$vendor_b_partend_userdata" ]; then
			vendor_b_status=treble_before_userdata
		fi
	fi
elif [ ! -b "$vendor_b_blockdev" ]; then
	vendor_b_status=none
fi

# Get userdata info
userdata_partline=`sgdisk --print /dev/block/mmcblk0 | grep -i userdata`
userdata_partnum_current=$(echo "$userdata_partline" | awk '{ print $1 }')
userdata_partstart_current=$(echo "$userdata_partline" | awk '{ print $2 }')
#userdata_partend_current=$(echo "$userdata_partline" | awk '{ print $3 }')
userdata_partname=$(echo "$userdata_partline" | awk '{ print $7 }')
if [ "$userdata_partnum_current" == "$userdata_partnum" ]; then
	if [ "$userdata_partname" == "userdata" ]; then
		if [ "$userdata_partstart_current" == "$userdata_treble_partstart" ]; then
			userdata_status=treble
		elif [ "$userdata_partstart_current" == "$userdata_stock_partstart" ]; then
			userdata_status=stock
		fi
	fi
fi

######################
#system_a_status=invalid
#vendor_a_status=invalid
#system_b_status=invalid
#vendor_b_status=invalid
#userdata_status=invalid


# if any status is invalid, return 0
if [ "$system_a_status" == "invalid" -o "$vendor_a_status" == "invalid" -o "$system_b_status" == "invalid" -o "$vendor_b_status" == "invalid" -o "$userdata_status" == "invalid" ]; then
	exit 0
fi

# check if we have a stock partition map
if [ "$system_a_status" == "stock" -a "$vendor_a_status" == "none" -a "$system_b_status" == "stock" -a "$vendor_b_status" == "none" -a "$userdata_status" == "stock" ]; then
	exit 1
fi

# check if we have a shrunk-system Treble map
if [ "$system_a_status" == "treble" -a "$vendor_a_status" == "treble_after_system" -a "$system_b_status" == "treble" -a "$vendor_b_status" == "treble_after_system" -a "$userdata_status" == "stock" ]; then
	exit 2
fi

# check if we have a shrunk-userdata Treble map
if [ "$system_a_status" == "stock" -a "$vendor_a_status" == "treble_before_userdata" -a "$system_b_status" == "stock" -a "$vendor_b_status" == "treble_before_userdata" -a "$userdata_status" == "treble" ]; then
	exit 3
fi

# nothing else matched, so return 0
exit 0
