#!/bin/bash
# Sample script to perform contiv cli configuration with ACI integration

function WaitPrompt {
  ConfirmPrompt
  return
  set +v
  echo 
  echo ---------
  echo 
  sleep 14
  set -v 
  return
}

# Function to get user confirmation to proceed
function ConfirmPrompt {
  set +v
  echo
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

# ------------------- Get global info

netctl global info

ConfirmPrompt

ConfirmPrompt

# ------------------- Choose the subnet you like...

netctl net create -t default -e vxlan -s 29.91.0.100-29.91.0.200/24 -g 29.91.0.1 newnet
netctl net create -t default -e vxlan -s 39.91.0.100-39.91.0.200/24 -g 39.91.0.1 newnet2

netctl net ls -t default

ConfirmPrompt


# ------------------- Creating two EPGs : app and db
# ------------------- with Deny All policy

netctl policy create -t default app2db

netctl group create -t default newnet app

netctl group create -t default -p app2db newnet db

netctl group create -t default newnet2 db2

netctl policy rule-add -t default --action deny app2db 1

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

echo "db2.yaml"
cat db2.yaml
printf "\n-----------------------\n"
kubectl create -f db2.yaml


# ------------------- Checking kubectl until pods are running 

sleep 4
until kubectl get pods db1 | grep Running
do
  sleep 1
done

kubectl get pods -o wide

app1IP=$(kubectl describe pod app1 | grep IP | sed -E 's/IP:[[:space:]]+//')
app2IP=$(kubectl describe pod app2 | grep IP | sed -E 's/IP:[[:space:]]+//')
db1IP=$(kubectl describe pod db1 | grep IP | sed -E 's/IP:[[:space:]]+//')
db2IP=$(kubectl describe pod db2 | grep IP | sed -E 's/IP:[[:space:]]+//')

echo "app1 IP address: " $app1IP
echo "app2 IP address: " $app2IP
echo "db1 IP address: " $db1IP
echo "db2 IP address: " $db2IP


ConfirmPrompt

# ------------------- Confirm that app1 container CAN ping app2 container

kubectl exec -ti app1 -- ping -w 3 ${app2IP}

# ------------------- Confirm that app1 container CAN ping db2 container

kubectl exec -ti app1 -- ping -w 3 ${db2IP}

# ------------------- Confirm that app1 container CAN NOT ping db1 container

kubectl exec -ti app1 -- ping -w 3 ${db1IP}

ConfirmPrompt

# ------------------- Testing the policies and rules which we have applied on app and db groups.

# ------------------- Create ICMP allow policy so that these container can ping each other.


netctl policy rule-add -t default -p 10 -d in --protocol icmp  --from-group app  --action allow app2db 10

# ------------------- Confirm that app1 container CAN ping db1 container

kubectl exec -ti app1 -- ping -w 3 ${db1IP}

ConfirmPrompt

# ------------------- Confirm that port range 6666-6669 is open app1->app2

kubectl exec -ti app1 -- nc -zvnw 3 ${app2IP} 6666-6669

# ------------------- Confirm that port range 6666-6669 is open app1->app2

kubectl exec -ti app1 -- nc -zvnw 3 ${db1IP} 6666-6669


ConfirmPrompt

# ------------------- Now allow TCP port 6666 between these containers


netctl policy rule-add -t default -p 10 -d in --protocol tcp --port 6666 --from-group app  --action allow app2db 11

# ------------------- Confirm that port 6666 is allowed between these Containers

kubectl exec -ti app1 -- nc -zvnw 3 ${db1IP} 6666-6669

ConfirmPrompt

# ------------------- Cleaning up all the containers, networks and groups."

ConfirmPrompt

kubectl delete pods --all


until kubectl get pods 2>&1 | grep "No resources found"
do
  sleep 1
done
kubectl get pods 

echo -- remove the created network


netctl group rm -t default app
netctl group rm -t default db
netctl group rm -t default db2
netctl policy rm -t default app2db
netctl network rm -t default newnet
netctl network rm -t default newnet2
