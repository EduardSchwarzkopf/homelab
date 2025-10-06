
curl -fsSL https://releases.jfrog.io/artifactory/api/gpg/key/public | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/jfrog.gpg
echo "deb https://releases.jfrog.io/artifactory/artifactory-debs $(lsb_release -cs) main" | tee -a /etc/apt/sources.list.d/artifactory.list

apt update

apt install default-jdk jfrog-artifactory-oss -y

mkdir -p ${APPLICATION_DATA_DIR} ${APPLICATION_CONFIG_DIR}

mv ${TEMP_SYSTEM_YAML_FILEPATH} ${ARTIFACTORY_HOME_DIR}/var/etc/system.yaml
mv ${TEMP_BINARYSTORE_FILEPATH} ${ARTIFACTORY_HOME_DIR}/var/etc/artifactory/binarystore.xml

ARTIFACTORY_USER="artifactory"
chown -R $ARTIFACTORY_USER:$ARTIFACTORY_USER  ${MOUNT_PATH}

systemctl start artifactory.service 
systemctl enable artifactory.service
