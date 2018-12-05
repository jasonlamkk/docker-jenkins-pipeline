#Kickstart Jenkins CI Pipeline with Docker(s) ( part 1/3 ) v1.1

Level: Beginner to Intermediate. 
___Might be nice for the beginners to explain the advantages of jenkins and docker and how it can make things easy___


Beginners should be able to get it working by Copy-and-Paste.
We do encourage understanding of the concepts and making changes to the scripts to fit your projects settings.

##What you can get from this tutorial

* quickly set up a CI environment with open source toolchain in a repeatable way
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
* demonstrate a multi-tier CI Pipeline  

##Introduction

To fully implement CI for a multi-tier project, you need to enable Jenkins or your CI server to interact with different components developed with different tool-chains. There are a few ways to do so.

* Install these environments on the CI server
* having multiple children nodes attached to the CI server
* or what we will demonstrate today: docker-ize everything and keep your CI tool slim 
 
**Jenkins** is an open source CI server which offers a simple way to set up a continuous integration and continuous delivery environment for almost any combination of languages and source code repositories. For beginners, it may be easier to understand if you treat it as a task scheduler.  You can migrate your daily works, such as *running unit tests*, *building software releases*, *copy files to servers*, to jenkins.

**Docker** is a software that performs operating-system-level virtualisation, known as **containerization**.  

**Continuous Delivery Pipeline** in CI are automated processes for getting the software from source control through deployment to end users.
**Jenkins Pipeline** <a name="pipeline"></a> is a newer suite of features in Jenkins to implement these pipelines in a single script file. You no longer need to set up a few different plugins to get through the while CI process.

Using docker will bring you the following advantages:
* separate complex and possible conflicting toolchains into straightforward virtual machines called **containers**.
* faster Pull->Build->Test cycle.  Instead of update dependency, every time before build
* closely mimic production architectures with different tiers of service

##Prerequisite

