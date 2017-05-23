
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


netctl global info

ConfirmPrompt

# ------------------- Create a tenant

netctl tenant create trains

netctl tenant ls

# ------------------- Choose the subnet you like...

netctl net create -t trains -e vlan -s 29.91.0.0/24 -g 29.91.0.254 steam

netctl net ls -t trains

ConfirmPrompt

# ------------------- Creating two EPGs : app and db

netctl group create -t trains steam app

netctl group create -t trains steam db

# ------------------- Push app-profile to ACI 

netctl app-profile create -t trains -g app,db trains-profile

netctl app-profile ls -t trains

# ------------------- At this point, you will see the app profile created in ACI

ConfirmPrompt

# ------------------- Creating containers with app/trains and db/trains as a network

docker run -itd --net="app/trains" --name=app1  johnkday/contiv-test-container
docker run -itd --net="app/trains" --name=app2 -e affinity:container!=app* johnkday/contiv-test-container 
docker run -itd --net="db/trains" --name=db1 -e affinity:container!=app* johnkday/contiv-test-container

# ------------------- Running docker ps command to check docker container creation

docker ps 

env | grep DOCKER_HOST

ConfirmPrompt

# ------------------- now confirm that app1 container CAN NOT ping db1 container

ConfirmPrompt

# ------------------- Testing the policies and rules which we have applied on app and db groups.

# ------------------- Now create ICMP allow policy so that these container can ping each other.

netctl policy create -t trains app2db

netctl group create -t trains -p app2db steam db

netctl group create -t trains steam app

netctl policy rule-add -t trains -d in --protocol icmp  --from-group app  --action allow app2db 1

ConfirmPrompt

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

docker stop $(docker ps -a | grep johnkday/contiv-test-container | awk '{print $1}')
docker rm $(docker ps -a | grep johnkday/contiv-test-container | awk '{print $1}')

netctl app-profile rm -t trains trains-profile
netctl group rm -t trains app
netctl group rm -t trains db
netctl policy rm -t trains app2db
netctl network rm -t trains steam
netctl tenant rm trains
