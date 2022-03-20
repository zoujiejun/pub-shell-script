sterIP=$1
KubernetesVer=$2
ImageRepository=$3
ServiceCidr=$4
PodCidr=$5

if [ ! $MasterIP ]; then
	echo "MasterIP can not be null"
	exit -1
fi

if [ ! $KubernetesVer ]; then
	KubernetesVer="1.19.0"
fi

if [ ! $ImageRepository ]; then
	ImageRepository="registry.aliyuncs.com/google_containers"
fi

if [ ! $ServiceCidr ]; then
	ServiceCidr=10.1.0.0/16
fi

if [ ! $PodCidr ]; then
	PodCidr=10.244.0.0/16
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

yum install -y yum-utils device-mapper-persistent-data lvm2 && \
	yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo && \
	yum install -y docker-ce docker-ce-cli containerd.io && \
	systemctl start docker && systemctl enable docker && \
	yum install -y kubelet-${KubernetesVer} kubeadm-${KubernetesVer} kubectl-${KubernetesVer} && \
	systemctl enable kubelet && systemctl start kubelet && \
	sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab && \
	swapoff -a && \
	systemctl stop firewalld.service && \
	systemctl disable firewalld.service && \
	setenforce 0 && \
	sed -i 's/^SELINUX=.*$/SELINUX=disable/g' /etc/selinux/config && \
	kubeadm init --kubernetes-version=${KubernetesVer} --apiserver-advertise-address=${MasterIP} --image-repository ${ImageRepository} --service-cidr=${ServiceCidr} --pod-network-cidr=${PodCidr} && 
	echo -e "kubernetes init finish, you can 
    install flannel with: kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
        check with: kubectl get all --all-namespaces
	    check node: kubectl get node -o wide"
