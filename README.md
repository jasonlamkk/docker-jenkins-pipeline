#Kickstart Jenkins CI Pipeline with Docker(s) ( part 1/3 )

##Introduction

Throughout these series, we will try to build a CI pipeline with Jenkins and Dockers.

If you can master them, you will be able to test any multi-tiered application on a single computer.

##Level: Beginner to Intermediate. 

Beginners should be able to get the setup working using Copy-and-Paste.

We recommend to have basic understanding of the concepts first and do encourage making changes to the scripts to fit your projects settings.

##Terminologies

**Jenkins** is an open source CI server which offers a simple way to set up a Continuous Integration and Continuous Delivery environment for almost any combination of languages and source code repositories. For beginners, it may be easier to understand if you treat it as a task scheduler. You can migrate your daily works, such as *running unit tests*, *building software releases*, or *copying files to servers*, into jenkins.

**Docker**  <a name="docker"></a> is a software that performs operating-system-level virtualisation, known as **containerization**.  

**Continuous Delivery Pipeline** in CI are automated processes for getting the software from source control up to deployment in your servers for consumers (which can be other servers or end users).

**Jenkins Pipeline** <a name="pipeline"></a> is a newer suite of features in Jenkins to implement CD pipelines in a single script file. You no longer need to set up a number of different plugins just to get through the whole CI process.

##Why Docker 

* Complex systems usually consist of multiple tiers using different toolchains
* Docker can help simulate these tiers on single computer or machine
* Consumes less resources compared to using multiple virtual machines
* Provides a way to interact, monitor, and control all machines with simple commands
* Steps to setup are repeatable

