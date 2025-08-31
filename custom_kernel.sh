# Setup runtime cpusets
echo "0-7" > /dev/cpuset/top-app/cpus
echo "0-7" > /dev/cpuset/foreground/cpus
echo "0-5" > /dev/cpuset/background/cpus
echo "0-5" > /dev/cpuset/system-background/cpus
echo "0-1" > /dev/cpuset/restricted/cpus

# Set default and maximum receive buffer sizes
echo 1310720 > /proc/sys/net/core/rmem_default
echo 8388608 > /proc/sys/net/core/rmem_max

# Set default and maximum send buffer sizes
echo 327680 > /proc/sys/net/core/wmem_default
echo 8388608 > /proc/sys/net/core/wmem_max

# Set maximum size for ancillary data and options
echo 20480 > /proc/sys/net/core/optmem_max

# Increase network device input backlog
echo 10000 > /proc/sys/net/core/netdev_max_backlog

# Set TCP receive buffer sizes (min default max)
echo "2097152 4194304 8388608" > /proc/sys/net/ipv4/tcp_rmem

# Set TCP send buffer sizes (min default max)
echo "262144 524288 8388608" > /proc/sys/net/ipv4/tcp_wmem

# Set total TCP memory thresholds (low pressure high - in pages)
echo "44259 59012 88518" > /proc/sys/net/ipv4/tcp_mem

# Set total UDP memory thresholds (low pressure high - in pages)
echo "88518 118025 177036" > /proc/sys/net/ipv4/udp_mem

# Set RPS (Receive Packet Steering) for each rmnet interface
echo fe > /sys/class/net/rmnet0/queues/rx-0/rps_cpus
echo fe > /sys/class/net/rmnet1/queues/rx-0/rps_cpus
echo fe > /sys/class/net/rmnet2/queues/rx-0/rps_cpus
echo fe > /sys/class/net/rmnet3/queues/rx-0/rps_cpus
echo fe > /sys/class/net/rmnet4/queues/rx-0/rps_cpus
echo fe > /sys/class/net/rmnet5/queues/rx-0/rps_cpus
echo fe > /sys/class/net/rmnet6/queues/rx-0/rps_cpus
echo fe > /sys/class/net/rmnet7/queues/rx-0/rps_cpus

# Set governor settings for CPU scaling
echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
echo 500 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
echo 1000 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us

echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy6/scaling_governor
echo 500 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/up_rate_limit_us
echo 900 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/down_rate_limit_us

# Fix mali GPU
echo 'simple_ondemand' > /sys/devices/platform/soc/13000000.mali/devfreq/13000000.mali/governor
echo 1003000000 > /sys/devices/platform/soc/13000000.mali/devfreq/13000000.mali/max_freq
echo 390000000 > /sys/devices/platform/soc/13000000.mali/devfreq/13000000.mali/min_freq
echo 25 > /sys/devices/platform/soc/13000000.mali/devfreq/13000000.mali/polling_interval

# Use simple_ondemand as DVFSRC default governor
echo 'simple_ondemand' > /sys/devices/platform/soc/10012000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor
echo 50 > /sys/devices/platform/soc/10012000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/polling_interval

# Memory optimization
echo 5 > /proc/sys/vm/dirty_ratio
echo 3 > /proc/sys/vm/dirty_background_ratio
echo 500 > /proc/sys/vm/dirty_writeback_centisecs
echo 200 > /proc/sys/vm/dirty_expire_centisecs

# Ultra-Low-Latency
echo 2000000 > /proc/sys/kernel/sched_latency_ns
echo 250000 > /proc/sys/kernel/sched_migration_cost_ns
echo 500000 > /proc/sys/kernel/sched_min_granularity_ns
echo 100 > /proc/sys/kernel/sched_util_clamp_min_rt_default
echo 0 > /proc/sys/kernel/sched_wakeup_granularity_ns
echo 0 > /proc/sys/kernel/sched_schedstats

# Runtime fs tuning
echo 64 > /sys/block/sda/queue/nr_requests
echo 0 > /sys/block/sda/queue/iostats

# Disable logging
echo "0" > /proc/sys/debug/exception-trace
echo "0 0 0 0" > /proc/sys/kernel/printk

# Enable console_suspend to save power
echo "Y" > /sys/module/printk/parameters/console_suspend

# Enable KSM
echo 1 > /sys/kernel/mm/ksm/run

