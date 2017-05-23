
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
# ------------------ Show docker swarm environment

kubectl get nodes


ConfirmPrompt


# -------------------  Specify the correct vlan range here...

netctl global set --fwd-mode routing --fabric-mode default  --vlan-range "2990-2999"

netctl global info

ConfirmPrompt

# -------------------  Create BGP network 


netctl bgp create johnkday-k8s-l3-vm-1 --router-ip="29.9.0.2/24" --as="65002" --neighbor-as="500" --neighbor="29.9.0.1"
netctl bgp create johnkday-k8s-l3-vm-2 --router-ip="29.9.0.3/24" --as="65002" --neighbor-as="500" --neighbor="29.9.0.1"
netctl bgp create johnkday-k8s-l3-vm-3 --router-ip="29.9.0.4/24" --as="65002" --neighbor-as="500" --neighbor="29.9.0.1"
netctl bgp create johnkday-k8s-l3-vm-4 --router-ip="29.9.0.5/24" --as="65002" --neighbor-as="500" --neighbor="29.9.0.1"


# ------------------- Create a tenant

netctl tenant create trains

netctl tenant ls

ConfirmPrompt

# ------------------- Choose the subnet you like...

netctl net create -t trains -e vlan -s 100.100.100.0/24 -g 100.100.100.254 steam

netctl net ls -t trains

ConfirmPrompt

# ------------------- Creating two EPGs : app and db

netctl group create -t trains steam app

netctl group create -t trains steam db

ConfirmPrompt
# ------------------- At this point, you will see the app profile created in ACI

ConfirmPrompt

# ------------------- Creating containers with app/trains and db/trains as a network


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

# ------------------- now confirm that app1 container CAN NOT ping db1 container

ConfirmPrompt

# ------------------- Testing the policies and rules which we have applied on app and db groups.

# ------------------- Now create ICMP allow policy so that these container can ping each other.

netctl policy create -t trains app2db

netctl group create -t trains -p app2db steam db

netctl policy rule-add -t trains -d in --protocol icmp  --from-group app  --action allow app2db 1

# ------------------- now confirm that app1 container CAN ping db1 container

ConfirmPrompt

# ------------------- Now confirm that port range 6666-6669 is not open

ConfirmPrompt

# ------------------- Now allow TCP port 6666 between these containers

netctl policy rule-add -t trains -d in --protocol tcp --port 6666 --from-group app  --action allow app2db 2

# ------------------- Confirm that port 6379 is allowed between these Containers

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


netctl group rm -t trains app
netctl group rm -t trains db
netctl policy rm -t trains app2db
netctl network rm -t trains steam
netctl tenant rm trains
