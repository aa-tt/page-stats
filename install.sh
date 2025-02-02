kind create cluster --name zenoptics-cluster
kubectl cluster-info --context kind-zenoptics-cluster
kubectl config set-context kind-zenoptics-cluster

kubectl apply -f kubernetes-dashboard.yaml 
kubectl apply -f dashboard-adminuser.yaml
kubectl create serviceaccount dashboard-admin-sa --namespace kube-system
kubectl -n kube-system create token dashboard-admin-sa
kubectl proxy
# Starting to serve on 127.0.0.1:8001
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/replicaset?namespace=zenoptics

kubectl apply -f kind-zenoptics-app.yaml
kubectl get pods -n zenoptics
# Debug logs
# kubectl logs kafka-0 -n zenoptics
# ERROR: Missing environment variable KAFKA_LISTENERS. Must be specified when using KAFKA_ADVERTISED_LISTENERS
# kubectl delete statefulset kafka -n zenoptics
# kubectl apply -f kind-zenoptics-app.yaml

# More Debug logs
# troubleshoot postgresql
## kubectl run -i --tty --rm debug --image=postgres --namespace=zenoptics -- bash
## psql -h postgres -U your-username -d zenopticsdb
# Caused by: java.net.UnknownHostException: postgres
## kubectl run -i --tty --rm debug --image=busybox --namespace=zenoptics -- sh
## / # nslookup postgres
###Server:		10.96.0.10
###Address:	10.96.0.10:53
###** server can't find postgres.svc.cluster.local: NXDOMAIN
###** server can't find postgres.cluster.local: NXDOMAIN
###Name:	postgres.zenoptics.svc.cluster.local
###Address: 10.96.246.78
#kubectl get pods -n zenoptics
##NAME                             READY   STATUS    RESTARTS       AGE
##ingest-service-f8fdb74d6-8j27z   0/1     Error     0              34s
## kubectl logs ingest-service-f8fdb74d6-8j27z -n zenoptics
###no main manifest attribute, in ingest-service.jar
#### configure mainClass in pom.xml spring-boot-maven-plugin
#### kubectl delete deployment ingest-service -n zenoptics
#### kubectl apply -f kind-zenoptics-app.yaml
#### kubectl rollout restart deployment ingest-service -n zenoptics
# use nodeport in ingest-service to expose the service -> type: NodePort, nodePort: 30080 -> kubectl get nodes -o wide -> http://192.168.99.100:30080
# kubectl port-forward svc/ingest-service 30080:80 -n zenoptics -> http://127.0.0.1:30080/aggregated-data/region-weekly?region=us-west&startTime=2023-01-01&endTime=2023-01-07
# kubectl logs -l app=ingest-service -n zenoptics --tail=100 -f
# for local build images -> kind load docker-image ingest-service:local
# curl -X GET "http://127.0.0.1:30080/aggregated-data/region-weekly?region=us-west&startTime=2023-01-01&endTime=2023-01-07"
# curl -X POST "http://127.0.0.1:30080/page-view" -H "Content-Type: application/json" -d '{"pageName": "HomePage","region": "us-west","timestamp": "2023-01-01T00:00:00"}'

# Debugging Kafka
# Error while fetching metadata with correlation id 1 : {page_view_events=INVALID_REPLICATION_FACTOR}
## This typically happens when the replication factor is set to a value greater than the number of available Kafka brokers.
## kubectl run kafka-client --rm -i --tty --image=confluentinc/cp-kafka -- bash
## [appuser@kafka-client ~]$ kafka-topics --create --topic page_view_events --bootstrap-server kafka.zenoptics.svc.cluster.local:9092 --replication-factor 1 --partitions 1
## [appuser@kafka-client ~]$ kafka-topics --describe --topic page_view_events --bootstrap-server kafka.zenoptics.svc.cluster.local:9092
## [appuser@kafka-client ~]$ kafka-topics --list --bootstrap-server kafka.zenoptics.svc.cluster.local:9092
### page_view_events
## [appuser@kafka-client ~]$ kafka-topics --describe --topic page_view_events --bootstrap-server kafka.zenoptics.svc.cluster.local:9092
###[2025-02-01 18:23:02,490] WARN [AdminClient clientId=adminclient-1] The DescribeTopicPartitions API is not supported, using Metadata API to describe topics. (org.apache.kafka.clients.admin.KafkaAdminClient)
###Topic: page_view_events	TopicId: 8aTzWcPqRg2lkTG8dZiWUQ	PartitionCount: 1	ReplicationFactor: 1	Configs: segment.bytes=1073741824
###	Topic: page_view_events	Partition: 0	Leader: 0	Replicas: 0	Isr: 0	Elr: N/A	LastKnownElr: N/A
# curl -X POST "http://127.0.0.1:30080/page-view" -H "Content-Type: application/json" -d '{"pageName": "ContactPage","region": "us-west","timestamp": "2023-01-03T00:00:00"}'
## [appuser@kafka-client ~]$ kafka-console-consumer --bootstrap-server kafka.zenoptics.svc.cluster.local:9092 --topic page_view_events --from-beginning
### {"pageName":"ContactPage","region":"us-west","timestamp":"2023-01-02T00:00:00"}
### {"pageName":"ContactPage","region":"us-west","timestamp":"2023-01-03T00:00:00"}

