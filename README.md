##Getting started on with [Kubernetes](https://github.com/GoogleCloudPlatform/kubernetes) on [Ubuntu](http://www.ubuntu.com)

This guide describes ways to start Kubernetes on a single host system i.e. both master and a minion on the same host. Running it across multiple hosts require a multi-host networking accordingly to the network model proposed by kubernetes.

The steps assume that docker is installed on the ubuntu system. The document is divided into 4 parts:
 1. Getting the latest binaries
 2. Configure Upstart scripts to start kubernetes
 3. Using Kubernetes
 4. Customizing the ubuntu launch

## 1. Getting the latest binaries
The first step is to get a latest etcd and kubernetes binaries. This is best done by compiling the binaries yourself using the instructions provided at 
[Kubernetes Compilation](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/devel/development.md) and [Etcd Compilation](https://github.com/coreos/etcd/tree/master/Documentation)

Here are the steps extracted from the above two links to compile both binaries:
```
# Clone and compile etcd (make sure your GOPATH is set)
$ sudo mkdir -p $GOPATH/src/github.com/coreos
$ cd $GOPATH/src/github.com/coreos/
$ git clone https://github.com/coreos/etcd.git
$ cd etcd
$ ./build
# copy etcd binaries to /opt/bin
$ sudo mkdir -p /opt/bin
$ sudo cp bin/etcd* /opt/bin

# Clone and compile Kubernetes
$ mkdir -p $GOPATH/src/github.com/GoogleCloudPlatform/
$ cd $GOPATH/src/github.com/GoogleCloudPlatform/
$ git clone https://github.com/GoogleCloudPlatform/kubernetes.git

# $GOPATH must set and $GOPATH/bin in $PATH
# first install mercurial and godep
$ sudo apt-get install mercurial
$ sudo go get github.com/tools/godep

# modify git hooks for compile changes
$ cd kubernetes/.git/hooks/
$ ln -s ../../hooks/prepare-commit-msg .
$ ln -s ../../hooks/commit-msg .

# building kubernetes executables
$ hack/build-go.sh

# Copy the kubernetes binaries to /opt/bin
$ cd $GOPATH/src/github.com/GoogleCloudPlatform/kubernetes/
$ sudo cp _output/local/bin/linux/amd64/kube* /opt/bin/

```

Note: if you download [ubuntu-kubernetes-instll](http://github.com/jainvipin/ubuntu-kubernetes-install) it includes the compiled binaries, however these binaries may not be the latest/stable version and wouldn't allow you to experiment with the code if you plan to do that.

## 2. Configure Upstart scripts to start kubernetes

The second step is to setup following upstart services on the system:
- Kubernetes Master: etcd, kube-apiserver, kube-controller-manager, kube-scheduler
- Kubernetes Minion: etcd, kubelet, kube-proxy

your can do the above things on one host sytem by cloning the following git repo and executing the ubuntu-kubernetes-install.sh script

```
$ git clone https://www.github.com/jainvipin/ubuntu-kubernetes-install.git
$ cd ubuntu-kubernetes-install
$ sudo ./ubuntu-kubernetes-install.sh
```

This will copy appropriate scripts with the default configuration for a single host in the following locations:
- /etc/init/kube* /etc/init/etcd
- /etc/init.d/kube* /etc/init.d/etcd
- /etc/default/kube* and /etc/default/etcd
These scripts would help upstart to work correctly upon bootup. At this point you can use the service commands to start/stop services associated with kubernetes:
```
# on master
$ sudo service etcd start
$ sudo service kube-apiserver start
$ sudo service kube-controller-manager start
$ sudo service kube-scheduler start

# on minion
$ sudo service etcd start
$ sudo service kube-proxy start
$ sudo service kubelet start

# similarly restart/stop commands can be used with various services
```


## 3. Using Kubernetes

Now that Kubernetes related services should be up and running which you can confirm this using 'service etcd status' or 'ps aux | grep etcd'. If all looks okay, you are ready to launch the docker apps and have kubernetes schedule them. Using the popular example from Kubernetes website, you can create a redis-master.json file, like following

```
{
  "id": "redis-master",
  "kind": "Pod",
  "apiVersion": "v1beta1",
  "desiredState": {
    "manifest": {
      "version": "v1beta1",
      "id": "redis-master",
      "containers": [{
        "name": "master",
        "image": "dockerfile/redis",
        "cpu": 100,
        "ports": [{
          "containerPort": 6379,
          "hostPort": 6379
        }]
      }]
    }
  },
  "labels": {
    "name": "redis-master"
  }
}
```

Then create/delete job using kubecfg command. Also look at the scheduled jobs:

```
# create a pod
$ sudo /opt/bin/kubecfg -h http://127.0.0.1:8080 -c ./redis-master.json create /pods
Name                Image(s)            Host                Labels              Status
----------          ----------          ----------          ----------          ----------
redis-master        dockerfile/redis    <unassigned>        name=redis-master   Pending

# list pods
$ sudo /opt/bin/kubecfg -h http://127.0.0.1:8080 -c ./redis-master.json list /pods
Name                Image(s)            Host                Labels              Status
----------          ----------          ----------          ----------          ----------
redis-master        dockerfile/redis    127.0.0.1/          name=redis-master   Running

# fire up the redis-cli and update the db to ensure redis server launched ok
$ sudo docker run -t -i dockerfile/redis /usr/local/bin/redis-cli -h 172.17.42.1
172.17.42.1:6379> 
172.17.42.1:6379> set name "jainvipin"
OK
172.17.42.1:6379> get name
"jainvipin"

# finally delete the pod
$ sudo kubecfg -h http://127.0.0.1:8080 -c ./redis-master.json delete /pods/redis-master
Status
----------
Success

```

## 4. Customizing the ubuntu launch

For this you will need to tweak /etc/default/kube* files and restart the services.

```
$ sudo cat /etc/default/etcd 
# Etcd Upstart and SysVinit configuration file

# Customize etcd location 
# ETCD="/opt/bin/etcd"

# Use ETCD_OPTS to modify the start/restart options
ETCD_OPTS="-listen-client-urls=http://127.0.0.1:4001"

# Add more envionrment settings used by etcd here

$ sudo service etcd status
etcd start/running, process 834
$ sudo service etcd restart
etcd stop/waiting
etcd start/running, process 29050
```

If you prefer not to start kubernetes upon startup, then you can modify the 'script' clause in /etc/init/kube*.conf and /etc/init/etcd.conf files.



Feel free to provide feedback or suggest changes to the above instructions if above mentioned changes do not work for you on a Ubuntu 14.04 or onwards.


