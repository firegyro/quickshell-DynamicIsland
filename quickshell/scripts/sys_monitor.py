#!/usr/bin/env python3
import json
import psutil
import sys

def get_cpu_temp():
    try:
        temps = psutil.sensors_temperatures()
        if not temps:
            return 0
        for name in ["coretemp", "k10temp", "zenpower", "aht10"]:
            if name in temps:
                for entry in temps[name]:
                    if "Package" in entry.label or "Tctl" in entry.label:
                        return entry.current
                return temps[name][0].current
        return 0
    except:
        return 0

def get_sys_info():
    # 1. CPU
    cpu_percent = psutil.cpu_percent(interval=0.1)

    # 2. 内存
    mem = psutil.virtual_memory()
    ram_used_gb = round((mem.total - mem.available) / (1024**3), 1)

    # 3. 硬盘
    disk = psutil.disk_usage("/")
    disk_percent = disk.percent

    # 4. 温度
    temp = get_cpu_temp()
    temp_percent = min(max(temp, 0), 100)

    # 5. 电池 (新增部分)
    battery = psutil.sensors_battery()
    if battery:
        batt_text = f"{int(battery.percent)}%"
        is_charging = battery.power_plugged
        batt_value = battery.percent / 100.0
    else:
        # 如果没有电池（台式机），给一个占位符
        batt_text = "N/A"
        is_charging = False
        batt_value = 0.0

    # 输出 JSON
    data = {
        "cpu": {"value": cpu_percent / 100.0, "text": f"{int(cpu_percent)}%"},
        "ram": {
            "value": mem.percent / 100.0,
            "text": f"{ram_used_gb}G",
        },
        "disk": {"value": disk_percent / 100.0, "text": f"{int(disk_percent)}%"},
        "temp": {"value": temp_percent / 100.0, "text": f"{int(temp)}°C"},
        "batt": {  # 对应 QML 中的 json.batt
            "value": batt_value,
            "text": batt_text,
            "is_charging": is_charging
        }
    }

    print(json.dumps(data))

if __name__ == "__main__":
    get_sys_info()
