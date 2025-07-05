## Ensure deployment is evenly distributed across cluster

#### Kubernetes provides mechanisms to ensure even distribution of workloads across cluster 

- [Pod Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)

    You can use topology spread constraints to control how Pods are spread across your cluster among failure-domains such as regions, zones, nodes, and other user-defined topology domains. This can help to achieve high availability as well as efficient resource utilization.

- [Comparison with podAffinity and podAntiAffinity](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/#comparison-with-podaffinity-podantiaffinity)

    In Kubernetes, inter-Pod affinity and anti-affinity control how Pods are scheduled in relation to one another - either more packed or more scattered.

    - `podAffinity` attracts Pods; you can try to pack any number of Pods into qualifying topology domain(s).
    - `podAntiAffinity` repels Pods. If you set this to requiredDuringSchedulingIgnoredDuringExecution mode then only a single Pod can be scheduled into a single topology domain; if you choose preferredDuringSchedulingIgnoredDuringExecution then you lose the ability to enforce the constraint.

- [Affinity and anti-affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)

    Affinity and anti-affinity expand the types of constraints you can define.

    Some of the benefits of affinity and anti-affinity include:

    - The affinity/anti-affinity language is more expressive. nodeSelector only selects nodes with all the specified labels. Affinity/anti-affinity gives you more control over the selection logic.

    - You can indicate that a rule is soft or preferred, so that the scheduler still schedules the Pod even if it can't find a matching node.

    - You can constrain a Pod using labels on other Pods running on the node (or other topological domain), instead of just node labels, which allows you to define rules for which Pods can be co-located on a node.

    ##### E.g.: [topology spread constrains with node affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/#example-topologyspreadconstraints-with-nodeaffinity)