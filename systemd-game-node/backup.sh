#!/bin/bash

CRAFTY_SERVERS="/var/opt/minecraft/crafty/crafty-4/servers"
LOCAL_BACKUP_DIR="/home/ubuntu/backups_locais"
DRIVE_DESTINATION="backupworlds:MinecraftBackups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)

mkdir -p "$LOCAL_BACKUP_DIR"

echo "=== Iniciando Processamento de Backups ==="

for dir in "$CRAFTY_SERVERS"/*; do
    if [ -d "$dir" ]; then
        server_name=$(basename "$dir")
        ZIP_NAME="backup_${server_name}_${DATE}.zip"
        
        echo "--------------------------------------------------"
        echo "Processando o servidor: $server_name..."
        
        sudo zip -r "$LOCAL_BACKUP_DIR/$ZIP_NAME" "$dir" -x "*/logs/*" "*/cache/*" > /dev/null
        
        rclone copy "$LOCAL_BACKUP_DIR/$ZIP_NAME" "$DRIVE_DESTINATION/$server_name"
        
        rm -f "$LOCAL_BACKUP_DIR/$ZIP_NAME"
        
        files_on_drive=$(rclone lsf --files-only "$DRIVE_DESTINATION/$server_name" | sort)
        file_count=$(echo "$files_on_drive" | wc -l)
        
        if [ "$file_count" -gt 3 ]; then
            delete_count=$((file_count - 3))
            echo "$files_on_drive" | head -n "$delete_count" | while read -r file_to_delete; do
                if [ -n "$file_to_delete" ]; then
                    echo "Deletando backup excedente mais antigo do Drive: $file_to_delete"
                    rclone deletefile "$DRIVE_DESTINATION/$server_name/$file_to_delete"
                fi
            done
        fi
    fi
done

echo "=== Todos os backups foram processados e sincronizados! ==="
