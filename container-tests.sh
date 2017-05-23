
#!/bin/bash
# Script to create tests against Confiv policies

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

set -v
# ------------------ Show container IPs

echo "IP address for app1 is:"
kubectl exec -ti app1 -- ip a s eth0


echo "IP address for app2 is:"
kubectl exec -ti app2 -- ip a s eth0


echo "IP address for db1 is:"
kubectl exec -ti db1 -- ip a s eth0



ConfirmPrompt

# ------------------ Show app1 CAN ping app2 container

kubectl exec -ti app1 -- ping -w 3 29.91.0.101

# ------------------ Show app1 CAN NOT ping db1 container

kubectl exec -ti app1 -- ping -w 3 29.91.0.102

# ------------------ Wait for ICMP rule added to app2db policy

ConfirmPrompt
 
# ------------------ Show app1 CAN ping db1 container

kubectl exec -ti app1 -- ping -w 3 29.91.0.102

# ------------------ 

ConfirmPrompt
 
# ------------------ Show app1 CAN connect to port 6666 on app2

kubectl exec -ti app1 -- nc -zvnw 3 29.91.0.101 6666-6669

# ------------------ Show app1 CAN NOT connect to port 6666 on db1

kubectl exec -ti app1 -- nc -zvnw 3 29.91.0.102 6666-6669

ConfirmPrompt

# ------------------ Show app1 CAN connect to port 6666 on db1

kubectl exec -ti app1 -- nc -zvnw 3 29.91.0.102 6666-6669

echo "Show config in web browser" 
exit 0

