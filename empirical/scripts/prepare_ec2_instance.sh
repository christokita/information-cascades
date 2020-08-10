# Example terminal command to get into ec2 instance:
# > ssh -i ../data/api_keys/aws_pem/my_key_here.pem ec2-user@[insert Public DNS (IPv4)]

# Get Anaconda3
wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh
bash Anaconda3-2020.02-Linux-x86_64.sh
source ~/.bashrc

# Install pip
conda install pip

# Install needed packages for our scripts
pip install -r requirements 