# Debugging InfluxDB
## kubectl run -i --tty --rm debug --image=busybox --namespace=zenoptics -- sh
### / # nslookup influxdb
#### Name:	influxdb.zenoptics.svc.cluster.local 
#### Address: 10.96.207.157
## kubectl run influxdb-client --rm -i --tty --image=influxdb:latest -- bash
## root@influxdb-client:/# influx setup --username your-username --password your-password --org your-org --bucket page_view_bucket --token your-influxdb-token --host http://influxdb.zenoptics.svc.cluster.local:8086 --force
## root@influxdb-client:/# influx write --bucket page_view_bucket --org your-org --token your-influxdb-token --precision s 'page_views,pageName=HomePage,region=us-west visits=100'
### Error: failed to write data: Post "http://localhost:8086/api/v2/write?bucket=page_view_bucket&org=your-org&precision=s": dial tcp [::1]:8086: connect: connection refused
## root@influxdb-client:/# export INFLUX_HOST=http://influxdb.zenoptics.svc.cluster.local:8086
## root@influxdb-client:/# influx write --bucket page_view_bucket --org your-org --token your-influxdb-token --precision s 'page_views,pageName=HomePage,region=us-west visits=100'
## root@influxdb-client:/# influx query 'from(bucket:"page_view_bucket") |> range(start: -1h)' --org your-org --token your-influxdb-token
###Result: _result
###Table: keys: [_start, _stop, _field, _measurement, pageName, region]
###                   _start:time                      _stop:time           _field:string     _measurement:string         pageName:string           region:string                      _time:time                  _value:float
###------------------------------  ------------------------------  ----------------------  ----------------------  ----------------------  ----------------------  ------------------------------  ----------------------------
###2025-02-01T18:06:53.163829980Z  2025-02-01T19:06:53.163829980Z                  visits              page_views                HomePage                 us-west  2025-02-01T19:06:46.000000000Z
## root@influxdb-client:/# influx query 'from(bucket:"page_view_bucket") |> range(start: 2023-01-10T00:00:00Z, stop: 2023-01-13T00:00:00Z)' --org your-org --token your-influxdb-token

# Debugging Processing Service
## Use below command to skip push docker images to docker hub. this loads the local docker image to kind cluster
## kind load docker-image ianunay/processor:v2 --name zenoptics-cluster
### Image: "ianunay/processor:v2" with ID "sha256:5c93394e225c3af59311cdbdde39cbdf1c32973447cff7000bd1bebe887bce0c" not yet present on node "zenoptics-cluster-control-plane", loading...
# kubectl logs -l app=processing-service -n zenoptics --tail=100 -f
## INFO:__main__:Starting processing-service...
## INFO:__main__:Using Kafka consumer group ID: processing-service-group-df2ec7f4-db94-4aa1-aa4f-3c28dcd50bbc
## INFO:__main__:Kafka consumer subscribed to topic 'page_view_events'.
## INFO:__main__:Consumed from Kafka: {'pageName': 'ContactPage', 'region': 'us-west', 'timestamp': '2023-01-02T00:00:00'}
## INFO:__main__:Written to InfluxDB: {'pageName': 'ContactPage', 'region': 'us-west', 'timestamp': '2023-01-02T00:00:00'}
## INFO:__main__:Starting processing-service...
## INFO:__main__:Using Kafka consumer group ID: processing-service-group-2ba4730c-8c4a-40cc-a75c-d6c8375cfe7f
## INFO:__main__:Kafka consumer subscribed to topic 'page_view_events'.
## INFO:__main__:Consumed from Kafka: {'pageName': 'ContactPage', 'region': 'us-west', 'timestamp': '2023-01-02T00:00:00'}
## INFO:__main__:Written to InfluxDB: {'pageName': 'ContactPage', 'region': 'us-west', 'timestamp': '2023-01-02T00:00:00'}

# Debugging Consolidation Service - running as cron jobs
## kubectl get cronjobs -n zenoptics
## kubectl get jobs -n zenoptics
## kubectl get pods -n zenoptics
## kubectl logs -l app=consolidation-service -n zenoptics --tail=100 -f


# Kubernetes
kubectl get all -n zenoptics
NAME                                      READY   STATUS      RESTARTS   AGE
pod/consolidator-service-28975290-wzncc   0/1     Completed   0          16m
pod/consolidator-service-28975305-s47h7   0/1     Completed   0          97s
pod/create-kafka-topic-4rtzg              0/1     Completed   0          122m
pod/influxdb-6544b57df5-x4x4c             1/1     Running     0          122m
pod/ingest-service-588f7b49d7-kdhc8       1/1     Running     0          122m
pod/kafka-0                               1/1     Running     0          122m
pod/nginx-6f56f7cd78-dsd2n                1/1     Running     0          122m
pod/postgres-57d656977c-4tc7x             1/1     Running     0          122m
pod/processing-service-7b9f9f7846-wxb5c   1/1     Running     0          122m
pod/verify-kafka-topic-tc44p              0/1     Completed   0          122m
pod/zookeeper-0                           1/1     Running     0          122m

