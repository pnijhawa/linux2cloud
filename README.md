# kubernetes

**Enable ssh on all nodes**

sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
grep -E "^PermitRootLogin |^PasswordAuthentication " /etc/ssh/sshd_config
systemctl restart sshd

**Set root password**

echo redhat | passwd --stdin root

**Set Hostname on Nodes**

hostnamectl set-hostname <hostname>
  
**Update /etc/hosts file on all nodes**

[root@loadbalancer ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
#::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

10.128.0.7      loadbalancer
10.128.0.9      master-a
10.138.0.9      master-b
10.128.0.8      worker-a
10.138.0.8      worker-b

**Disable Selinux on all nodes**

[root@loadbalancer ~]# for n in loadbalancer master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux"; done
[root@loadbalancer ~]# for n in loadbalancer master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "grep disabled /etc/sysconfig/selinux"; done
[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "init 6"; done
[root@loadbalancer ~]# init 6
[root@loadbalancer ~]# for n in loadbalancer master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n setenforce 0; done

**Generate ssh key**

[root@loadbalancer ~]# ssh-keygen
[root@loadbalancer ~]# for n in loadbalancer master-a master-b worker-a worker-b; do echo "*********$n********"; ssh-copy-id $n; done




Update all the nodes
[root@loadbalancer ~]# for n in loadbalancer master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n yum update -y; done

Configure Haproxy on loadbalancer
[root@loadbalancer ~]# yum install haproxy -y

[root@loadbalancer ~]# cat /etc/haproxy/haproxy.cfg
frontend fe-apiserver
        bind *:6443
        mode tcp
        option tcplog
        default_backend be-apiserver

backend be-apiserver 
        mode tcp
        option tcplog
        option tcp-check
        balance roundrobin
        #default-server  inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
        server master-a 10.128.0.9:6443 check
        server master-b 10.138.0.9:6443 check
		
[root@loadbalancer ~]# systemctl restart haproxy
[root@loadbalancer ~]# systemctl enable haproxy
[root@loadbalancer ~]# systemctl status haproxy
[root@loadbalancer ~]# nc -v localhost 6443

Disable Swap
[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "sed -i '/swap/d' /etc/fstab"; done
[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "swapoff -a"; done
[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "swapon -s"; done

[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "yum install wget gcc pcre-static pcre-devel curl -y"; done

[root@loadbalancer ~]# cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; scp /etc/yum.repos.d/kubernetes.repo $n:/etc/yum.repos.d/; done

[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "yum install -y kubelet kubeadm kubectl"; done

[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "yum install -y docker"; done

On Master Nodes (master-a, master-b)
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --reload

On Worker Nodes (worker-a, worker-b)
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --reload

[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "systemctl disable firewalld"; done
[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "systemctl stop firewalld"; done
[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "systemctl enable docker"; done
[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "systemctl start docker"; done
[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "systemctl enable kubelet"; done
[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "systemctl start kubelet"; done

[root@loadbalancer ~]# cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; scp /etc/sysctl.d/k8s.conf $n:/etc/sysctl.d/; done
[root@loadbalancer ~]# for n in master-a master-b worker-a worker-b; do echo "*********$n********"; ssh -qt $n "sysctl -p"; done

[root@master-a ~]# kubeadm init --control-plane-endpoint "loadbalancer:6443" --upload-certs --pod-network-cidr=192.168.0.0/16

[root@master-b ~]# kubeadm join loadbalancer:6443 --token 37oxyc.n0uf6dh50g5bu6sw \
>     --discovery-token-ca-cert-hash sha256:2cd93e097c694a1a532eb30db9e5d57368def7281fa0a2fd248a2c0ae6847aee \
>     --control-plane --certificate-key 098ffba6a0187daeef49b0c767e37759e2ee6c365441b2c32d58bb09e281b48a

For Worker Nodes
[root@worker-a ~]# kubeadm join loadbalancer:6443 --token 37oxyc.n0uf6dh50g5bu6sw \
    --discovery-token-ca-cert-hash sha256:2cd93e097c694a1a532eb30db9e5d57368def7281fa0a2fd248a2c0ae6847aee
	
[root@worker-b ~]# kubeadm join loadbalancer:6443 --token 37oxyc.n0uf6dh50g5bu6sw \
>     --discovery-token-ca-cert-hash sha256:2cd93e097c694a1a532eb30db9e5d57368def7281fa0a2fd248a2c0ae6847aee

[root@master-a ~]#   mkdir -p $HOME/.kube
[root@master-a ~]#   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
[root@master-a ~]#   sudo chown $(id -u):$(id -g) $HOME/.kube/config


[root@loadbalancer ~]# mkdir -p $HOME/.kube
[root@loadbalancer ~]# scp  master-a:/etc/kubernetes/admin.conf $HOME/.kube/config
[root@loadbalancer ~]# yum install kubectl -y

[root@loadbalancer ~]# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

[root@loadbalancer ~]# kubectl get pods -n kube-system
