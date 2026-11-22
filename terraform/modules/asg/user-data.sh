#!/bin/bash
# سكريبت بسيط - باقي الإعدادات (containerd, kubeadm) هتتعمل بالـ Ansible
hostnamectl set-hostname "asg-worker-$(hostname | tr -d '.')"
