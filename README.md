### Ambiente WSL - Passar as chaves SSH do .vagrant(Windows) para o WSL(Linux)

Automatizamos com a execução da task 2 (dois) do setup.sh. A mesma deve ser ajustada (corrija o nome do usuário WSL) ou comentada (caso esteja rodando no Linux puro).

Local: setup.sh/ # 2. Verificação e atualização das chaves SSH para dentro do WSL.
Ex: DEST="/home/AJUSTE_AQUI/.ssh/seaweed_lab/$KEY_NAME"

---

## Verificação dos serviços SeaweedFS

Abra o seu navegador no Windows e acesse:  

Painel do Master: http://192.168.56.101:9333  (status do cluster e quantos "Volumes" estão ativos.)
Interface do Filer: http://192.168.56.101:8888  (Este é o seu "Google Drive" interno)  
S3 Gateway: http://192.168.56.101:8333 (Deve retornar uma mensagem XML)  