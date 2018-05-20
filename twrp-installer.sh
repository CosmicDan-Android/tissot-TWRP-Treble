#!/sbin/sh
# LazyFlasher boot image patcher script by jcadduono

tmp=/tmp/twrp-install
bin=$tmp/tools/arm64
split_img_a=$tmp/split-img-a
split_img_b=$tmp/split-img-b

console=$(cat /tmp/console)
[ "$console" ] || console=/proc/$$/fd/1

cd "$tmp"
./config.sh

chmod -R 755 "$bin"
rm -rf "$split_img_a"
rm -rf "$split_img_b"

print() {
	if [ "$1" ]; then
		echo "ui_print - $1" > "$console"
	else
		echo "ui_print  " > "$console"
	fi
	echo
}

abort() {
	[ "$1" ] && {
		print "Error: $1!"
		print "Aborting..."
	}
	exit 1
}

## start install methods

# find the location of the boot block
find_boot() {
	verify_block() {
		boot_block_a=$(readlink -f "$boot_block"_a)
		boot_block_b=$(readlink -f "$boot_block"_b)
		# if the boot block is a file, we must use dd
		if [ -f "$boot_block" ]; then
			use_dd=true
		# if the boot block is a block device, we use flash_image when possible
		elif [ -b "$boot_block" ]; then
			case "$boot_block" in
				/dev/block/bml*|/dev/block/mtd*|/dev/block/mmc*)
					use_dd=false ;;
				*)
					use_dd=true ;;
			esac
		# otherwise we have to keep trying other locations
		else
			return 1
		fi
		print "Found by-name boot partition at: $boot_block"
		print "Found boot_a partition at: $boot_block_a"
		print "Found boot_b partition at: $boot_block_b"
	}
	# if we already have boot block set then verify and use it
	[ "$boot_block" ] && verify_block && return
	# otherwise, time to go hunting!
	if [ -f /etc/recovery.fstab ]; then
		# recovery fstab v1
		boot_block=$(awk '$1 == "/boot" {print $3}' /etc/recovery.fstab)
		[ "$boot_block" ] && verify_block && return
		# recovery fstab v2
		boot_block=$(awk '$2 == "/boot" {print $1}' /etc/recovery.fstab)
		[ "$boot_block" ] && verify_block && return
	fi
	for fstab in /fstab.*; do
		[ -f "$fstab" ] || continue
		# device fstab v2
		boot_block=$(awk '$2 == "/boot" {print $1}' "$fstab")
		[ "$boot_block" ] && verify_block && return
		# device fstab v1
		boot_block=$(awk '$1 == "/boot" {print $3}' "$fstab")
		[ "$boot_block" ] && verify_block && return
	done
	if [ -f /proc/emmc ]; then
		# emmc layout
		boot_block=$(awk '$4 == "\"boot\"" {print $1}' /proc/emmc)
		[ "$boot_block" ] && boot_block=/dev/block/$(echo "$boot_block" | cut -f1 -d:) && verify_block && return
	fi
	if [ -f /proc/mtd ]; then
		# mtd layout
		boot_block=$(awk '$4 == "\"boot\"" {print $1}' /proc/mtd)
		[ "$boot_block" ] && boot_block=/dev/block/$(echo "$boot_block" | cut -f1 -d:) && verify_block && return
	fi
	if [ -f /proc/dumchar_info ]; then
		# mtk layout
		boot_block=$(awk '$1 == "/boot" {print $5}' /proc/dumchar_info)
		[ "$boot_block" ] && verify_block && return
	fi
	abort "Unable to find boot block location"
}

