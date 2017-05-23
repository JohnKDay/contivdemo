
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

docker info 


ConfirmPrompt


# -------------------  Specify the correct vlan range here...
netctl global set -f aci -v 2991-2999

netctl global info

ConfirmPrompt

# ------------------- Create a tenant

netctl tenant create trains

netctl tenant ls

ConfirmPrompt

# ------------------- Create a external contracts

# uni/tn-trains/brc-roundhouse
netctl external-contracts create --tenant trains -p --contract "uni/tn-trains/brc-roundhouse" vmHTTPprovide
netctl external-contracts create --tenant trains -c --contract "uni/tn-trains/brc-roundhouse" vmHTTPconsume

ConfirmPrompt
# ------------------- Choose the subnet you like...

netctl net create -t trains -e vlan -s 100.100.100.0/24 -g 100.100.100.254 steam

netctl net ls -t trains

ConfirmPrompt

# ------------------- Creating two EPGs : app and db

netctl group create -t trains -e vmHTTPprovide -e vmHTTPconsume steam app

netctl group create -t trains steam db

ConfirmPrompt
# ------------------- Push app-profile to ACI 

netctl app-profile create -t trains -g app,db trains-profile

netctl app-profile ls -t trains

ConfirmPrompt
# ------------------- At this point, you will see the app profile created in ACI

ConfirmPrompt

# ------------------- Creating containers with app/trains and db/trains as a network
exit


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


until kubectl get pods | grep "No resources found"
do
  sleep 1
done
kubectl get pods 


ConfirmPrompt


netctl app-profile rm -t trains trains-profile
netctl group rm -t trains app
netctl group rm -t trains db
netctl external-contracts rm --tenant trains vmHTTPprovide
netctl external-contracts rm --tenant trains vmHTTPconsume
netctl policy rm -t trains app2db
netctl network rm -t trains steam
netctl tenant rm trains
