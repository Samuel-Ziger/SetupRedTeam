FROM node:22-alpine
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY server ./server
COPY index.html ./

ENV NODE_ENV=production
EXPOSE 3847
CMD ["node", "server/index.js"]
