#!/bin/bash

KubernetesVer=$1


if [ ! $KubernetesVer ]; then
	KubernetesVer="1.19.0"
fi

cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab && \
	swapoff -a && \
	yum install -y yum-utils device-mapper-persistent-data lvm2 && \
	yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo && \
	yum install -y docker-ce docker-ce-cli containerd.io  && \
	systemctl start docker && systemctl enable docker && \
	yum install -y kubelet-${KubernetesVer} kubeadm-${KubernetesVer} --disableexcludes=kubernetes && \
	systemctl enable kubelet && systemctl start kubelet && \
	echo -e "kubernetes slave init finish, you can join with: kubeadm join <master-addr> --token <token> --discovery-token-ca-cert-hash sha256:<discovery-token-ca-cert-hash>"
