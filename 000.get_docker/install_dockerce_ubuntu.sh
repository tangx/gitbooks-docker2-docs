#!/bin/bash
#
# install_dockerce_ubuntu.sh
#
# for ubuntu 16.04.3
#


echo $1 |grep -i cn

[ $? -eq 0 ] && area=cn


sudo apt-get update

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
    
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -


if [ "$area" == "cn" ]
then
{
    # 使用 aliyun repo
    # sudo add-apt-repository \
    #    "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
    #    $(lsb_release -cs) \
    #    stable"

    # 使用 中科大 repo
    sudo add-apt-repository \
        "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu \
        $(lsb_release -cs) \
        stable"
       
}
else
{
    # 使用 docker repo
    sudo add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
}
fi


sudo apt-get update
sudo apt-get install -y docker-ce

## 修改 image 源
if [ "$area" == "cn" ]
then
{
    sudo sed -i --follow-symlinks '/^ExecStart/s/\(.*\)/\1 --registry-mirror=https:\/\/docker.mirrors.ustc.edu.cn/' /etc/systemd/system/multi-user.target.wants/docker.service
    
    sudo systemctl daemon-reload
    sudo systemctl restart docker
}
fi
