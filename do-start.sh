#!/bin/bash

echo "installing .."

# replace conf files from installer with environment-specific files
# mounted from the hosting VM

if [[ -d config ]]; then
    cp config/*.conf .
fi

if [[ -f config/drools-preinstall.sh ]] ; then
    echo "found preinstallation script"
    bash config/drools-preinstall.sh
fi

# remove broken symbolic links if any in data directory
if [[ -d ${POLICY_HOME}/config ]]; then
    echo "removing dangling symbolic links"
    find -L ${POLICY_HOME}/config -type l -exec rm -- {} +
fi

apps=$(ls config/apps*.zip 2> /dev/null)
for app in $apps
do
    echo "Application found: ${app}"
    unzip -o ${app}
done

feats=$(ls config/feature*.zip 2> /dev/null)
for feat in $feats
do
    echo "Feature found: ${feat}"
    cp ${feat} .
done

echo "docker install at ${PWD}"

./docker-install.sh

source ${POLICY_HOME}/etc/profile.d/env.sh


# allow user to override the key or/and the trust stores

if [[ -f config/policy-keystore ]]; then
    cp -f config/policy-keystore ${POLICY_HOME}/etc/ssl
fi

if [[ -f config/policy-truststore ]]; then
    cp -f config/policy-truststore ${POLICY_HOME}/etc/ssl
fi

# allow user to override all or some aaf configuration

if [[ -f config/aaf.properties ]]; then
    cp -f config/aaf.properties ${POLICY_HOME}/config/aaf.properties
fi

if [[ -f config/aaf-cadi.keyfile ]]; then
    cp -f config/aaf-cadi.keyfile ${POLICY_HOME}/config/aaf-cadi.keyfile
fi

if [[ -f config/drools-tweaks.sh ]] ; then
    echo "Executing tweaks"
    # file may not be executable; running it as an
    # argument to bash avoids needing execute perms.
    bash config/drools-tweaks.sh
fi

echo "Starting processes"
features enable controller-logging distributed-locking eelf healthcheck lifecycle mdc-filters pooling-dmaap test-transaction

policy start

tail -f /dev/null
