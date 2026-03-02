#instalacion necesaria para isntancias de gcloud
#-----------------------
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
#-----------------------
sudo apt-get install -y lsb-release
export GCSFUSE_REPO=gcsfuse-$(lsb_release -c -s)
echo "deb https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y gcsfuse
