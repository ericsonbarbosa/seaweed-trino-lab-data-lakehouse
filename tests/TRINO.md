# 🚀 Guia de Testes de Integração e Sistema: Ecossistema Big Data
## SeaweedFS | Hive | Trino

Este documento fornece as instruções passo a passo para acessar as plataformas e executar os testes de integração que validam a fluidez dos dados entre o armazenamento (S3), o catálogo de metadados (Hive) e o motor de consulta distribuída (Trino).

---

## Teste 1 - SeaweedFS-Node (Armazenamento e Metadados)
Este nó contém o **S3** e o **Hive Server/Metastore**.

* **Acesso à VM:** 
    ```bash
    vagrant ssh seaweedfs-node
    ```
* **Validar se o Metastore está rodando na 9083 e pronto para receber o Trino:**
    ```bash
    sudo netstat -nlpt | grep 9083
    ```
    *Nota: O comando deve retornar que está ecutando: tcp 0.0.0.0:9083*

## Teste 2 - Trino-Node (Motor de Consulta)
Este nó é responsável pela execução de queries de alta performance sobre os dados do Hadoop.

* **Acesso à VM:**
    ```bash
    vagrant ssh trino-node
    ```
* **Acesso ao Trino CLI:**
    ```bash
    trino --catalog hive --schema default
    ```
    *Nota: O Trino utiliza conectores para "enxergar" o catálogo do Hive e os arquivos físicos no HDFS.*

---

### ✅ Passo A: Escrita e Consulta via Trino CLI
Objetivo: Validar se o Trino consegue ler do Hive e criar novos arquivos no S3. No `Trino CLI`, execute:

```sql
-- 1. Criar um schema (banco de dados) no catálogo do Hive
CREATE SCHEMA hive.lab_ed;

-- 2. Criar a tabela
CREATE TABLE hive.lab_ed.usuarios (
    id BIGINT, nome VARCHAR, cargo VARCHAR
) WITH (format = 'PARQUET');

-- 3. Inserir os dados (Este é o momento da verdade!)
INSERT INTO lab_ed.usuarios VALUES (1, 'Ericson', 'Data Engineer'), (2, 'Ana Vitória', 'Little Artist');

-- 4. Consultar os dados
SELECT * FROM lab_ed.usuarios;

-- 5. Visualizar todas as tabelas criadas dento do lab_ed.db
SHOW TABLES FROM lab_ed;
```

### ✅ Passo B: – Verificar a gravação dos dados no SeaweedFS S3
Liste o conteúdo do bucket diretamente no S3:
```bash
# Usando AWS CLI recursivo
AWS_ACCESS_KEY_ID=admin AWS_SECRET_ACCESS_KEY=admin_secret aws --endpoint-url http://192.168.56.101:8333 s3 ls s3://warehouse/ --recursive

# Ou via curl no endpoint REST (listagem simples)
http://192.168.56.101:8888/buckets/warehouse/
```

### ✅ Passo C: – Validar as tabelas do Metastore no PostgreSQL
Conecte‑se ao PostgreSQL e verifique se as informações da tabela criada foram registradas:

```bash
sudo -u postgres psql -d metastore -c "SELECT t.\"TBL_NAME\", d.\"NAME\" FROM \"TBLS\" t JOIN \"DBS\" d ON t.\"DB_ID\" = d.\"DB_ID\";"
```
Saída esperada:

```text
  tabela  | banco
----------+---------
 usuarios | lab_ed
```

## 🧹 Limpeza do labratório

```sql
-- 1. Exclusão do schema
DROP SCHEMA IF EXISTS hive.lab_ed CASCADE;

-- 2. Conferir exclusão do schema, deve retornar (0 rows)
SHOW TABLES;
```