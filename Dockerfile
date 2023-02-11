version: '2.3'

services:
  web:
    build: ./srv
    image: registry.example.com/user/web
    environment:
      - DEPLOY_LOCATION=local
      - JANUS_HTTP_URI=/janus/http
      - JANUS_HTTPS_URI=/janus/http
      - JANUS_WS_URI=/janus/ws
      - JANUS_WSS_URI=/janus/ws
      - JANUS_CODEC=vp8
      - JANUS_TOKEN_SECRET=$JANUS_TOKEN_SECRET
      - JANUS_SERVER_IDS=janus,janus2
      - JANUS_PLUGINS=janus.plugin.videoroom
      - YT_API_KEY=$YT_API_KEY
      - AWS_SES_ACCESS_KEY=$AWS_SES_ACCESS_KEY
      - AWS_SES_SECRET=$AWS_SES_SECRET
      - AWS_S3_UPLOADS_ACCESS_KEY="AKIAQXGT6CMGAIPNOBFY"
      - AWS_S3_UPLOADS_SECRET="jEIHPRVyd84vtkXHSOTAe+bGbFJecU9DHMDJXVZ4"
      - AWS_S3_UPLOADS_BUCKET=jic-uploads
      - TURN_URIS=turn.example.com
      - GCM_API_KEY=$GCM_API_KEY # key for push notifications
      - STRIPE_SK=$STRIPE_SK
      - STRIPE_WH_KEY=$STRIPE_WH_KEY
      - MONGODB_URI=mongodb://mongodb,mongodbslave/tc?replicaSet=rs0
    expose:
      - "80"
    depends_on:
      - redis
      - mongodb
      - mongodbslave
      - janus
      - janus2
    logging:
      options:
        max-size: '1m'
    restart: always
  web2:
    image: registry.example.com/user/web
    environment:
      - DEPLOY_LOCATION=local
      - JANUS_HTTP_URI=/janus/http
      - JANUS_HTTPS_URI=/janus/http
      - JANUS_WS_URI=/janus/ws
      - JANUS_WSS_URI=/janus/ws
      - JANUS_CODEC=vp8
      - JANUS_TOKEN_SECRET=$JANUS_TOKEN_SECRET
      - JANUS_SERVER_IDS=janus,janus2
      - JANUS_PLUGINS=janus.plugin.videoroom
      - YT_API_KEY=$YT_API_KEY
      - AWS_SES_ACCESS_KEY=$AWS_SES_ACCESS_KEY
      - AWS_SES_SECRET=$AWS_SES_SECRET
      - AWS_S3_UPLOADS_ACCESS_KEY=$AWS_S3_UPLOADS_ACCESS_KEY
      - AWS_S3_UPLOADS_SECRET=$AWS_S3_UPLOADS_SECRET
      - AWS_S3_UPLOADS_BUCKET=jic-uploads
      - TURN_URIS=turn.example.com
      - GCM_API_KEY=$GCM_API_KEY # key for push notifications
      - STRIPE_SK=$STRIPE_SK
      - STRIPE_WH_KEY=$STRIPE_WH_KEY
      - MONGODB_URI=mongodb://mongodb,mongodbslave/tc?replicaSet=rs0
    expose:
      - "80"
    depends_on:
      - redis
      - mongodb
      - mongodbslave
      - janus
      - janus2
    logging:
      options:
        max-size: '1m'
    restart: always

  home:
    build: ./home
    image: registry.example.com/user/home
    environment:
      - DEPLOY_LOCATION=local
      - STRIPE_KEY_PUBLIC=$STRIPE_KEY_PUBLIC
      - MONGODB_URI=mongodb://mongodb,mongodbslave/tc?replicaSet=rs0
    ports:
      - "3000:3000"
    restart: always
    depends_on:
      - web
      - web2
    logging:
      options:
        max-size: '1m'
  home2:
    image: registry.example.com/user/home
    environment:
      - DEPLOY_LOCATION=local
      - STRIPE_KEY_PUBLIC=$STRIPE_KEY_PUBLIC
      - MONGODB_URI=mongodb://mongodb,mongodbslave/tc?replicaSet=rs0
    expose:
      - "3000"
    restart: always
    depends_on:
      - web
      - web2
    logging:
      options:
        max-size: '1m'

  mongodb:
    image: mongo:3.6
    command: "--smallfiles --replSet rs0"
    # expose:
    #   - "27017"
    ports:
      - "27017:27017"
    volumes:
      - ./data/db:/data/db
    logging:
      options:
        max-size: '1m'
    restart: always

  mongodbslave:
    image: mongo:3.6
    command: "--smallfiles --replSet rs0"
    expose:
      - "27017"
    logging:
      options:
        max-size: '1m'
    restart: always
    volumes:
      - ./data/db2:/data/db

  redis:
    image: redis
    logging:
      options:
        max-size: '1m'
    restart: always

  nginx:
    build:
      context: ./nginx
      args:
        - ENV
    image: registry.example.com/user/nginx
    ports:
      - "80:80"
      - "443:443"
    logging:
      options:
        max-size: '1m'
    depends_on:
      - web
      - web2
      - home
      - home2
    restart: always

  janus:
    build:
      context: ./janus

    image: registry.example.com/user/janus
    expose:
      - "8088"
      - "8889"
      - "8188"
      - "8989"
      - "7888"
    environment:
      - DEBUG_COLORS=false
      - SERVER_NAME=janus
      - ENABLE_EVENTS=true
      - ENABLE_RABBIT_EVENTS=false
      - JANUS_TOKEN_SECRET=$JANUS_TOKEN_SECRET
    logging:
      options:
        max-size: '1m'
    restart: always

  janus2:
    image: registry.example.com/user/janus
    expose:
      - "8088"
      - "8889"
      - "8188"
      - "8989"
      - "7888"
    environment:
      - DEBUG_COLORS=false
      - SERVER_NAME=janus2
      - ENABLE_EVENTS=true
      - ENABLE_RABBIT_EVENTS=false
      - JANUS_TOKEN_SECRET=$JANUS_TOKEN_SECRET
    logging:
      options:
        max-size: '1m'
    volumes:
      - ./core:/opt/janus/bin/core
    restart: always
  haproxy:
    build: ./haproxy
    image: registry.example.com/user/haproxy
    expose:
      - "80"
    logging:
      options:
        max-size: '1m'
    restart: always

  email:
    image: registry.example.com/user/jic-email
    expose:
      - "3001"
    environment:
      - AWS_SES_ACCESS_KEY=$AWS_SES_ACCESS_KEY
      - AWS_SES_SECRET=$AWS_SES_SECRET
      - SHARED_SECRET=$SHARED_SECRET
    logging:
      options:
        max-size: '1m'
    restart: always
