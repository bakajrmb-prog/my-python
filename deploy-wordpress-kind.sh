#!/bin/bash
set -e

CLUSTER_NAME="wordpress-cluster"
NAMESPACE="wordpress"

echo "=== Suppression ancien cluster si existe ==="
kind delete cluster --name ${CLUSTER_NAME} >/dev/null 2>&1 || true

echo "=== Création du cluster Kind ==="
kind create cluster --name ${CLUSTER_NAME} --image kindest/node:v1.26.0

echo "=== Attente que le node soit Ready ==="
kubectl wait --for=condition=Ready node --all --timeout=120s

echo "=== Installation Ingress Nginx ==="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml

echo "=== Fix Kind : suppression nodeSelector ==="
kubectl patch deployment ingress-nginx-controller -n ingress-nginx \
  --type='json' \
  -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector"}]'

echo "=== Attente Ingress Nginx ==="
kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "=== Déploiement WordPress ==="
kubectl create namespace ${NAMESPACE} || true

cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:6.4-apache
        ports:
        - containerPort: 80
        env:
        - name: WORDPRESS_DB_HOST
          value: mariadb
        - name: WORDPRESS_DB_USER
          value: wpuser
        - name: WORDPRESS_DB_PASSWORD
          value: wppassword
        - name: WORDPRESS_DB_NAME
          value: wpdatabase
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress
spec:
  selector:
    app: wordpress
  ports:
  - port: 80
EOF

cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:10.6
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: rootpassword
        - name: MYSQL_DATABASE
          value: wpdatabase
        - name: MYSQL_USER
          value: wpuser
        - name: MYSQL_PASSWORD
          value: wppassword
        ports:
        - containerPort: 3306
---
apiVersion: v1
kind: Service
metadata:
  name: mariadb
spec:
  selector:
    app: mariadb
  ports:
  - port: 3306
EOF

echo "=== Création Ingress ==="
cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress
spec:
  ingressClassName: nginx
  rules:
  - host: localhost
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wordpress
            port:
              number: 80
EOF

echo "=== Attente WordPress ==="
kubectl wait -n ${NAMESPACE} \
  --for=condition=Available deployment/wordpress \
  --timeout=180s

echo ""
echo "=============================================="
echo " WordPress est DISPONIBLE sur :"
echo " 👉 http://localhost:8080"
echo "=============================================="

