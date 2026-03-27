#!/bin/bash

# Caminhos dos arquivos de status
TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
PERF=$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct)
GPU=$(cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status)

# Lógica para definir o Modo, Ícone e Cor (opcional para CSS)
if [ "$TURBO" -eq 1 ]; then
    TEXT="SAV "
    CLASS="saver"
elif [ "$PERF" -eq 100 ] && [ "$GPU" == "active" ]; then
    TEXT="PER 󱓟"
    CLASS="performance"
else
    TEXT="BAL ⚖️"
    CLASS="balanced"
fi

# Tooltip detalhado
TOOLTIP="Configurações Atuais:\n------------------\nTurbo Boost: $( [ $TURBO -eq 1 ] && echo 'OFF' || echo 'ON' )\nMax Performance: ${PERF}%\nGPU Status: ${GPU^^}"

# Saída em JSON para a Waybar
echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}"
