FROM node:18

ENV NODE_ENV=production

WORKDIR /usr/src/app

COPY app/package*.json ./

RUN npm install

COPY app/ ./

EXPOSE 3000

CMD ["node", "index.js"]
