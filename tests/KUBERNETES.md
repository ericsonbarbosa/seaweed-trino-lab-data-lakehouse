## Teste de integração SeaweedFS + Kubernetes
### 1. Entre na VM3 k8s-node
```bash
vagrant ssh k8s-node
```

### 2. Verificar a Saúde dos PODs e o apontamento seaweedfs-storage:
```bash
sudo k3s kubectl get sc,pods -n kube-system
```

Retorno esperado:  
***storageclass.storage.k8s.io/seaweedfs-storage (default)***

Pods do seaweed-csi-driver (geralmente um controller e um node) com o status Running:  
***pod/seaweedfs-csi-controller-66fd64d57b-tn88k   5/5     Running     5 (21h ago)   22h***   
***pod/seaweedfs-csi-node-ktvdr                    3/3     Running     4 (38m ago)   22h***   

### 3. Realizaremos os testes de Escrita e Lakehouse

3.1 Vamos criar e aplicar automaticamente um manifesto YAML com as seguintes características:

1. Um PVC chamado pvc-teste-lakehouse solicitando 1 GiB de armazenamento da classe seaweedfs-storage.

2. Um Pod chamado pod-teste-escrita que monta esse PVC em /mnt/lakehouse e escreve um arquivo status.txt dentro do volume.
```bash
sudo k3s kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-teste-lakehouse
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: seaweedfs-storage
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-teste-escrita
spec:
  containers:
  - name: worker
    image: alpine
    command: ["/bin/sh", "-c"]
    args: ["echo 'Integracao K3s SeaweedFS' > /mnt/lakehouse/status.txt && sync; sleep 3600"]
    volumeMounts:
    - name: storage-seaweed
      mountPath: /mnt/lakehouse
  volumes:
  - name: storage-seaweed
    persistentVolumeClaim:
      claimName: pvc-teste-lakehouse
EOF
```
### 4. Aguarde o POD subir e verifique:
```bash
sudo k3s kubectl get pvc pvc-teste-lakehouse
```

```bash
sudo k3s kubectl get pod pod-teste-escrita
```
Retorno esperado:  
***PVC Bound e Pod Running***

### 5. Por fim, vamos verificar a leitura do arquvo:
```bash
sudo k3s kubectl exec pod-teste-escrita -- cat /mnt/lakehouse/status.txt
```
Retorno esperado:  
***Integracao K3s SeaweedFS***

### 6. Vá na seaweedfs-node e verifique o volume shell:
```bash
# Na VM1 (SeaweedFS)
echo "ls /" | weed shell -master=localhost:9333
```
ou http://192.168.56.101:8888/  

Retorno esperado:  
***buckets***  
***topics***  
