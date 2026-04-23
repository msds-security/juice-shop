# deploy-wiz-sensor
Jenkins pipeline that installs the Wiz Runtime Sensor (eBPF DaemonSet)
on juice-shop-cluster.
Jobs:
  juice-shop-deploy-wiz-sensor  -> Jenkinsfile
  juice-shop-delete-wiz-sensor  -> Jenkinsfile-delete
Credentials: wizclient, wizsecret (existing Jenkins creds).
Namespace: wiz.
See Jenkinsfile for parameter details.
