#Kickstart Jenkins CI Pipeline with Dockers ( part 1/n )

Level : Beginner 

##What you can get from this tutorial

* quickly setup a CI environment with open source tool chain in a repeatable way
* create post-execution scripts on Jenkins without using extra plugins
* create parallel CI tasks
* create a restful API with NodeJS in a few minutes
* write a simple test for the API with jasmine 
* shorten project build time 
* some bash automation  

##What will be cover in the remaining series 

* create a simple web app 
* create visual testing for web app
* recap parallel tasks on Jenkins
* demonistrate a multi-tier CI Pipeline  

##Introduction

To fully implement CI for a multi-tier project, you need to enable Jenkins or your CI server to interact with different components developed with different tool-chains. There are a few ways to do so.

* Install these environments on the CI server
* having multiple children nodes attached to the CI server
* or what we will demonstrate today: dockorized everything and keep your CI tool slim 
 
**Jenkins** is an open source CI server which offer a simple way to set up a continuous integration and continuous delivery environment for almost any combination of languages and source code repositories. For beginners, it may be easier to understand if you treat it as a task scheduler.  Anyone with basic Linux bash script knowledge you only need to  bash command.

**Docker** is a software that performs operating-system-level virtualization, known as **containerisation**.  

**Continuous Delivery Pipeline** in CI are automated processes for getting the software from source control through deployment to end users.
**Jenkins Pipeline** is a newer suite of features in jenkins to implement these pipelines in a single script file. You no longer need to setup a few different plugins to get throught the while CI process.

Using docker will bring you the following advantages:
* separate complex and possible conflicting toolchains into straight forward virtual machines called **containers**.
* faster Pull->Build->Test cycle.  Instead of update dependency every time before build
* closely mimic production architectures with different tiers of service

##Prerequisite

