#!/usr/bin/fish

cd (dirname (status -f))
cd qrtag-server

echo "Installing required Node version"
nvm install
npm install --global yarn
set NODE_ENV production

echo "Installing dependices"
yarn install
echo "Building"
yarn build
echo "Starting"
pm2 start dist/index.js --name qrtag-server
sudo /home/server/scripts/reloadNGINX.sh
