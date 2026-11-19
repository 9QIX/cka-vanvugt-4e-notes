# Lab 02 · Gateway API (HTTP, then TLS)

## 0 · Install a controller (lab only; the exam has one ready)

```bash
bash lab-setup/scripts/install-gateway-controller.sh
kubectl get gatewayclass                      # "nginx" should be Accepted: True
kubectl api-resources --api-group=gateway.networking.k8s.io
```

Re-create the lab app if you deleted it: `kubectl apply -f 03-networking/manifests/01-apples-and-services.yaml`.

## 1 · HTTP Gateway + HTTPRoute

```bash
cd 03-networking/manifests
kubectl apply -f 03-gateway-http.yaml
kubectl get gateway,httproute
kubectl describe gateway fruit-gw              # wait for Programmed: True
```

The controller creates a data-plane Service for the Gateway. Find its exact name, then test with port-forward:

```bash
kubectl get svc                                # look for the Service owned by fruit-gw (e.g. fruit-gw-nginx)
kubectl port-forward svc/fruit-gw-nginx 8080:80 &       # use the name you just found
curl -H 'Host: my.fruit' http://127.0.0.1:8080/
kill %1
```

## 2 · Add TLS

```bash
openssl req -x509 -nodes -newkey rsa:2048 -days 30 -keyout /tmp/tls.key -out /tmp/tls.crt \
  -subj "/CN=my.fruit" -addext "subjectAltName=DNS:my.fruit"
kubectl create secret tls fruit-tls --cert=/tmp/tls.crt --key=/tmp/tls.key

kubectl apply -f 04-gateway-tls.yaml
kubectl describe gateway fruit-gw-tls          # Programmed: True, listener ResolvedRefs: True

kubectl get svc                                # find the Service for fruit-gw-tls
kubectl port-forward svc/fruit-gw-tls-nginx 8443:443 &
curl -k --resolve my.fruit:8443:127.0.0.1 https://my.fruit:8443/
kill %1
rm -f /tmp/tls.key /tmp/tls.crt                # never commit or keep private keys around
```

## 3 · Read the status, it tells you what is wrong

```bash
kubectl describe httproute apples              # Parents -> Accepted / ResolvedRefs conditions
```

| Condition | False means |
|---|---|
| `Accepted` (Gateway/Route) | the controller rejected it: wrong `gatewayClassName`, `parentRefs`, or hostname mismatch |
| `ResolvedRefs` | a `backendRef` Service or a TLS `Secret` does not exist |
| `Programmed` | the data plane is not ready yet |

## Compare with Ingress

| Ingress | Gateway API |
|---|---|
| `Ingress.spec.rules[].host` | `Gateway.spec.listeners[].hostname` and `HTTPRoute.spec.hostnames` |
| `Ingress.spec.tls[].secretName` | `Gateway.spec.listeners[].tls.certificateRefs` |
| `ingressClassName` | `gatewayClassName` |
| rule path → backend | `HTTPRoute.spec.rules[].matches` → `backendRefs` |

## Clean up

```bash
kubectl delete -f 04-gateway-tls.yaml -f 03-gateway-http.yaml
kubectl delete secret fruit-tls
```

## Done when

- [ ] HTTP and HTTPS both answer through a Gateway.
- [ ] You can read `kubectl describe gateway/httproute` conditions to find out why a route is not working.
