#!/sbin/sh

# Common constants for all scripts

# system_a partition info
system_a_partnum=25
system_a_partstart=1185792
system_a_treble_partend=6248447
system_a_stock_partend=7477247

# vendor_a partition info
vendor_a_partnum=50
vendor_a_partstart_system=6248448
vendor_a_partend_system=7477247
vendor_a_partstart_userdata=14550032
vendor_a_partend_userdata=15778832
vendor_a_blockdev=/dev/block/mmcblk0p50

# system_b partition info
system_b_partnum=26
system_b_partstart=7477248
system_b_treble_partend=12539903
system_b_stock_partend=13768703

# vendor_b partition info
vendor_b_partnum=51
vendor_b_partstart_system=12539904
vendor_b_partend_system=13768703
vendor_b_partstart_userdata=15778834
vendor_b_partend_userdata=17007633
vendor_b_blockdev=/dev/block/mmcblk0p51

# userdata partition info
userdata_partnum=49
userdata_stock_partstart=14550032
userdata_treble_partstart=17007634
