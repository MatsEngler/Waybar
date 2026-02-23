#!/bin/bash

# Arquivo de estado
STATE_FILE="/tmp/waybar_sys_cycle_state"

# --- LÓGICA DE TOGGLE ---
if [[ "$1" == "toggle" ]]; then
    if [[ ! -f "$STATE_FILE" ]]; then echo 0 > "$STATE_FILE"; fi

    current_state=$(cat "$STATE_FILE")

    # MUDANÇA IMPORTANTE:
    # Agora temos 4 estados (0=Disk, 1=CPU, 2=RAM, 3=GPU).
    # Então o módulo é 4. (0 -> 1 -> 2 -> 3 -> 0 ...)
    next_state=$(( (current_state + 1) % 4 ))

    echo "$next_state" > "$STATE_FILE"
    pkill -RTMIN+1 waybar
    exit 0
fi

# --- LÓGICA DE EXIBIÇÃO ---
if [[ ! -f "$STATE_FILE" ]]; then echo 0 > "$STATE_FILE"; fi
current_mode=$(cat "$STATE_FILE")

text=""
tooltip=""
class=""

case $current_mode in
    0) # Disk
        usage=$(df -h / | awk 'NR==2 {print $5}')
        avail=$(df -h / | awk 'NR==2 {print $4}')
        text="$usage "
        tooltip="Disk: $usage Used, $avail Available"
        class="disk"
        ;;
    1) # CPU
        cpu_load=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        cpu_int=$(printf "%.0f" "$cpu_load")
        text="${cpu_int}%  "
        tooltip="CPU Load: ${cpu_load}%"
        class="cpu"
        ;;
    2) # RAM
        used=$(free -h | awk '/^Mem/ {print $3}')
        total=$(free -h | awk '/^Mem/ {print $2}')
        percent=$(free -m | awk '/^Mem/ {printf("%.0f", $3/$2 * 100)}')
	icon_frog=$(echo -e "\uedf8")
        text="<span size='7pt'>$used</span>$icon_frog"
        tooltip="RAM: $used / $total ($percent%)"
        class="memory"
        ;;
    3) # MODO GPU (NVIDIA - Apenas Uso)
        # --query-gpu=utilization.gpu: Pede apenas a % de uso.
        # --format=csv,noheader,nounits: Retorna apenas o número puro (ex: 45).
        gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
        
        # Tratamento de erro básico (se o driver falhar, assume 0)
        if [[ -z "$gpu_usage" ]]; then gpu_usage="0"; fi

        # Exibição limpa: Ícone + Porcentagem
        text="${gpu_usage}% 󰏘"
        
        # Tooltip simples
        tooltip="NVIDIA GPU Usage: ${gpu_usage}%"
        
        # Mantém a classe para colorir no CSS (Verde ou Roxo)
        class="gpu"
        ;;
esac

echo -e "{\"text\":\"$text\", \"tooltip\":\"$tooltip\", \"class\":\"$class\"}"
