
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

netctl global set --fwd-mode aci --fabric-mode default  --vlan-range "2980-2989"

netctl global info

ConfirmPrompt

# ------------------- Create a tenant

netctl tenant create shapes

netctl tenant ls

# ------------------- Choose the subnet you like...

netctl net create -t shapes -e vlan -s 29.81.0.0/24 -g 29.81.0.1 sphere

netctl net ls -t shapes

ConfirmPrompt

# ------------------- Creating two EPGs : app and db

netctl group create -t shapes sphere app

netctl group create -t shapes sphere db

ConfirmPrompt

# ------------------- Creating containers with app/shapes and db/shapes as a network

#docker run -itd --net="app/shapes" --name=app1  contiv/web /bin/bash
#docker run -itd --net="app/shapes" --name=app2 -e affinity:container!=app* contiv/web /bin/bash
#docker run -itd --net="db/shapes" --name=db1 -e affinity:container!=app* contiv/redis /bin/bash

# ------------------- Running docker ps command to check docker container creation

docker ps 

env | grep DOCKER_HOST

ConfirmPrompt 


# ------------------- Testing the policies and rules which we have applied on app and db groups.

# ------------------- Now create default deny policy so that these containers can not ping each other.


netctl policy create -t shapes app2db

netctl group create -t shapes -p app2db sphere db

netctl group create -t shapes sphere app

#netctl policy rule-add -t shapes -d in --protocol tcp --action deny app2db 1 
#netctl policy rule-add -t shapes -d in --protocol udp --action deny app2db 2
#netctl policy rule-add -t shapes -d in --protocol icmp --action deny app2db 3
 
ConfirmPrompt

# ------------------- now confirm that app1 container CAN NOT ping db1 container

ConfirmPrompt

# ------------------- Now create ICMP allow policy so that these containers can ping each other.


netctl policy rule-add -t shapes -p 10 -d in --protocol icmp  --from-group app  --action allow app2db 10

ConfirmPrompt

# ------------------- now confirm that app1 container CAN ping db1 container

ConfirmPrompt

# ------------------- Now confirm that port range 6375-6379 is not open
# ----------- db1  - iperf -s -p 6379
# ----------- app1 - nc -znvw 3 <IP> 6375-6379

ConfirmPrompt

# ------------------- Now allow TCP port 6379 between these containers

netctl policy rule-add -t shapes -p 10 -d in --protocol tcp --port 6379 --from-group app  --action allow app2db 11

# ------------------- Confirm that port 6379 is allowed between these Containers

ConfirmPrompt

# ------------------- Cleaning up all the containers, networks and groups."

ConfirmPrompt

docker stop $(docker ps -a | grep web | awk '{print $1}')
docker stop $(docker ps -a | grep redis | awk '{print $1}') 
docker rm $(docker ps -a | grep web | awk '{print $1}')
docker rm $(docker ps -a | grep redis | awk '{print $1}')

netctl group rm -t shapes app
netctl group rm -t shapes db
netctl policy rm -t shapes app2db
netctl network rm -t shapes sphere
netctl tenant rm shapes