# dump boot and unpack the android boot image
dump_boot() {
	print "Dumping & unpacking original boot image..."
	cd "$tmp"
	if $use_dd; then
		dd if="$boot_block"_a of=boot_a.img
		[ $? = 0 ] || abort "Unable to read boot partition A"
		dd if="$boot_block"_b of=boot_b.img
		[ $? = 0 ] || abort "Unable to read boot partition B"
	else
		dump_image "$boot_block_a" boot_a.img
		[ $? = 0 ] || abort "Unable to read boot partition A"
		dump_image "$boot_block_b" boot_b.img
		[ $? = 0 ] || abort "Unable to read boot partition B"
	fi
	"$bin/bootimg" xvf boot_a.img "$split_img_a" ||
		abort "Unpacking boot image A failed"
	"$bin/bootimg" xvf boot_b.img "$split_img_b" ||
		abort "Unpacking boot image B failed"
}

# build the new boot image
build_boot() {
	cd "$tmp"
	print "Building new boot image..."
	kernel=
	rd=
	dtb=
	for image in zImage zImage-dtb Image Image-dtb Image.gz Image.gz-dtb Image.lz4 Image.lz4-dtb; do
		if [ -s $image ]; then
			kernel=$image
			print "Found replacement kernel $image!"
			break
		fi
	done
	if [ -s ramdisk-recovery.img ]; then
		rd="$tmp/ramdisk-recovery.img"
		print "Found TWRP ramdisk image!"
	fi
	if [ -s dtb.img ]; then
		dtb=dtb.img
		print "Found replacement device tree image!"
	fi
	"$bin/bootimg" cvf boot-new-a.img "$split_img_a" \
		${kernel:+--kernel "$kernel"} \
		${rd:+--ramdisk "$rd"} \
		${dtb:+--dt "$dtb"} \
		--hash ||
		abort "Repacking boot image A failed"
	"$bin/bootimg" cvf boot-new-b.img "$split_img_b" \
		${kernel:+--kernel "$kernel"} \
		${rd:+--ramdisk "$rd"} \
		${dtb:+--dt "$dtb"} \
		--hash ||
		abort "Repacking boot image B failed"
}

# backup old boot image
backup_boot() {
	[ "$boot_backup" ] || return
	print "Backing up original boot image to $boot_backup..."
	cd "$tmp"
	mkdir -p "$(dirname "$boot_backup")"
	cp -f boot.img "$boot_backup"
}

# verify that the boot image exists and can fit the partition
verify_size() {
	print "Verifying boot image size..."
	cd "$tmp"
	[ -s boot-new-a.img ] || abort "New boot image A not found!"
	old_sz=$(wc -c < boot_a.img)
	new_sz=$(wc -c < boot-new-a.img)
	if [ "$new_sz" -gt "$old_sz" ]; then
		size_diff=$((new_sz - old_sz))
		print " Partition A size: $old_sz bytes"
		print "Boot image A size: $new_sz bytes"
		abort "Boot image A is $size_diff bytes too large for partition"
	fi
	[ -s boot-new-b.img ] || abort "New boot image B not found!"
	old_sz=$(wc -c < boot_b.img)
	new_sz=$(wc -c < boot-new-b.img)
	if [ "$new_sz" -gt "$old_sz" ]; then
		size_diff=$((new_sz - old_sz))
		print " Partition B size: $old_sz bytes"
		print "Boot image B size: $new_sz bytes"
		abort "Boot image B is $size_diff bytes too large for partition"
	fi
}

# write the new boot image to boot block
write_boot() {
	print "Writing new boot image to memory..."
	cd "$tmp"
	if $use_dd; then
		dd if=boot-new-a.img of="$boot_block"_a
		[ $? = 0 ] || abort "Failed to write boot image A! You may need to restore your boot partition"
		dd if=boot-new-b.img of="$boot_block"_b
		[ $? = 0 ] || abort "Failed to write boot image B! You may need to restore your boot partition"
	else
		flash_image "$boot_block_a" boot-new-a.img
		flash_image "$boot_block_b" boot-new-b.img
	fi
	[ $? = 0 ] || abort "Failed to write boot image! You may need to restore your boot partition"
}

## end install methods

## start boot image patching

find_boot

dump_boot

build_boot

verify_size

#backup_boot

write_boot

## end boot image patching
