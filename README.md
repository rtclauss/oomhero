# OOMHero

OOMHero is a sidecar that helps you to keep track of your containers memory
usage. By implementing it two signals are going to be send to your container
as the memory usage grows: a _warning_ and a _critical_ signals. By leveraging
these signals you might be able to defeat the deadly `OOMKiller`.

### How it works

This sidecar is tailored for Java workloads and will send your container two signals: 
when memory usage crosses so called _warning_(**SIGQUIT**) and _critical_(**SIGQUIT**) thresholds. 
JVMs, specifically IBM's JVMs, will trigger a variety of heap, thread dumps, javacores, etc. when
a `SIGQUIT` signal is received.

### On limits

If only `requests` are specified during the pod Deployment no signal will be
sent, this sidecar operates only on `limits`.

### Deployment example

The Pod below is composed by two distinct containers, the first one is called
`bloat` and its purpose is(as the name implies) to simulate a memory leak by
constantly allocating in a global variable. The sidecar is an `OOMHero` 
configured to send a `SIGUSR1`(warning) when `bloat` reaches 65% and a `SIGUSR2`
(critical) on 90%. There are two pre-requisites on Amazon EKS:
1. both containers share the same process namespace, hence `shareProcessNamespace` is set to `true`.
2. the oomhero container needs `SYS_PTRACE` capability enabled, as shown below, to allow access to the limits
   of the other containers and to send the signal to the targeted container.


```yaml
apiVersion: v1
kind: Pod
metadata:
  name: oomhero
spec:
  shareProcessNamespace: true
  containers:
    - name: bloat
      image: quay.io/rmarasch/bloat
      imagePullPolicy: Always
      livenessProbe:
        periodSeconds: 3
        failureThreshold: 1
        httpGet:
          path: /healthz
          port: 8080
      resources:
        requests:
          memory: "256Mi"
          cpu: "250m"
        limits:
          memory: "256Mi"
          cpu: "250m"
    - name: oomhero
      image: quay.io/rmarasch/oomhero
      imagePullPolicy: Always
      securityContext:
        capabilities:
          add:
            - SYS_PTRACE
      env:
      - name: WARNING
        value: "65"
      - name: CRITICAL
        value: "90"
```

Saving the above yaml into a file you just need to deploy it:

```bash
$ kubectl create -f ./pod.yaml
```

That will create a Pod with two containers, you may follow the memory consumption
and signals being sent by inspecting all pod logs.

```bash
$ # for bloat container log
$ kubectl logs -f oomhero --container bloat
$ # for oomhero container log
$ kubectl logs -f oomhero --container oomhero 
```

### Help needed

[Official documentation](https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/)
states that `SYS_PTRACE` capability is mandatory when signaling between containers
on the same Pod. I could not validate if this is true as it works without it on my
K8S cluster. If to make it work you had to add this capability please let me know.
