# Kind Cluster Configuration Guide

This guide provides detailed instructions for setting up and configuring a Kind cluster with advanced features including Calico CNI, Volcano Scheduler, and MetalLB LoadBalancer.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Creating the Kind Cluster](#creating-the-kind-cluster)
3. [Installing Calico CNI](#installing-calico-cni)
4. [Configuring Volcano Scheduler](#configuring-volcano-scheduler)
5. [Setting Up MetalLB LoadBalancer](#setting-up-metallb-loadbalancer)
6. [Example Usage](#example-usage)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

- Docker installed
- Kind installed
- kubectl installed
- Basic understanding of Kubernetes concepts

## Creating the Kind Cluster

First, create the Kind cluster using the provided configuration file:

```bash
kind create cluster --config=/home/crochee/.dotfiles/k8scnf/kind-cluster-config.yaml
```

## Installing Calico CNI

The cluster is configured to use Calico as the CNI plugin. Install Calico with the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/calico.yaml
```

### Why Calico?

- **Production-ready**: Calico is used in thousands of production environments
- **Advanced network policies**: Fine-grained control over traffic flow
- **High performance**: Efficient networking with low overhead
- **Dual-stack support**: Works with both IPv4 and IPv6
- **Integration**: Seamlessly integrates with Kubernetes

### Verifying Calico Installation

```bash
# Check Calico pods
kubectl get pods -n calico-system

# Check node status
kubectl get nodes
```

## Configuring Volcano Scheduler

Volcano is a batch scheduler for Kubernetes that excels at managing AI/ML, big data, and high-performance computing workloads.

### Installation

```bash
kubectl apply -f https://raw.githubusercontent.com/volcano-sh/volcano/master/installer/volcano-development.yaml
```

### Verifying Volcano Installation

```bash
kubectl get pods -n volcano-system
```

### Using Volcano Scheduler

To use Volcano scheduler for specific workloads, add `schedulerName: volcano` to your pod spec:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      schedulerName: volcano  # Use Volcano scheduler
      containers:
      - name: my-app
        image: my-app:latest
```

### Advanced Configuration

For automatic scheduler assignment, configure the Volcano admission webhook:

```bash
kubectl edit configmap volcano-admission-configmap -n volcano-system
```

Uncomment and modify the relevant sections to match your requirements:

```yaml
resourceGroups:
- resourceGroup: cpu
  object:
    key: annotation
    value:
    - "volcano.sh/resource-group: cpu"
  schedulerName: volcano
  labels:
    volcano.sh/nodetype: cpu
```

## Setting Up MetalLB LoadBalancer

MetalLB provides LoadBalancer services for bare-metal Kubernetes clusters, including Kind.

### Why MetalLB?

- **Production-ready**: Enterprise-grade features
- **Simple configuration**: Easy to set up and manage
- **Dual-mode support**: Works in both L2 and BGP modes
- **Cross-platform**: Compatible with various Kubernetes distributions
- **Well-documented**: Extensive documentation and community support

### Installation

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
```

### Configuration

1. **Get Kind network CIDR**: First, identify your Kind network's subnet
   ```bash
docker network inspect kind | grep Subnet
   ```

2. **Create IP address pool**: Define a range of IP addresses for MetalLB to use
   ```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.18.255.200-172.18.255.250  # Use an IP range from your Kind network
   ```

3. **Configure L2 advertisement**: Tell MetalLB to advertise the IP pool using L2 mode
   ```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
   ```

### Creating a LoadBalancer Service

Now you can create LoadBalancer services that will automatically get external IPs from MetalLB:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

### Verifying LoadBalancer IP Assignment

```bash
kubectl get svc nginx-lb
```

Expected output:
```
NAME       TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)        AGE
nginx-lb   LoadBalancer   10.96.123.45    172.18.255.200    80:31234/TCP   1m
```

### Accessing the Service

You can now access the service from your local machine using the external IP:

```bash
curl http://172.18.255.200
```

## Example Usage

### Complete Workflow

1. **Create the Kind cluster**: 
   ```bash
   kind create cluster --config=/home/crochee/.dotfiles/k8scnf/kind-cluster-config.yaml
   ```

2. **Install Calico**: 
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/calico.yaml
   ```

3. **Install Volcano**: 
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/volcano-sh/volcano/master/installer/volcano-development.yaml
   ```

4. **Install MetalLB**: 
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
   ```

5. **Configure MetalLB IP pool**: 
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: metallb.io/v1beta1
   kind: IPAddressPool
   metadata:
     name: first-pool
     namespace: metallb-system
   spec:
     addresses:
     - 172.18.255.200-172.18.255.250
   EOF
   ```

6. **Configure L2 advertisement**: 
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: metallb.io/v1beta1
   kind: L2Advertisement
   metadata:
     name: example
     namespace: metallb-system
   spec:
     ipAddressPools:
     - first-pool
   EOF
   ```

7. **Deploy a test application**: 
   ```bash
   kubectl create deployment nginx --image=nginx
   ```

8. **Expose with LoadBalancer**: 
   ```bash
   kubectl expose deployment nginx --port=80 --type=LoadBalancer
   ```

9. **Access the application**: 
   ```bash
   curl $(kubectl get svc nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   ```

## Troubleshooting

### Common Issues

1. **Calico pods not starting**: 
   - Check if the cluster has the correct pod CIDR
   - Verify Docker network connectivity
   - Review Calico logs: `kubectl logs -n calico-system <pod-name>`

2. **Volcano scheduler not being assigned**: 
   - Ensure `schedulerName: volcano` is correctly added to pod spec
   - Check Volcano pods are running: `kubectl get pods -n volcano-system`
   - Verify admission webhook configuration

3. **MetalLB not assigning IPs**: 
   - Ensure the IP pool range is within your Kind network
   - Check MetalLB controller logs: `kubectl logs -n metallb-system <controller-pod>`
   - Verify L2 advertisement configuration

4. **LoadBalancer service pending**: 
   - Wait a few minutes for MetalLB to assign an IP
   - Check if MetalLB is installed correctly
   - Verify IP pool configuration

### Useful Commands

```bash
# Check cluster status
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check pod status in all namespaces
kubectl get pods -A

# Check service details
kubectl describe svc <service-name>

# Check logs for a specific pod
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Conclusion

This guide has provided detailed instructions for setting up a Kind cluster with Calico CNI, Volcano Scheduler, and MetalLB LoadBalancer. These components work together to create a powerful, production-ready Kubernetes environment for development and testing.

By following this guide, you can:
- Create a multi-node Kind cluster
- Implement robust network policies with Calico
- Leverage advanced scheduling capabilities with Volcano
- Expose services externally using MetalLB LoadBalancer

This setup provides an excellent foundation for testing and developing Kubernetes applications that require advanced networking and scheduling features.