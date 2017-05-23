#!/bin/bash
# Sample script to perform contiv cli configuration with ACI integration

# Function to get user confirmation to proceed
function ConfirmPrompt {
  set +v
  while true; do
  read -p "Ready to proceed(y/n)? " choice
  if [ "$choice" == "y" ]; then
      break
  fi

  if [ "$choice" == "n" ]; then
      echo "Try again when you are ready."
      exit 1
  else
      echo "Please answer y or n"
      continue
  fi
  done
  set -v
}
# ------------------ Show container environment

kubectl get nodes

ConfirmPrompt

# -------------------  Specify the correct vlan range here...

netctl global info

ConfirmPrompt

# ------------------- Creating two EPGs : app and db
# ------------------- with Deny All policy

netctl policy create app2db

netctl group create steam app

netctl group create -p app2db steam db

netctl policy rule-add -d in --protocol tcp --action deny app2db 1
netctl policy rule-add -d in --protocol udp --action deny app2db 2
netctl policy rule-add -d in --protocol icmp --action deny app2db 3

ConfirmPrompt

# ------------------- Creating containers with app/trains and db/trains in a network

echo "app1.yaml"
cat app1.yaml
printf "\n-----------------------\n"
kubectl create -f app1.yaml

echo "app2.yaml"
cat app2.yaml
printf "\n-----------------------\n"
kubectl create -f app2.yaml

echo "db1.yaml"
cat db1.yaml
printf "\n-----------------------\n"
kubectl create -f db1.yaml


# ------------------- Checking kubectl until pods are running 

until kubectl get pods db1 | grep Running
do
  sleep 1
done

kubectl get pods -o wide

ConfirmPrompt

# ------------------- Confirm that app1 container CAN ping app2 container
# ------------------- Confirm that app1 container CAN NOT ping db1 container

ConfirmPrompt

# ------------------- Testing the policies and rules which we have applied on app and db groups.

# ------------------- Create ICMP allow policy so that these container can ping each other.


netctl policy rule-add -p 10 -d in --protocol icmp  --from-group app  --action allow app2db 10

# ------------------- Confirm that app1 container CAN ping db1 container

ConfirmPrompt

# ------------------- Confirm that port range 6666-6669 is open app1->app2
# ------------------- `nc -zvnw 3 29.91.0.101 6666-6669`
# ------------------- Confirm that port range 6666-6669 is open app1->app2
# ------------------- `nc -zvnw 3 29.91.0.101 6666-6669`


ConfirmPrompt

# ------------------- Now allow TCP port 6666 between these containers


netctl policy rule-add -p 10 -d in --protocol tcp --port 6666 --from-group app  --action allow app2db 11

# ------------------- Confirm that port 6666 is allowed between these Containers

ConfirmPrompt

# ------------------- Cleaning up all the containers, networks and groups."

ConfirmPrompt

kubectl delete pods --all


until kubectl get pods 2>&1 | grep "No resources found"
do
  sleep 1
done
kubectl get pods 


ConfirmPrompt


netctl group rm app
netctl group rm db
netctl policy rm app2db
netctl network rm steam
netctl tenant rm trains
