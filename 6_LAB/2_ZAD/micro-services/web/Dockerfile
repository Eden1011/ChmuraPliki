FROM node:18

WORKDIR /app

COPY package.json .

RUN npm install --no-network || npm install --verbose --offline || echo "Instalacja pakietów nie powiodła się, będziemy kontynuować"

COPY . .

EXPOSE 3000

CMD ["node", "index.js"]
