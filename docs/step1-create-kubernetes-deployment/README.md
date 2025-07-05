## Create a Kubernetes deployment using the public Docker image [kennethreitz/httpbin](https://hub.docker.com/r/kennethreitz/httpbin).

- Create and deploy kubernetes deployment object to cluster. 

    Image: [kennethreitz/httpbin](https://hub.docker.com/r/kennethreitz/httpbin)

### How to deploy:

1. Go to [k8s](../../k8s/) folder and run commands listed below.

    to create namespace, run:
    ```sh
    kubectl create namespace httpbin
    ```

    to create deployment object, run:
    ```sh
    kubectl apply -f httpbin.yml -n httpbin
    ```

2. To verify deployment is up & running, run:
    ```sh
    kubectl get po -n httpbin
    ```