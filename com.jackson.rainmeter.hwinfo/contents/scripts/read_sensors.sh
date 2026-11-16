#!/bin/sh
export LC_ALL=C

# Cache static hardware info once per boot in /dev/shm/hwmonitor_static
STATIC_FILE="/dev/shm/hwmonitor_static"
if [ ! -f "$STATIC_FILE" ]; then
    # 1. CPU Name, Cores, Threads
    CPU_RAW=$(awk -F': ' '
        /^model name/ && !model { model=$2 }
        /^cpu cores/ && !cores { cores=$2 }
        /^processor/ { threads++ }
        END {
            gsub(/\(R\)|\(TM\)|\(tm\)|Processor|[0-9]+-Core|with Radeon.*|CPU @.*/, "", model)
            gsub(/  +/, " ", model)
            sub(/^ +/, "", model); sub(/ +$/, "", model)
            if (!cores) cores = threads
            print model "|" cores "C / " threads "T"
        }
    ' /proc/cpuinfo 2>/dev/null)
    CPU_NAME=$(printf "%s" "$CPU_RAW" | cut -d'|' -f1)
    CPU_BADGE=$(printf "%s" "$CPU_RAW" | cut -d'|' -f2)
    [ -z "$CPU_NAME" ] && CPU_NAME="Linux CPU"
    [ -z "$CPU_BADGE" ] && CPU_BADGE="CPU"

    # CPU Max Clock MHz
    CPU_MAX_KHZ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo 4250000)
    CPU_MAX_MHZ=$((CPU_MAX_KHZ / 1000))
    [ "$CPU_MAX_MHZ" -lt 1000 ] && CPU_MAX_MHZ=4250

    # 2. GPU Name & Vendor
    GPU_LINES=$(lspci 2>/dev/null | grep -iE "vga|3d|display" || true)
    GPU_LINE=$(printf "%s\n" "$GPU_LINES" | tail -n 1)
    GPU_VENDOR="amd"
    if printf "%s" "$GPU_LINE" | grep -qi "nvidia"; then
        GPU_VENDOR="nvidia"
    elif printf "%s" "$GPU_LINE" | grep -qi "intel" && ! printf "%s" "$GPU_LINES" | grep -qiE "amd|ati|radeon|nvidia"; then
        GPU_VENDOR="intel"
    fi

    GPU_NAME=$(printf "%s" "$GPU_LINE" | awk '
    {
        n = split($0, arr, "[")
        best = ""
        for (i = 2; i <= n; i++) {
            split(arr[i], sub_arr, "]")
            val = sub_arr[1]
            if (val !~ /^AMD\/ATI$/ && val !~ /^NVIDIA$/ && val !~ /^[0-9a-fA-F]{4}:[0-9a-fA-F]{4}$/) {
                best = val
            }
        }
        # Clean up dual-chip strings like "Radeon RX 9050 / 9060 XT" -> "Radeon RX 9060 XT"
        if (best ~ /Radeon RX [0-9]+ \/ [0-9]+/) {
            sub(/Radeon RX [0-9]+ \/ /, "Radeon RX ", best)
        }
        print best
    }')
    [ -z "$GPU_NAME" ] && GPU_NAME="GPU Graphics"

    # 3. RAM Type, Speed, Channel from /run/udev/data/+dmi:id (if readable without root)
    RAM_TYPE="DDR4"
    RAM_SPEED="2400"
    RAM_STICKS=0
    if [ -r "/run/udev/data/+dmi:id" ]; then
        DMI_OUT=$(awk -F'=' '
            /^E:MEMORY_DEVICE_[0-9]+_PRESENT=1/ { sticks++ }
            /^E:MEMORY_DEVICE_[0-9]+_TYPE=DDR/ && !rtype { rtype=$2 }
            /^E:MEMORY_DEVICE_[0-9]+_CONFIGURED_SPEED_MTS=[0-9]+/ && !rspeed { rspeed=$2 }
            /^E:MEMORY_DEVICE_[0-9]+_SPEED_MTS=[0-9]+/ && ! fallback_speed { fallback_speed=$2 }
            END {
                if (!rspeed) rspeed = fallback_speed
                print rtype "|" rspeed "|" sticks
            }
        ' /run/udev/data/+dmi:id 2>/dev/null)
        T_TYPE=$(printf "%s" "$DMI_OUT" | cut -d'|' -f1)
        T_SPEED=$(printf "%s" "$DMI_OUT" | cut -d'|' -f2)
        T_STICKS=$(printf "%s" "$DMI_OUT" | cut -d'|' -f3)
        [ -n "$T_TYPE" ] && RAM_TYPE="$T_TYPE"
        [ -n "$T_SPEED" ] && [ "$T_SPEED" -gt 400 ] 2>/dev/null && RAM_SPEED="$T_SPEED"
        [ -n "$T_STICKS" ] && RAM_STICKS="$T_STICKS"
    fi
    if [ "$RAM_STICKS" -eq 1 ] 2>/dev/null; then
        RAM_CHAN="Single-Channel"
    else
        RAM_CHAN="Dual-Channel"
    fi

    printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
        "$CPU_NAME" "$CPU_BADGE" "$CPU_MAX_MHZ" \
        "$GPU_NAME" "$GPU_VENDOR" \
        "$RAM_TYPE" "$RAM_SPEED" "$RAM_CHAN" > "$STATIC_FILE"
fi

# Fast dynamic poll via awk
exec awk -v static_file="$STATIC_FILE" '
BEGIN {
    getline cpu_name < static_file
    getline cpu_badge < static_file
    getline cpu_max_mhz < static_file
    getline gpu_name < static_file
    getline gpu_vendor < static_file
    getline ram_type < static_file
    getline ram_speed < static_file
    getline ram_chan < static_file
    close(static_file)

    if (cpu_max_mhz <= 0) cpu_max_mhz = 4250
    if (ram_speed <= 0) ram_speed = 2400
    if (ram_type == "") ram_type = "DDR4"
    if (ram_chan == "") ram_chan = "Dual-Channel"

    state_file = "/dev/shm/hwmonitor_state"
    cpu_temp = 0; cpu_power = 0; cpu_clock = 0; cpu_usage = 0
    gpu_temp = 0; gpu_hotspot = 0; gpu_clock = 0; gpu_mem_clock = 0
    gpu_fan = 0; gpu_power = 0; gpu_usage = 0; vram_used = 0; vram_total = 0
    gpu_max_sclk = 3000; gpu_max_power = 180
    driver_label = "[Ativo] Kernel Linux + Driver Nativo"

    if ((getline line < "/proc/stat") > 0) {
        close("/proc/stat")
        split(line, a, " ")
        idle = a[5] + a[6]
        total = a[2] + a[3] + a[4] + a[5] + a[6] + a[7] + a[8] + a[9]
    }
    prev_total = 0; prev_idle = 0; prev_uj = -1; prev_ts = 0
    if ((getline sline < state_file) > 0) {
        close(state_file)
        split(sline, s, " ")
        prev_total = s[1]; prev_idle = s[2]; prev_uj = s[3]; prev_ts = s[4]
    }
    d_total = total - prev_total
    d_idle = idle - prev_idle
    if (d_total > 0 && prev_total > 0) {
        cpu_usage = ((d_total - d_idle) / d_total) * 100.0
    }

    for (i = 0; i < 64; i++) {
        f = "/sys/devices/system/cpu/cpu" i "/cpufreq/scaling_cur_freq"
        if ((getline freq < f) > 0) {
            close(f)
            mhz = freq / 1000.0
            if (mhz > cpu_clock) cpu_clock = mhz
        } else if (i >= 4) {
            break
        }
    }

    cpu_hw_power = 0
    for (i = 0; i < 12; i++) {
        hw = "/sys/class/hwmon/hwmon" i
        nf = hw "/name"
        if ((getline hname < nf) > 0) {
            close(nf)
            if (hname == "k10temp" || hname == "zenpower" || hname == "zenergy" || hname == "coretemp") {
                tf = hw "/temp1_input"
                if ((getline v < tf) > 0) { close(tf); if (v / 1000.0 > cpu_temp) cpu_temp = v / 1000.0 }
                pf = hw "/power1_input"
                if ((getline pv < pf) > 0) { close(pf); cpu_hw_power = pv / 1000000.0 }
            } else if (hname == "amdgpu") {
                driver_label = "[Ativo] Kernel Linux + AMDgpu Driver"
                tf = hw "/temp1_input"; if ((getline v < tf) > 0) { close(tf); gpu_temp = v / 1000.0 }
                tf = hw "/temp2_input"; if ((getline v < tf) > 0) { close(tf); gpu_hotspot = v / 1000.0 }
                tf = hw "/freq1_input"; if ((getline v < tf) > 0) { close(tf); gpu_clock = v / 1000000.0 }
                tf = hw "/freq2_input"; if ((getline v < tf) > 0) { close(tf); gpu_mem_clock = (v / 1000000.0) * 2.0 }
                tf = hw "/fan1_input";  if ((getline v < tf) > 0) { close(tf); gpu_fan = v + 0 }
                tf = hw "/power1_average"
                if ((getline v < tf) > 0) { close(tf); gpu_power = v / 1000000.0 }
                else {
                    tf = hw "/power1_input"
                    if ((getline v < tf) > 0) { close(tf); gpu_power = v / 1000000.0 }
                }
                tf = hw "/power1_cap_max"
                if ((getline v < tf) > 0) { close(tf); if (v > 0) gpu_max_power = v / 1000000.0 }
                tf = hw "/device/gpu_busy_percent"; if ((getline v < tf) > 0) { close(tf); gpu_usage = v + 0.0 }
                tf = hw "/device/mem_info_vram_used"; if ((getline v < tf) > 0) { close(tf); vram_used = v + 0.0 }
                tf = hw "/device/mem_info_vram_total"; if ((getline v < tf) > 0) { close(tf); vram_total = v + 0.0 }
            }
        }
    }

    # NVIDIA fallback if no amdgpu found
    if (gpu_vendor == "nvidia" && vram_total == 0) {
        cmd = "nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,clocks.current.graphics,clocks.current.memory,fan.speed,power.draw,memory.used,memory.total,power.max_limit --format=csv,noheader,nounits 2>/dev/null"
        if ((cmd | getline nvline) > 0) {
            close(cmd)
            driver_label = "[Ativo] Kernel Linux + NVIDIA Driver"
            split(nvline, nv, ",")
            gpu_temp = nv[1] + 0; gpu_hotspot = gpu_temp
            gpu_usage = nv[2] + 0.0
            gpu_clock = nv[3] + 0; gpu_mem_clock = nv[4] + 0
            gpu_fan = nv[5] + 0; gpu_power = nv[6] + 0
            vram_used = (nv[7] + 0.0) * 1048576.0
            vram_total = (nv[8] + 0.0) * 1048576.0
            if (nv[9] + 0 > 0) gpu_max_power = nv[9] + 0
        }
    }

    now_ts = 0
    if ((getline upline < "/proc/uptime") > 0) {
        close("/proc/uptime")
        split(upline, u, " ")
        now_ts = u[1] + 0.0
    }

    rapl_f = "/sys/class/powercap/intel-rapl:0/energy_uj"
    cur_uj = -1
    if ((getline v < rapl_f) > 0) {
        close(rapl_f)
        cur_uj = v + 0
    }
    if (cpu_hw_power > 0) {
        cpu_power = cpu_hw_power
    } else if (cur_uj >= 0 && prev_uj >= 0 && now_ts > prev_ts && (now_ts - prev_ts) < 15) {
        duj = cur_uj - prev_uj
        if (duj < 0) duj += 262143328850
        cpu_power = (duj / 1000000.0) / (now_ts - prev_ts)
    } else {
        t_factor = (cpu_temp > 38) ? (cpu_temp - 38) * 0.45 : 0
        f_factor = (cpu_clock > 3600) ? ((cpu_clock - 3600) / 650.0) * 6.0 : 0
        cpu_power = 12.0 + (cpu_usage * 0.46) + t_factor + f_factor
        if (cpu_power > 105) cpu_power = 105
    }

    print total, idle, cur_uj, now_ts > state_file
    close(state_file)

    mem_total_kb = 32733484; mem_avail_kb = 16000000
    while ((getline mline < "/proc/meminfo") > 0) {
        if (mline ~ /^MemTotal:/) { split(mline, m, " "); mem_total_kb = m[2] }
        else if (mline ~ /^MemAvailable:/) { split(mline, m, " "); mem_avail_kb = m[2]; break }
    }
    close("/proc/meminfo")

    ram_total_gb = mem_total_kb / 1048576.0
    ram_free_gb = mem_avail_kb / 1048576.0
    ram_used_gb = ram_total_gb - ram_free_gb
    ram_pct = (ram_used_gb / ram_total_gb) * 100.0

    # Round physical RAM label to standard binary sizes (8, 16, 24, 32, 48, 64, 128)
    ram_phys_gb = int(ram_total_gb + 1.5)
    if (ram_phys_gb >= 30 && ram_phys_gb <= 33) ram_phys_gb = 32
    else if (ram_phys_gb >= 14 && ram_phys_gb <= 17) ram_phys_gb = 16
    else if (ram_phys_gb >= 60 && ram_phys_gb <= 65) ram_phys_gb = 64
    else if (ram_phys_gb >= 7 && ram_phys_gb <= 9) ram_phys_gb = 8
    ram_badge = ram_phys_gb " GB " ram_chan
    ram_title = "Memória RAM " ram_type

    if (vram_total <= 0) vram_total = 17179869184
    vram_mb = vram_used / 1048576.0
    vram_gb = vram_used / 1073741824.0
    vram_tot_gb = int((vram_total / 1073741824.0) + 0.5)
    if (vram_tot_gb <= 0) vram_tot_gb = 16
    vram_pct = (vram_used / vram_total) * 100.0
    gpu_badge = vram_tot_gb " GB GDDR6"

    printf "{\"cpuName\":\"%s\",\"cpuBadge\":\"%s\",\"cpuMaxClockMHz\":%.0f,\"gpuName\":\"%s\",\"gpuBadge\":\"%s\",\"gpuMaxPowerW\":%.0f,\"ramName\":\"%s\",\"ramBadge\":\"%s\",\"driverLabel\":\"%s\",\"cpuTemp\":%.0f,\"cpuPower\":%.0f,\"cpuUsage\":%.1f,\"cpuClock\":%.0f,\"gpuTemp\":%.0f,\"gpuHotSpot\":%.0f,\"gpuUsage\":%.1f,\"gpuClock\":%.0f,\"gpuMemClock\":%.0f,\"gpuFan\":%.0f,\"gpuPower\":%.0f,\"vramMB\":%.0f,\"vramGB\":%.1f,\"vramTotalGB\":%.1f,\"vramPct\":%.1f,\"ramUsedGB\":%.1f,\"ramTotalGB\":%.1f,\"ramFreeGB\":%.1f,\"ramPct\":%.1f,\"ramClock\":%.0f}\n",
        cpu_name, cpu_badge, cpu_max_mhz,
        gpu_name, gpu_badge, gpu_max_power,
        ram_title, ram_badge, driver_label,
        cpu_temp, cpu_power, cpu_usage, cpu_clock,
        gpu_temp, gpu_hotspot, gpu_usage, gpu_clock, gpu_mem_clock, gpu_fan, gpu_power,
        vram_mb, vram_gb, vram_tot_gb, vram_pct,
        ram_used_gb, ram_total_gb, ram_free_gb, ram_pct, ram_speed
}'
