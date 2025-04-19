# TCP keepalive time (how often to check if the connection is still active)
echo 1800 > /proc/sys/net/ipv4/tcp_keepalive_time
# TCP keepalive interval (how often to check)
echo 60 > /proc/sys/net/ipv4/tcp_keepalive_intvl
# TCP keepalive probes (how many probes before the connection is considered dead)
echo 5 > /proc/sys/net/ipv4/tcp_keepalive_probes

# Enable TCP Fast Open
echo 3 > /proc/sys/net/ipv4/tcp_fastopen

# Disable TCP Slow Start
echo 1 > /proc/sys/net/ipv4/tcp_slow_start_after_idle

# Use the "best-effort" scheduler for the network
echo 1 > /proc/sys/net/core/netdev_budget

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
echo 5000 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us

echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy6/scaling_governor
echo 500 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/up_rate_limit_us
echo 5000 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/down_rate_limit_us

# Fix mali GPU
echo 'simple_ondemand' > /sys/devices/platform/soc/13000000.mali/devfreq/13000000.mali/governor
echo 990000000 > /sys/devices/platform/soc/13000000.mali/devfreq/13000000.mali/max_freq
echo 415000000 > /sys/devices/platform/soc/13000000.mali/devfreq/13000000.mali/min_freq
echo 50 > /sys/devices/platform/soc/13000000.mali/devfreq/13000000.mali/polling_interval

# Use simple_ondemand as DVFSRC default governor
echo 'simple_ondemand' > /sys/devices/platform/soc/10012000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor
echo 50 > /sys/devices/platform/soc/10012000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/polling_interval

# Memory optimization
echo 0 > /proc/sys/vm/dirty_ratio
echo 0 > /proc/sys/vm/dirty_background_ratio
echo 500 > /proc/sys/vm/dirty_writeback_centisecs
echo 200 > /proc/sys/vm/dirty_expire_centisecs

# Ultra-Low-Latency
echo 2000000 > /proc/sys/kernel/sched_latency_ns
echo 250000 > /proc/sys/kernel/sched_migration_cost_ns
echo 0 > /proc/sys/kernel/sched_wakeup_granularity_ns
echo 500000 > /proc/sys/kernel/sched_min_granularity_ns
echo 100 > /proc/sys/kernel/sched_util_clamp_min_rt_default
echo 0 > /proc/sys/kernel/sched_schedstats

# Runtime fs tuning
echo 128 > /sys/block/sda/queue/nr_requests
echo 1 > /sys/block/sda/queue/iostats

# Enable console_suspend to save power
echo "Y" > /sys/module/printk/parameters/console_suspend

