# Testes Essenciais do Hive Metastore + Hadoop com Armazenamento S3 (SeaweedFS)

Este documento descreve uma sequência de testes para verificar a correta instalação e configuração do Hive Metastore, sua comunicação com o PostgreSQL e a capacidade de ler/escrever dados no bucket S3 do SeaweedFS.

## Pré‑requisitos

- VM `seaweedfs-node` em execução.
- Serviços ativos: SeaweedFS S3 (porta 8333), PostgreSQL (porta 5432) e Hive Metastore (porta 9083).
- Bucket `warehouse` já criado (o playbook da role `hive` já faz isso via AWS CLI).
- O cliente Hive CLI apresenta um erro (`ClassCastException`) com Java 11. Para corrigi‑lo, execute uma única vez:

```bash
sudo sed -i 's/exec "\$JAVA" \$HADOOP_OPTS/exec "\$JAVA" -Djava.system.class.loader=com.google.common.reflect.ReflectionClassLoader \$HADOOP_OPTS/' /opt/hive/bin/hive
```

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

## Teste 3 – Criar uma tabela externa no bucket S3 e inserir dados

```bash
# Acesse o cliente Hive
/opt/hive/bin/hive
```
Dentro do shell do Hive, execute:
```sql
-- Criar base de dados no warehouse
CREATE DATABASE IF NOT EXISTS testdb
LOCATION 's3a://warehouse/testdb/';

-- Usar a base criada
USE testdb;

-- Criar tabela externa particionada
CREATE EXTERNAL TABLE IF NOT EXISTS vendas (
    id INT,
    produto STRING,
    valor DOUBLE
)
PARTITIONED BY (dt STRING)
STORED AS PARQUET
LOCATION 's3a://warehouse/testdb/vendas';

-- Adicionar uma partição
ALTER TABLE vendas ADD PARTITION (dt='2026-05-05');

-- Inserir dados de exemplo
INSERT INTO vendas PARTITION (dt='2026-05-05')
VALUES (1, 'Notebook', 2500.00), (2, 'Mouse', 45.90);

-- Consultar os dados
SELECT * FROM vendas;
```
Saída esperada:
```text
1   Notebook    2500.0   2026-05-05
2   Mouse       45.9     2026-05-05
```
## Teste 4 – Verificar a gravação dos dados no SeaweedFS S3
Liste o conteúdo do bucket diretamente no S3:
```bash
# Usando AWS CLI recursivo
aws --endpoint-url http://192.168.56.101:8333 s3 ls s3://warehouse/testdb/vendas/dt=2026-05-05/ --recursive

# Ou via curl no endpoint REST (listagem simples)
curl http://192.168.56.101:8333/warehouse/testdb/vendas/dt=2026-05-05/
O resultado deve mostrar um ou mais arquivos Parquet (ex: 000000_0).
```

## Teste 5 – Validar as tabelas do Metastore no PostgreSQL
Conecte‑se ao PostgreSQL e verifique se as informações da tabela criada foram registradas:

```bash
sudo -u postgres psql -d metastore -c "SELECT TBL_NAME, DB_NAME FROM TBLS JOIN DBS ON TBLS.DB_ID = DBS.DB_ID;"
```
Saída esperada:

```text
 tbl_name | db_name
----------+---------
 vendas   | testdb
Limpeza (opcional)
```
## Após os testes, remova os recursos criados:

```bash
/opt/hive/bin/hive -e "DROP DATABASE testdb CASCADE;"
aws --endpoint-url http://192.168.56.101:8333 s3 rm s3://warehouse/testdb/ --recursive
```
| Teste | Objetivo | Critério de sucesso |
|-------|----------|----------------------|
| 1 | Bucket S3 existe | `warehouse` listado |
| 2 | Metastore acessível | Conexão TCP bem‑sucedida |
| 3 | Cliente Hive funcional | `hive` CLI inicia sem `ClassCastException` |
| 4 | Criação/inserção de dados | Comandos SQL executados sem erro |
| 5 | Persistência no S3 | Arquivos Parquet visíveis no bucket |
| 6 | Metadados no PostgreSQL | Tabela `vendas` associada à base `testdb` | 