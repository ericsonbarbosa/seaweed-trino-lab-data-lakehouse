#!/bin/bash

# Encerra o script em caso de erro
set -e

# Caminho absoluto para o executável do Windows no WSL
VAGRANT="/mnt/c/Program\ Files\ \(x86\)/Vagrant/bin/vagrant.exe"

echo "🔍 Verificando o status das máquinas virtuais..."

# 1. Checagem de Status
# Usamos eval para que o Bash interprete corretamente os espaços no caminho do Windows
VM_STATUS=$(eval "$VAGRANT status --machine-readable" | tr -d "\r" | grep ",state," | cut -d',' -f4)

if echo "$VM_STATUS" | grep -qv "running"; then
    echo "pit stop 🛑 Algumas VMs estão desligadas ou não criadas. Iniciando..."
    eval "$VAGRANT up --no-provision"
else
    echo "✅ VMs já estão em execução. Pulando o boot."
fi

echo "⏳ Aguardando estabilização da rede (5s)..."
sleep 5

echo "⚙️  Executando a orquestração com Ansible..."
export ANSIBLE_HOST_KEY_CHECKING=False

# 2. Verificação e atualização das chaves SSH para dentro do WSL
echo "🔑 Verificando chaves SSH das VMs..."
mkdir -p /home/ericson/.ssh/seaweed_lab

# Converte path Windows para path WSL
windows_to_wsl() {
  echo "$1" | sed 's|\\|/|g' | sed 's|^\([A-Za-z]\):|/mnt/\L\1|'
}

for VM in "seaweedfs-node:key_seaweed" "trino-sea-node:key_trino"; do
  VM_NAME="${VM%%:*}"
  KEY_NAME="${VM##*:}"
  DEST="/home/ericson/.ssh/seaweed_lab/$KEY_NAME"

  VAGRANT_KEY_RAW=$(eval "$VAGRANT ssh-config $VM_NAME" 2>/dev/null | tr -d "\r" | grep IdentityFile | awk '{print $2}')

  if [ -z "$VAGRANT_KEY_RAW" ]; then
    echo "⚠️  Não foi possível obter a chave da VM $VM_NAME, pulando..."
    continue
  fi

  VAGRANT_KEY=$(windows_to_wsl "$VAGRANT_KEY_RAW")

  EXPECTED=$(md5sum "$VAGRANT_KEY" 2>/dev/null | awk '{print $1}')
  CURRENT=$(md5sum "$DEST" 2>/dev/null | awk '{print $1}')

  if [ "$CURRENT" = "$EXPECTED" ]; then
    echo "✅ Chave de $VM_NAME já está atualizada, pulando."
  else
    echo "🔄 Atualizando chave de $VM_NAME..."
    cp "$VAGRANT_KEY" "$DEST"
    chmod 600 "$DEST"
  fi
done

# 3. Execução do Ansible
# Certifique-se de que o comando 'ansible-playbook' está instalado no seu Ubuntu/WSL
if command -v ansible-playbook >/dev/null 2>&1; then
    ansible-playbook -i ansible/inventory/hosts.ini ansible/playbook.yml "$@"
else
    echo "❌ Erro: ansible-playbook não encontrado no WSL. Instale com: sudo apt install ansible"
    exit 1
fi

echo "🏁 Processo concluído!"
read -p "Pressione [Enter] para fechar..."