#!/bin/bash
# الاستخدام:  ./run.sh <BASTION_PUBLIC_IP>
set -e
export BASTION_IP="$1"
export AWS_PROFILE=new-profile
[ -z "$BASTION_IP" ] && { echo "usage: ./run.sh <bastion_public_ip>"; exit 1; }
ansible-inventory --graph
ansible-playbook playbooks/site.yml
