#!/bin/bash

function prompt {
  read # Wait for the user to press Enter
  local count=$#
  local i=1

  for str in "$@"; do
    if [ $i -lt $count ]; then
      echo -e "$str"
    else
      echo -n "$str"
    fi
    ((i++))
  done

  read # Wait for the user to press Enter

  echo ""
}

function execute_command {
  echo "$1"
  eval "$1"
  echo ""
}

clear

prompt "Demo of Request Timeout\n" "Kmesh, Istio, Bookinfo and service granularity waypoint for reviews service have been installed\n" "Install waypoint for ratings service"

execute_command "istioctl x waypoint apply -n default --name ratings-svc-waypoint"

execute_command "kubectl label service ratings istio.io/use-waypoint=ratings-svc-waypoint"

execute_command "kubectl annotate gateway ratings-svc-waypoint sidecar.istio.io/proxyImage=ghcr.io/kmesh-net/waypoint:latest"

prompt "Apply application version routing"

execute_command "kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/bookinfo/networking/virtual-service-all-v1.yaml"
  
execute_command "kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml"

prompt "Reque Timeouts\n" "Route requests to v2 of the reviews service, i.e., a version that calls the ratings service"

kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
EOF

prompt "Add a 2 second delay to calls to the ratings service"

kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percentage:
          value: 100
        fixedDelay: 2s
    route:
    - destination:
        host: ratings
        subset: v1
EOF


#!/bin/bash

function prompt {
  read # Wait for the user to press Enter
  local count=$#
  local i=1

  for str in "$@"; do
    if [ $i -lt $count ]; then
      echo -e "$str"
    else
      echo -n "$str"
    fi
    ((i++))
  done

  read # Wait for the user to press Enter

  echo ""
}

function execute_command {
  echo "$1"
  eval "$1"
  echo ""
}

clear

prompt "Now add a half second request timeout for calls to the reviews service"

kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
    timeout: 0.5s
EOF

