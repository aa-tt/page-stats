## Steps to bring the app up on Rancher Desktop
**kind** is not needed in this case, as Rancher provides **k3s** where kubernetes cluster can be created, as with kind in docker

1. **Configure Rancher Desktop**
Open Rancher Desktop → Preferences:

Container Engine → select `containerd`
Kubernetes → enable, pick a recent stable version (1.28+)
Apply & wait for the green Ready status

2. **Verify kubectl points to Rancher Desktop**
```
kubectl config current-context
# Should show: rancher-desktop
kubectl get nodes
# Should show a Ready node
```

3. **Apply the manifest**
```
kubectl apply -f /Users/aa/code/page-stats/kind-zenoptics-app.yaml
```

4. **Watch pods come up (run in a separate terminal)**
```
kubectl get pods -n zenoptics -w
```

Expected startup order (takes ~2-3 min total):
1. `zookeeper-0` → Running
2. `kafka-0` → Running (waits for zookeeper)
3. `influxdb-*`, `postgres-*` → Running
4. `create-kafka-topic` Job → Completed (may retry a few times waiting for kafka)
5. `ingest-service-*`, `processing-service-*` → Running
6. `nginx-*` → Running

5. **Verify kafka topic was created**
```
kubectl logs -n zenoptics job/create-kafka-topic
kubectl logs -n zenoptics job/verify-kafka-topic
```
Should show `page_view_events` listed.

6. **Check all pods are healthy**
```
kubectl get all -n zenoptics
```

7. **Access the app**
On Rancher Desktop (k3s), `LoadBalancer` services get `127.0.0.1` automatically — no tunnel needed:
```
kubectl get svc nginx -n zenoptics
# EXTERNAL-IP should show 127.0.0.1
```
Then open: http://localhost
If EXTERNAL-IP stays `<pending>`, fall back to port-forward:
```
kubectl port-forward svc/nginx 8080:80 -n zenoptics
# Then open: http://localhost:8080
```

**Useful debug commands**
```
# Logs for any service
kubectl logs -n zenoptics deployment/ingest-service
kubectl logs -n zenoptics deployment/processing-service
kubectl logs -n zenoptics statefulset/kafka
kubectl logs -l app=consolidator-service -n zenoptics --tail=100 -f 

# Describe a pod that's not starting
kubectl describe pod -n zenoptics <pod-name>

# Restart a deployment
kubectl rollout restart deployment/ingest-service -n zenoptics

# Tear everything down
kubectl delete namespace zenoptics
```