NAME                         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/influxdb             ClusterIP      10.96.40.252    <none>        8086/TCP       122m
service/ingest-service       ClusterIP      10.96.192.152   <none>        8080/TCP       122m
service/kafka                ClusterIP      10.96.91.74     <none>        9092/TCP       122m
service/nginx                LoadBalancer   10.96.139.40    <pending>     80:31023/TCP   122m
service/postgres             ClusterIP      10.96.65.44     <none>        5432/TCP       122m
service/processing-service   ClusterIP      10.96.178.5     <none>        5000/TCP       122m
service/zookeeper            ClusterIP      None            <none>        2181/TCP       122m

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/influxdb             1/1     1            1           122m
deployment.apps/ingest-service       1/1     1            1           122m
deployment.apps/nginx                1/1     1            1           122m
deployment.apps/postgres             1/1     1            1           122m
deployment.apps/processing-service   1/1     1            1           122m

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/influxdb-6544b57df5             1         1         1       122m
replicaset.apps/ingest-service-588f7b49d7       1         1         1       122m
replicaset.apps/nginx-6f56f7cd78                1         1         1       122m
replicaset.apps/postgres-57d656977c             1         1         1       122m
replicaset.apps/processing-service-7b9f9f7846   1         1         1       122m

NAME                         READY   AGE
statefulset.apps/kafka       1/1     122m
statefulset.apps/zookeeper   1/1     122m

NAME                                 SCHEDULE       TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/consolidator-service   */15 * * * *   <none>     False     0        97s             122m

NAME                                      STATUS     COMPLETIONS   DURATION   AGE
job.batch/consolidator-service-28975290   Complete   1/1           21s        16m
job.batch/consolidator-service-28975305   Complete   1/1           22s        97s
job.batch/create-kafka-topic              Complete   1/1           4m41s      122m
job.batch/verify-kafka-topic              Complete   1/1           4m42s      122m

# Kafka-InfluxDB
kubectl logs -l app=processing-service -n zenoptics --tail=100 -f
INFO:__main__:Starting processing-service...
INFO:__main__:Using Kafka consumer group ID: processing-service-group-80032db9-63f7-4c8f-8f5f-4e990cd4e08c
INFO:__main__:Kafka consumer subscribed to topic 'page_view_events'.
INFO:__main__:Consumed from Kafka: {'pageName': 'ContactPage', 'region': 'us-west', 'timestamp': '2023-01-02T00:00:00'}
INFO:__main__:Written to InfluxDB: {'pageName': 'ContactPage', 'region': 'us-west', 'timestamp': '2023-01-02T00:00:00'}
INFO:__main__:Consumed from Kafka: {'pageName': 'HomePage', 'region': 'us-west', 'timestamp': '2025-02-02'}
INFO:__main__:Written to InfluxDB: {'pageName': 'HomePage', 'region': 'us-west', 'timestamp': '2025-02-02'}
INFO:__main__:Consumed from Kafka: {'pageName': 'dashboard', 'region': 'us-west', 'timestamp': '2025-02-02'}
INFO:__main__:Written to InfluxDB: {'pageName': 'dashboard', 'region': 'us-west', 'timestamp': '2025-02-02'}
INFO:__main__:Consumed from Kafka: {'pageName': 'contact', 'region': 'us-west', 'timestamp': '2025-02-02'}

# Spark Job
kubectl logs -l app=consolidator-service -n zenoptics --tail=100 -f
No resources found in zenoptics namespace.
kubectl logs -l app=consolidator-service -n zenoptics --tail=100 -f
SPARK_CLASSPATH: /opt/spark/jars/postgresql-42.2.23.jar
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
25/02/02 01:18:05 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
[Stage 0:>                                                          (0 + 1) / 1]                                                                                

[Stage 6:>                                                          (0 + 8) / 8]

[Stage 6:===================================================>       (7 + 1) / 8]

Initial DataFrame:
+--------+-------+-------------------+------+
|pageName| region|          timestamp|visits|
+--------+-------+-------------------+------+
|HomePage|us-west|2025-02-01 19:06:46| 100.0|
+--------+-------+-------------------+------+

DataFrame with week and year columns:
+--------+-------+-------------------+------+----+----+
|pageName| region|          timestamp|visits|week|year|
+--------+-------+-------------------+------+----+----+
|HomePage|us-west|2025-02-01 19:06:46| 100.0|   5|2025|
+--------+-------+-------------------+------+----+----+

Aggregated DataFrame:
+--------+-------+----+----+------+
|pageName| region|year|week|visits|
+--------+-------+----+----+------+
|HomePage|us-west|2025|   5| 100.0|
+--------+-------+----+----+------+

Final DataFrame with timestamp:
+--------+-------+--------------------+------+
|pageName| region|           timestamp|visits|
+--------+-------+--------------------+------+
|HomePage|us-west|2025-01-26 01:39:...| 100.0|
+--------+-------+--------------------+------+

# cleanup
kind delete cluster --name zenoptics-cluster