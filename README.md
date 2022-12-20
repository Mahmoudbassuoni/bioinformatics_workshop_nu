# Bioinformatics_Workshop_NU
A bioinformatics tutorial on alignment and variant calling and how to extract the Operational Taxonimc Units (OTU) out of Bacterial Fastq files.
# NGS alignment and variant calling
## Part.1 Docker Installation and Image start
**All tools needed was downloaded and installed on a docker image for anyone to be able to reproduce the same data without errors**
### 1.1 Download Docker
#### 1. Update the apt package index and install packages to allow apt to use a repository over HTTPS:
```
$ sudo apt-get update
$ sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```    
#### 2.Add Docker’s official GPG key:
```
$ sudo mkdir -p /etc/apt/keyrings
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```
#### 3.Use the following command to set up the repository:
```
$ echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
### 1.2 Install Docker Engine
#### 1.Update the apt package index:
```
$ sudo apt-get update
```
#### 2.Install Docker Engine, containerd, and Docker Compose. 
```
$ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```
#### 3.Verify that the Docker Engine installation is successful by running the hello-world image:
```
$ sudo docker run hello-world
```
### 1.3 Install our tutorial docker image
```
$ sudo docker pull mahmoudbassyouni/bioinformatics_workshop_nu:v2
```
### 1.4 Run the docker image
```
$ sudo docker run -it -v $HOME:$HOME mahmoudbassyouni/bioinformatics_workshop_nu:v2
```
