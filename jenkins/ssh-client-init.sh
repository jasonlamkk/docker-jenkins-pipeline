#ssh-client-init.sh

# Add domains to known_hosts
ssh-keyscan -t rsa bitbucket.org > /root/.ssh/known_hosts
ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