_may reference to official site for detail about [What is docker](https://www.docker.com/why-docker)_

Using Docker will bring you the following advantages:
* Ability to separate complex and possibly conflicting toolchains into their own sandboxes called **containers**.
* Faster Pull->Build->Test cycle. 
Instead of loading dependencies every time before building.
* Mimic production architecture with different tiers of service as closely as possible.

##Why Jenkins + Docker

* Open-source
* Popular and well known
* Easy to migrate your workflows to CI without dependency on specific brand of tools.
* Trigger or orchestrate any task with shell scripting. 

##What you can get from this tutorial

* Quickly set up a CI environment with open source toolchain in a repeatable way
* Create post-execution scripts on Jenkins without using extra plugins
* Create parallel CI tasks
* Create a restful API with NodeJS in a few minutes
* Srite a simple test for the API with jasmine 
* Shorten project build time 
* Some bash automation  

##What will be covered on the next part of the series 

* Create a simple web app 
* Perform visual testing for web app
* Recap parallel tasks on Jenkins
* Demonstrate a multi-tier CI Pipeline  

Eventually, we will scale your setup to be able to handle multiple components that were developed using different tool-chains.

##Prerequisite

* Download and Install Docker Community Edition ( [Mac (https://download.docker.com/mac/stable/Docker.dmg)]  / [Win (https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe)] )
We expect you can use docker without `sudo`.
If you are using Linux and haven't added yourself into the docker group, do so and restart your terminal.
* clone GitHub - NodeJS API service ( coming soon )
* clone GitHub - Tutorial scripts
`git clone git@bitbucket.org:jlam-palo-it/jenkins-pipeline-dockers.git && cd jenkins-pipeline-dockers`

##Housekeeping

The Jenkins docker will presist all settings to the host disk and can be shutdown and removed to save disk space. Therefore, we begin by creating folders which will be shared between the host computer ( your PC / MAC ) and containers.

`
sh housekeeping/createFoldersMac.sh
`

This script contains commands to create folders and grant access to yourself.

```
sudo mkdir -p ${DOCKER_HOST_BASE}/jenkins/documents

sudo mkdir -p ${DOCKER_HOST_BASE}/jenkins/home

sudo mkdir -p ${DOCKER_HOST_BASE}/jenkins/.ssh

```

if you want to change the path, can use the variable JENKIN_FOLDER
`JENKIN_FOLDER=j3 sh housekeeping/createFoldersMac.sh`


##Create and Start Jenkins service

###Creation and Setup

First, we will use the script `jenkins/start-jenkins.sh`.

####What the script does
```
DOCKER_SOCKET=/var/run/docker.sock
HTTP_PORT=4080
DATA_FOLDER=/private/jenkins/home
HOME_FOLDER=/private/jenkins/documents
SSH_HOME=/private/jenkins/.ssh
docker run --rm -d --name local_jenkins -u root -p ${HTTP_PORT}:8080 -v ${SSH_HOME}:/root/.ssh -v ${DATA_FOLDER}:/var/jenkins_home -v ${DOCKER_SOCKET}:/var/run/docker.sock -v ${HOME_FOLDER}:/home jenkinsci/blueocean
```

Aside from setting some environment variables, the script ran a long command at the end. Here's what it did:
 - started a container instance named *local_jenkins* which contain contents from image `jenkinsci/blueocean`
 - `-d` run in detached mode ( Run container in background and print container ID /var/run/docker.sock )
 - `-u root` switched to root user ( which allow jenkins to access )
 - `-p ${HTTP_PORT}:8080` expos the port for you to access
 - `-v ${path_in_host}:${path_inside_container}` mount a volume from host to container
 - visit [docker docs](https://docs.docker.com/engine/reference/commandline/run/#options) for more available options

Most importantly, we have to grant Jenkins the access to Docker by granting access to `/var/run/docker.sock` socket. ( this is not tested on windows, but there are sources saying it works on: https://jenkins.io/doc/tutorials/build-a-node-js-and-react-app-with-npm/#on-windows  Feedbacks are welcomed.)

####Grant access to git repositories
In most of the Jenkins single tier project, you only need to interact with one upstream git server.

But when works with pipeline, it is very likely you will be pulling a few repositories and combine them to form your testing enviorment.

To better manage the access control, we will treat jenkins as a separated git user, and access read access of to him as follow.

First, we will try to print out the existing SSH public key `/root/.ssh/id_rsa.pub`.  
    If cannot find any, will create the folder `/root/.ssh`, 
    generate a new private key `/root/.ssh/id_rsa`, 
    and print out the public key.

(This is part of the automated script you don't need to type it :)
```
docker exec local_jenkins cat /root/.ssh/id_rsa.pub || \
    ( docker exec local_jenkins mkdir -p /root/.ssh && \
        docker exec local_jenkins ssh-keygen -t rsa -f /root/.ssh/id_rsa && \
        docker exec local_jenkins cat /root/.ssh/id_rsa.pub )

```

These steps ensure you have a unique ssh key per machine, you can disable any of them individually. 

Second, you need to add this public key to your git server: 

If you are using BitBucket, go to your BitBucket cloud Setting => SSH Keys => Add Key,
copy `ssh-rsa ... ` from your terminal and paste to the textarea named Key.

![add SSH key to bitbucket](https://bitbucket.org/jlam-palo-it/jenkins-pipeline-dockers/raw/983f5a01b9d2eff11aa4788e77e2cf902f2c567a/images/bitbucket.png)

####How to configure the port and paths for Docker

The script observes on environment variables so that you can change port and folders when needed.

```
if [ -z "${JENKIN_DOCKER_HTTP_PORT}" ]; then 
    HTTP_PORT=4080
else 
    HTTP_PORT=${JENKIN_DOCKER_HTTP_PORT}
fi
```

For example, if you want to run a second instance:
```
JENKIN_DOCKER_HTTP_PORT=5080 JENKIN_INST_NAME=j2 sh jenkins/start-jenkins.sh
```
The Jenkins web admin panel will be mapped to port 5080.

####Initiate access from Jenkins to your Git servers.

Whenever a new machine performs it's first SSH requests to a server, it will ask your confirmation to authorize add the server to your machine's trusted hosts.
If you do not trigger this access confirmation, it could block your Jenkins pipeline. To fix this, we made a solution as follows:

Run the script file `jenkins/ssh-client-init.sh`. It runs `ssh-keyscan` and inject public keys into known_hosts

```
ssh-keyscan -t rsa bitbucket.org > /root/.ssh/known_hosts
ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
```

###Starting Jenkins

After the preparation, we are now ready to run Jenkins. Use the following steps:

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
* when all the projects are ready (and without errors), run a visual testing. (visual testing will be covered in another post)

For the structure to create parallel pipeline tasks, try to remember these 2 lines.

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

Although docker images do not need to be created very often, it is a good practice to grant some self-heal ability any automated things.  The following step will detect and create the required image (append it after `git clone ...`) (This step was included in the full version below.): 
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

    1. check out the source code

    2. detect if images are ready, build if not

    3. stop previous container if you already have one running

    4. start the containers

        * after starting, copy files from repo to containers. ( Remember, we prefer to copy small source files over to a nearly ready project folder > over `yard/npm/composer` install from scratch > over store external code in the repository.)

        * finally, start the services you will use. ( Since we need to copy files, "start application server" is not a command embedded in docker. This is a hack for testing environment only. This shall be different from production docker images and shall force you to make another set of docker images optimised for production performance. )
  
2. ___*Run unit tests in parallel*___ ( as there shall be no dependencies )

3. ___*Integrated Test*___ (when every service is ready) 

4. ___Clean-up___ Use a post pipeline, always-run task to clean up everything. ( leave no side-effect after each run )

update the pipeline script as follows:

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

You now have a ready-to-use CI pipeline based on open-source tool chain, which can be deployed free-of-charge!

![pipeline result](https://bitbucket.org/jlam-palo-it/jenkins-pipeline-dockers/raw/983f5a01b9d2eff11aa4788e77e2cf902f2c567a/images/pipeline-result.png)

You deployed a very easy to use NodeJS json-server, and a unit test based on `jest`. We will cover them in detail in later blog posts. 

You may also notice a few important things when growing your pipeline:

* You will meet constraints when developing and dockerizing your services. These forces you to create decoupled service tiers. 

* Avoid including third-party libraries in your repositories. Try to prevent npm install in your pipeline which could be very slow.

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
