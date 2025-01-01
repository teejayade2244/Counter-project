# FROM: Specifies the base image to use for the Docker container. In this case, it's using node:18-alpine3.17, which is a lightweight version of Node.js based on Alpine Linux (version 3.17). This is a great choice for reducing the size of your Docker image.
FROM node:18-alpine3.17

# Sets the working directory for the following instructions. Any relative paths used after this command will be from /usr/app. If the directory doesn’t exist, it will be created.
WORKDIR /usr/app

# This copies package.json and package-lock.json (or any file matching package*.json) from your local machine into the /usr/app/ directory in the container. This is done before installing dependencies to leverage Docker’s caching mechanism, so dependencies don’t need to be reinstalled unless these files change.
COPY package*.json /usr/app/

# Runs a command inside the container. Here, it runs npm install to install the dependencies listed in package.json. This is done after copying the package*.json files to avoid unnecessary reinstallation of dependencies
RUN npm install

# This copies the entire content of the current directory (except files ignored by .dockerignore) into the working directory (/usr/app) of the container. This includes your application code, configuration files, etc.
COPY . .

# This informs Docker that the container will listen on port 3000 at runtime. It's a way of documenting the port your application uses, and it makes it easier to link containers in Docker Compose or when running with docker run.
EXPOSE 3000

# This specifies the default command to run when the container starts. Here, it’s running npm start, which typically starts the application (you should have a start script defined in package.json).
CMD ["npm", "start"]