# Testes Essenciais do Hive Metastore + Hadoop com Armazenamento S3 (SeaweedFS)

Este documento descreve uma sequência de testes para verificar a correta instalação e configuração do Hive Metastore, sua comunicação com o PostgreSQL e a capacidade de ler/escrever dados no bucket S3 do SeaweedFS.

## Pré‑requisitos

- VM `seaweedfs-node` em execução.
- Serviços ativos: SeaweedFS S3 (porta 8333), PostgreSQL (porta 5432) e Hive Metastore (porta 9083).
- Bucket `warehouse` já criado (o playbook da role `hive` já faz isso via AWS CLI).

## Teste 1 – Verificar o bucket S3 no SeaweedFS

```bash
# Listar buckets via AWS CLI (instalado pelo playbook)
AWS_ACCESS_KEY_ID=admin AWS_SECRET_ACCESS_KEY=admin_secret aws --endpoint-url http://192.168.56.101:8333 s3 ls

# Saída esperada: 
# 2026-05-05 19:20:15 warehouse
```

## Teste 2 – Verificar a conectividade com o Hive Metastore (porta 9083)

```bash
# Teste simples de conexão TCP
nc -zv 192.168.56.101 9083

#Saída esperada: 
#Connection to 192.168.56.101 port 9083 [tcp/*] succeeded!
```