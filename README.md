# 1. Criar uma pasta segura para as chaves no seu usuário Linux
mkdir -p ~/.ssh/seaweed_lab

# 2. Copiar as chaves do Windows para essa pasta Linux
cp .vagrant/machines/seaweedfs-node/virtualbox/private_key ~/.ssh/seaweed_lab/key_seaweed
cp .vagrant/machines/trino-sea-node/virtualbox/private_key ~/.ssh/seaweed_lab/key_trino

# 3. DAR A PERMISSÃO CORRETA (Isso agora vai funcionar!)
chmod 600 ~/.ssh/seaweed_lab/key_seaweed
chmod 600 ~/.ssh/seaweed_lab/key_trino