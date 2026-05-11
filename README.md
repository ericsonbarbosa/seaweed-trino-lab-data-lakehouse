### Requitements do projeto

Instalação das dependências do projeto:
```bash
ansible-galaxy install -r requirements.yml
```
---

## Verificação dos serviços SeaweedFS

| Serviço               | URL                               | Descrição                                                                 |
|-----------------------|-----------------------------------|---------------------------------------------------------------------------|
| SeaweedFS Master      | http://192.168.56.101:9333        | Painel de status do cluster (volumes ativos, health checks)               |
| SeaweedFS Filer       | http://192.168.56.101:8888        | Interface web tipo "Google Drive" para navegar pelos arquivos do data lake |
| SeaweedFS S3 Gateway  | http://192.168.56.101:8333        | Endpoint compatível com S3 (retorna XML com informações do bucket)        |
| Trino                 | http://192.168.56.102:8080        | Interface web do Trino (login: `admin`, sem senha)                        | 

## Diagramas

```mermaid
useCaseDiagram
    actor "Usuário (SQL)" as User
    actor "Kubernetes (K3s)" as K8s
    actor "Trino" as Trino
    actor "Hive Metastore" as Hive
    actor "SeaweedFS" as Seaweed
    actor "PostgreSQL" as PG

    usecase "Executar consulta SQL" as UC1
    usecase "Planejar execução (Coordinator)" as UC2
    usecase "Distribuir tarefas aos Workers" as UC3
    usecase "Consultar metadados (Thrift)" as UC4
    usecase "Ler dados via S3 API" as UC5
    usecase "Escrever dados via S3 API" as UC6
    usecase "Provisionar volume persistente (PVC)" as UC7
    usecase "Montar volume via CSI Driver" as UC8
    usecase "Armazenar blocos de dados" as UC9
    usecase "Gerenciar volumes (Master)" as UC10
    usecase "Inicializar schema do Metastore" as UC11
    usecase "Registrar metadados" as UC12

    User --> UC1

    Trino --> UC2
    Trino --> UC3
    Trino --> UC4
    Trino --> UC5
    Trino --> UC6

    Hive --> UC11
    Hive --> UC12

    Seaweed --> UC9
    Seaweed --> UC10

    K8s --> UC7
    K8s --> UC8

    PG --> UC12

    UC1 ..> UC2 : include
    UC2 ..> UC3 : include
    UC3 ..> UC4 : include
    UC3 ..> UC5 : include
    UC6 ..> UC12 : include
    UC7 ..> UC8 : include
```

## Caso não faça sentido o K8 ao seu projeto:

### 1. Remover do ansible/enventory/hosts.ini  
```bash
[k8s]
k8s-node ansible_host=192.168.56.103 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/k8s-node/virtualbox/private_key
```

### 2. Remover do ansible/playbook.yml
```bash
- name: "Configuração do Nó Kubernetes (VM 3)"
  hosts: k8s
  become: yes
  roles:
    - role: k8s-seaweed-csi
      tags: k8s-seaweed-csi
```

### 3. Remover do `Vagrantefile`
```bash
# VM 3: Kubernetes Node (K3s)
  config.vm.define "k8s-node" do |node|
    node.vm.box = "ubuntu/focal64"
    node.vm.hostname = "k8s-node"
    node.vm.network "private_network", ip: "192.168.56.103"
    node.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
      vb.name = "k8s-node"
    end
  end
```

### 4. Remover do `setup.sh` apenas o ***"k8s-node:key_k8s"*** do `for` de dentro do loop.
```bash
# Adicionei a VM3 (k8s-node) que planejamos anteriormente na lista
for VM in "seaweedfs-node:key_seaweed" "trino-sea-node:key_trino" "k8s-node:key_k8s"; do
  VM_NAME="${VM%%:*}"
  KEY_NAME="${VM##*:}"
  DEST="$SSH_DIR/$KEY_NAME"
  ```

## Outros comandos

### Utilizando TAGs
```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbook.yml --tags "seaweed"

# ou

./setup.sh --tags seaweed
```