* Download and Install Docker Community Edition ( [Mac (https://download.docker.com/mac/stable/Docker.dmg)]  / [Win (https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe)] )
We expect you can use docker without `sudo`.
If you are using linux and haven't add yourself into the docker group, do so and restart your terminal.
* clone GitHub - NodeJS API service ( coming soon )
* clone GitHub - Tutorial scripts
`git clone git@bitbucket.org:jlam-palo-it/jenkins-pipeline-dockers.git && cd jenkins-pipeline-dockers`

##Housekeeping

The jenkins docker shall presist all setting to host disk and can be shutdown and removed to save disk spaces. Therefore, we begin with creating folders which will be shared between host computer ( your PC / MAC ) and the virtual machines.

`
sh housekeeping/createFoldersMac.sh
`

It contains scripts to create folders and grant access to yourself.

```
sudo mkdir -p ${DOCKER_HOST_BASE}/jenkins/documents

sudo mkdir -p ${DOCKER_HOST_BASE}/jenkins/home

sudo mkdir -p ${DOCKER_HOST_BASE}/jenkins/.ssh

```

if you want to change the path, can use the variable JENKIN_FOLDER
`JENKIN_FOLDER=j3 sh housekeeping/createFoldersMac.sh`


##Create and Start Jenkins service

###Understand what will be created

first we will use the script `jenkins/start-jenkins.sh`

####How it start docker
```
DOCKER_SOCKET=/var/run/docker.sock
HTTP_PORT=4080
DATA_FOLDER=/private/jenkins/home
HOME_FOLDER=/private/jenkins/documents
SSH_HOME=/private/jenkins/.ssh
docker run --rm -d --name local_jenkins -u root -p ${HTTP_PORT}:8080 -v ${SSH_HOME}:/root/.ssh -v ${DATA_FOLDER}:/var/jenkins_home -v ${DOCKER_SOCKET}:/var/run/docker.sock -v ${HOME_FOLDER}:/home jenkinsci/blueocean
```

This command started a jenkins server named *local_jenkins* on port 4080 and mapped some folders from host to jenkins.
With the `--rm` command, the container instance will be auto deleted while the stage will still be presisted with those mapped folders. 

Most important, we have grant jenkins the access to the docker by granting access to `/var/run/docker.sock` socket. ( this is not tested on windows, but there are sources saying it works on: https://jenkins.io/doc/tutorials/build-a-node-js-and-react-app-with-npm/#on-windows  Feedbacks are welcomed.)


####How to grant access to git servers
```
docker exec local_jenkins cat /root/.ssh/id_rsa.pub || \
    ( docker exec local_jenkins mkdir -p /root/.ssh && \
        docker exec local_jenkins ssh-keygen -t rsa -f /root/.ssh/id_rsa && \
        docker exec local_jenkins cat /root/.ssh/id_rsa.pub )

```
`docker exec <container name/id>` means start a command inside that container. 

Above, the script will first try to print out the existing SSH public key `/root/.ssh/id_rsa.pub`.  
    If cannot find any, will create the folder `/root/.ssh`, 
    generate a new private key `/root/.ssh/id_rsa`, 
    and print out the public key.

These steps ensure you have a unique ssh key per machines, you can disable any of them one by one. 
If you are using bitbucket, goes to BitBucket Setting => SSH Keys => Add Key,
copy from `ssh-rsa ... ` and paste to the Key textarea.

![add SSH key to bitbucket][../../raw/0290e57138f7d592985cd6f972e580d4ab6fdbc4/imges/bitbucket.png]

####How to configure the port and paths of docker

The script observes on enviorment variables, so that you can change port and folders when needed.

```
if [ -z "${JENKIN_DOCKER_HTTP_PORT}" ]; then 
    HTTP_PORT=4080
else 
    HTTP_PORT=${JENKIN_DOCKER_HTTP_PORT}
fi
```

For example if you run a second instance:
```
JENKIN_DOCKER_HTTP_PORT=5080 JENKIN_INST_NAME=j2 sh jenkins/start-jenkins.sh
```
The jenkin will be web admin panel mapped to port 5080.

####How it say yes for first ssh connection to git servers

When a new virtual machine SSH to a server, it will ask your confirmation.
This could block your jenkins pipeline and we make a solution as follow.

There is another script file `jenkins/ssh-client-init.sh`, it runs `ssh-keyscan` and inject public keys into known_hosts

```
ssh-keyscan -t rsa bitbucket.org > /root/.ssh/known_hosts
ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
```

###Start your jenkins

Thanks for your patient, you shall understand every scripts before run.  Now please start the jenkins together:

1. `sh jenkins/start-jenkins.sh`
2. add SSH key to git server
3. visit http://localhost:4080/ 
4. for first login, the admin panel will ask for password. The script shall already print it to the terminal.


###Create jenkins pipeline

Here we will cover basic pipeline involve starting a server, run different tests in parallel.   *Yes, in parallel! *  For complex multitiered system, you can checkout multiple projects in parallel and each run their own unit test.  Then when everyone is ready and without critical error, run a visual testing.

For the structure to create parallel pipeline tasks, we had seen a few some variations on the Net.  After some tests, this is a working version you can remember in 2 lines.

* stages -> stage('') -> steps , for normal steps
* stages -> stage('') -> parallel -> stage('') -> steps , for parallel steps

Now, let create it together:
1. First let create a **pipeline** project. *(note: never use space in item name, this may require extra care when writing bash scripts.)*
2. Go to configure, scroll down to Pipeline
3. copy the following Pipeline script into the text area. It helps 2 things
    1. clone your repo into a folder called *backend*.
    2. clean up the workspace after run, no matter success or not. 
```
pipeline {
    agent any 
    stages {
        stage('Prepare') {
            steps {
                sh 'rm -rf backend'
                sh 'git clone https://github.com/jasonlamkk/jenkins-pipeline-tutorial-restful-backend.git backend'
            }
        }
        stage('multi-tier-in-parallel') {
           parallel{
                stage('backend') {
                    steps{
                        echo "backend unit test finish"
                    }
                }
                stage('frontend'){
                    steps{
                        echo "frontend unit test not written"
                    }
                }
            }
        }
        stage('Integrated Test') {
            steps{
                echo "Integrated Test not written"
            }
        }
    }
    post {
        always {
            sh 'rm -rf backend'
        }
    }
}
```

4. Save the changes and click **Build Now**
5. Look at the **Build History** and celebrate your first success
### (optional) Auto create docker images

Although docker images do not need to be created very often, it is a good practice to grant some self-heal ability any automated things.  The following step will detect and create required image (append it after `git clone ...`): 
```
                sh '''
exists=`docker images | grep restful-backend | wc -l`
if [ $exists -eq 0 ]; then
    cd backend
    docker build -t restful-backend .
    cd ..
fi
'''
```

### Add Backend Server to the pipeline

In this session, we will run json-server to mimic a backend service and also run a simple unit test on it:

The logic flow is as follow 

1. Prepare

 1.1. check out source code

 1.2. detect if images is ready, build it if not
 
 1.3. stop previous container if already running
 
 1.4. start the containers
 
  1.4.1. after start, copy files from repo to containers. ( Remember, we prefer copy small source files over to a nearly ready project folder > over `yard/npm/composer` install from scratch > over store external code in repository.)
  
  1.4.2. finally, start services you will use. ( Due to we need to copy files, start service is not a command embedded in docker. This is a hack for testing environment only. This shall be different from production docker images, and shall force you to make another set of images optimised for production performance. )
  
2. *Run unit tests in parallel* ( as there shall be no dependences )

3. *Integrated Test* (when eveny service is ready) 

4. use a post pipeline, always-run task to clean up everything. ( leave no side-effect after each run )

update the pipeline script as follow:

```
pipeline {
    agent any 
    stages {
        stage('Prepare') {
            steps {
                sh 'rm -rf backend'
                sh 'git clone https://github.com/jasonlamkk/jenkins-pipeline-tutorial-restful-backend.git backend'
                sh '''
echo "Check Docker Image"
imageName=restful-backend
exists=`docker images | grep ${imageName} | wc -l`
if [ $exists -eq 0 ]; then
    cd backend
    docker build -t ${imageName} .
    cd ..
fi

echo "Stop Container Instance in case old one exists"
cd backend
containerName=json-api-server
exists=`docker ps | grep ${containerName} | wc -l`
if [ $exists -gt 0 ]; then
    docker stop ${containerName}
fi

echo "Start Backend Container Instance but not the server"
docker run --name=${containerName} --rm -d ${imageName}

echo "Copy latest changes"
currentDirectory=$(pwd)
for file in $(< ${currentDirectory}/copyfiles.txt)
do
  docker cp "${currentDirectory}/code/${file}" "${containerName}:/code/${file}"
done
cd ..

echo "Start Service"

docker exec -d ${containerName} sh /code/start-server-inside-docker.sh
pidExists=0
while [ $pidExists -eq 0 ]
do 
    sleep 1
    pidExists=$(docker exec json-api-server ls | grep pid.out | wc -l)
done
'''
            }
        }
        stage('multi-tier-in-parallel') {
           parallel{
                stage('backend') {
                    steps{
                        sh 'docker exec json-api-server sh run-test-inside-docker.sh'
                        echo "backend unit test finish"
                    }
                }
                stage('frontend'){
                    steps{
                        sh 'sleep 1'
                        echo "frontend unit test not written"
                    }
                }
            }
        }
        stage('Integrated Test') {
            steps{
                echo "Integrated Test not written"
                sh 'docker exec json-api-server sh stop-server-inside-docker.sh'
            }
        }
    }
    post {
        always {
            sh 'docker stop json-api-server'
            sh 'rm -rf backend'
        }
    }
}
```

##In conclusion

You now have a ready to use CI pipeline based on opensource tool chain, which can be deployed free of charge.

![add SSH key to bitbucket][../../raw/0290e57138f7d592985cd6f972e580d4ab6fdbc4/imges/bitbucket.png]

You deployed a very easy to use NodeJS json-server, and a unit test based on `jest`. We will cover them in detail in later blog posts. 
You may also notice a few important things when growing your pipeline:
* You will meet constraints when developing and dockerizing your services. Yet, these force you to create decoupled tiers. 
* 