* Download and Install Docker Community Edition ( [Mac (https://download.docker.com/mac/stable/Docker.dmg)]  / [Win (https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe)] )
We expect you can use docker without `sudo`.
If you are using Linux and haven't added yourself into the docker group, do so and restart your terminal.
* clone GitHub - NodeJS API service ( coming soon )
* clone GitHub - Tutorial scripts
`git clone git@bitbucket.org:jlam-palo-it/jenkins-pipeline-dockers.git && cd jenkins-pipeline-dockers`

##Housekeeping

The Jenkins docker shall presist all settings to host disk and can be shutdown and removed to save disk spaces. Therefore, we begin with creating folders which will be shared between the host computer ( your PC / MAC ) and virtual machines.

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

First, we will use the script `jenkins/start-jenkins.sh`.

####How it start docker
```
DOCKER_SOCKET=/var/run/docker.sock
HTTP_PORT=4080
DATA_FOLDER=/private/jenkins/home
HOME_FOLDER=/private/jenkins/documents
SSH_HOME=/private/jenkins/.ssh
docker run --rm -d --name local_jenkins -u root -p ${HTTP_PORT}:8080 -v ${SSH_HOME}:/root/.ssh -v ${DATA_FOLDER}:/var/jenkins_home -v ${DOCKER_SOCKET}:/var/run/docker.sock -v ${HOME_FOLDER}:/home jenkinsci/blueocean
```

This command
 - started a container instance named *local_jenkins* which contain contents from image `jenkinsci/blueocean`
 - `-d` run in detached mode ( Run container in background and print container ID /var/run/docker.sock )
 - `-u root` switched to root user ( which allow jenkins to access )
 - `-p ${HTTP_PORT}:8080` expos the port for you to access
 - `-v ${path_in_host}:${path_inside_container}` mount a volume from host to container
 - visit [docker docs](https://docs.docker.com/engine/reference/commandline/run/#options) for more available options

Most important, we have to grant Jenkins the access to the docker by granting access to `/var/run/docker.sock` socket. ( this is not tested on windows, but there are sources saying it works on: https://jenkins.io/doc/tutorials/build-a-node-js-and-react-app-with-npm/#on-windows  Feedbacks are welcomed.)

####How to grant access to git servers
In most jenkins tutorial, you will configure upstream git servers credentials per project. 

When using pipeline, we may work with multiple repositories with different credentials.

The workaround is treat jenkins as a new git user and manage access control on the cloud.

Below, we will first try to print out the existing SSH public key `/root/.ssh/id_rsa.pub`.  
    If cannot find any, will create the folder `/root/.ssh`, 
    generate a new private key `/root/.ssh/id_rsa`, 
    and print out the public key.

(This is part of the automated script you don't need to type it:)
```
docker exec local_jenkins cat /root/.ssh/id_rsa.pub || \
    ( docker exec local_jenkins mkdir -p /root/.ssh && \
        docker exec local_jenkins ssh-keygen -t rsa -f /root/.ssh/id_rsa && \
        docker exec local_jenkins cat /root/.ssh/id_rsa.pub )

```

These steps ensure you have a unique ssh key per machines, you can disable any of them one by one. 
If you are using bitbucket, go to your BitBucket cloud Setting => SSH Keys => Add Key,
copy `ssh-rsa ... ` from your terminal and paste to the textarea named Key.

![add SSH key to bitbucket](https://bitbucket.org/jlam-palo-it/jenkins-pipeline-dockers/raw/983f5a01b9d2eff11aa4788e77e2cf902f2c567a/images/bitbucket.png)

####How to configure the port and paths of docker

The script observes on environment variables so that you can change port and folders when needed.

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
The Jenkins will be web admin panel mapped to port 5080.

####How it says yes for first ssh connection to git servers

When a new virtual machine SSH to a server, it will ask your confirmation.
This could block your Jenkins pipeline and we make a solution as follow.

There is another script file `jenkins/ssh-client-init.sh`, it runs `ssh-keyscan` and inject public keys into known_hosts

```
ssh-keyscan -t rsa bitbucket.org > /root/.ssh/known_hosts
ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
```

###Start your Jenkins

Thank you for your patience, you shall understand every scripts before run.  

Now, please start the Jenkins together:

1. `sh jenkins/start-jenkins.sh`
2. Add SSH key to the git server
3. Visit http://localhost:4080/ 
4. For the first login, the admin panel will ask for the password. The script shall already print it to the terminal.
( You can also print the password again by `echo /private/jenkins/home/secretsinitialAdminPassword` on host machines)
5. Follow the screen instractions such as install recommended plugins.

###Create Jenkins pipeline

Here, we will cover how to run different tests in parallel. 

Which means you will be able to: 
* checkout multiple projects in parallel
* let each project run its own unit tests.
* when everyone is ready and without critical error, run a visual testing. (visual testing will be cover in another post)

For the structure to create parallel pipeline tasks, you can remember in 2 lines.

* `stages -> stage('') -> steps` , for normal steps
* `stages -> stage('') -> parallel -> stage('') -> steps` , for parallel steps

Now, let's create it together:
1. First, let's create a **pipeline** project. *(note: never use space in the item name, this may require extra care when writing bash scripts.)*
2. Go to `Configure`, scroll down to Pipeline
![Pipeline section](https://bitbucket.org/jlam-palo-it/jenkins-pipeline-dockers/raw/2b7d5a2e91df83cc02d69bf340fbf24e84fb7d28/images/pipelinesection.png)
3. copy the following Pipeline script into the text area. It helps with 2 things
    1. clone your repo into a folder called *backend*.
    2. clean up the workspace after a run, no matter success or not. 
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
           parallel {
                stage('backend') {
                    steps {
                        echo "backend unit test finish"
                    }
                }
                stage('frontend') {
                    steps {
                        echo "frontend unit test not written"
                    }
                }
            }
        }
        stage('Integrated Test') {
            steps {
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

Although docker images do not need to be created very often, it is a good practice to grant some self-heal ability any automated things.  The following step will detect and create the required image (append it after `git clone ...`): 
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

The logic flow is as follows:

1. ___Prepare___

 1.1. check out the source code

 1.2. detect if images are ready, build it if not
 
 1.3. stop the previous container if already running
 
 1.4. start the containers
 
  1.4.1. after start, copy files from repo to containers. ( Remember, we prefer to copy small source files over to a nearly ready project folder > over `yard/npm/composer` install from scratch > over store external code in the repository.)
  
  1.4.2. finally, start services you will use. ( Due to we need to copy files, start service is not a command embedded in docker. This is a hack for testing environment only. This shall be different from production docker images and shall force you to make another set of images optimised for production performance. )
  
2. ___*Run unit tests in parallel*___ ( as there shall be no dependencies )

3. ___*Integrated Test*___ (when every service is ready) 

4. ___Clean-up___ Use a post pipeline, always-run task to clean up everything. ( leave no side-effect after each run )

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
docker exec ${containerName} npm update
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
           parallel {
                stage('backend') {
                    steps {
                        sh 'docker exec json-api-server sh run-test-inside-docker.sh'
                        echo "backend unit test finish"
                    }
                }
                stage('frontend') {
                    steps {
                        sh 'sleep 1'
                        echo "frontend unit test not written"
                    }
                }
            }
        }
        stage('Integrated Test') {
            steps {
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

## Conclusion

You now have a ready-to-use CI pipeline based on open-source tool chain, which can be deployed free- of-charge!

![pipeline result](https://bitbucket.org/jlam-palo-it/jenkins-pipeline-dockers/raw/983f5a01b9d2eff11aa4788e77e2cf902f2c567a/images/pipeline-result.png)

You deployed a very easy to use NodeJS json-server, and a unit test based on `jest`. We will cover them in detail in later blog posts. 

You may also notice a few important things when growing your pipeline:

* You will meet constraints when developing and dockerizing your services. Yet, these force you to create decoupled service tiers. 

* Never include third-party libraries in your repositories. Try to prevent npm install in your pipeline which could be very slow.

* Code your plugins instead of Pipeline Editor. Treating your pipeline as code enforces good discipline and also opens up a new world of features, and you can trial run every script on the terminal.

* Ensure each action has no side effect and remember to stop and remove all containers which started within the pipeline. ( You can include `--rm` flag when starting them, so they will be deleted after stop.)

##Further improvement 

* __Node utilization__ , we assume you start this tutorial on your machine. you can optimize it by 

 * Do: All material work within a node

 * Acquire nodes within parallel steps, yet

 * Don’t: Use input within a node block

* __Plan for timeout__ , you can use this timeout block to prevent timeout occur `timeout(time:2, unit:'HOURS') { }`

* __Notification__ , you may add email to receive build test result

##Coming soon

Currently we only added backend tier and its unit test. In the upcoming series, we will 

* describe how to link frontend container to backend container or database container  

* how to capture screen and make a __Visual Testing__ .
