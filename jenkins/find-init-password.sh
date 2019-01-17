DATA_FOLDER=/var/jenkins_home
#check need to use initialAdminPassword
if [ -f ${DATA_FOLDER}/secrets/initialAdminPassword ]; then
    echo "Finish your docker setup by visiting http://localhost:${HTTP_PORT}/"
    echo "With the following initialAdminPassword:"
    cat ${DATA_FOLDER}/secrets/initialAdminPassword
else
    echo "jenkins ready at http://localhost:${HTTP_PORT}/"
fi

