DATA_FOLDER=/var/jenkins_home
#check need to use initialAdminPassword
if [ -f ${DATA_FOLDER}/secrets/initialAdminPassword ]; then
    echo "With the following initialAdminPassword:"
    cat ${DATA_FOLDER}/secrets/initialAdminPassword
else
    echo "Jenkins has been initialized"
fi

