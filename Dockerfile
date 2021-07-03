FROM ubuntu:20.04

## Arguments
ARG ZSDK_VERSION=0.12.4
ARG LLVM_VERSION=12
ARG WGET_ARGS="-q --show-progress --progress=bar:force:noscroll --no-check-certificate"

ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND noninteractive

# RUN dpkg --add-architecture i386 && \
RUN	apt-get -y update && \
    apt-get -y upgrade && \
    apt-get install --no-install-recommends -y \
            python3-pip cmake git gpg-agent libncurses5 locales \
			lsb-release make ninja-build software-properties-common \
			ssh sudo unzip wget xz-utils && \
    apt-get clean && \
	apt-get autoremove --purge

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

## Python3
RUN pip3 install --no-cache-dir --upgrade wheel pip && \
    pip3 install --no-cache-dir -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements.txt && \
    rm -rf $(pip cache dir)

## LLVM & clang-format
RUN wget ${WGET_ARGS} https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh ${LLVM_VERSION} && \
    rm llvm.sh && \
    apt-get install --no-install-recommends -y clang-format-12 && \
    apt-get clean && \
	apt-get autoremove --purge


## get run-clang-format
RUN wget https://raw.githubusercontent.com/Sarcasm/run-clang-format/master/run-clang-format.py -O /usr/local/bin/run-clang-format.py && \
    chmod 755 /usr/local/bin/run-clang-format.py

## Zephyr SDK (only arm toolchain)
RUN wget ${WGET_ARGS} https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-toolchain-arm-${ZSDK_VERSION}-x86_64-linux-setup.run && \
    chmod +x "zephyr-toolchain-arm-${ZSDK_VERSION}-x86_64-linux-setup.run" && \
    sh "zephyr-toolchain-arm-${ZSDK_VERSION}-x86_64-linux-setup.run" --quiet -- -d /opt/toolchains/zephyr-sdk-${ZSDK_VERSION} && \
    rm "zephyr-toolchain-arm-${ZSDK_VERSION}-x86_64-linux-setup.run"

## Zephyr
RUN west init /workspaces/zephyrproject && \
    cd /workspaces/zephyrproject && \
    west update && \
    west zephyr-export && \
	rm -rf /workspaces/zephyrproject/modules/lib/tensorflow && \
    rm -rf /workspaces/zephyrproject/modules/hal/espressif && \
    rm -rf /workspaces/zephyrproject/modules/hal/silabs && \
    rm -rf /workspaces/zephyrproject/modules/hal/stm32 && \
    pip3 install --no-cache-dir -r /workspaces/zephyrproject/zephyr/scripts/requirements.txt && \
    rm -rf $(pip cache dir) && \
    mkdir -m777 /workspaces/zephyrproject/zephyr/.cache

## install nrfjprog and Segger JLink Tools
RUN wget ${WGET_ARGS} https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-command-line-tools/sw/Versions-10-x-x/10-12-1/nRFCommandLineTools10121Linuxamd64.tar.gz && \
    tar xvfz nRFCommandLineTools10121Linuxamd64.tar.gz ./JLink_Linux_V688a_x86_64.deb ./nRF-Command-Line-Tools_10_12_1_Linux-amd64.deb && \
	dpkg -i JLink_Linux_V688a_x86_64.deb && \
    dpkg -i nRF-Command-Line-Tools_10_12_1_Linux-amd64.deb && \
    ln -s /opt/nrfjprog/nrfjprog /usr/local/bin/nrfjprog && \
    ln -s /opt/mergehex/mergehex /usr/local/bin/mergehex && \
    rm nRFCommandLineTools10121Linuxamd64.tar.gz JLink_Linux_V688a_x86_64.deb nRF-Command-Line-Tools_10_12_1_Linux-amd64.deb

## add user
RUN groupadd -g $GID -o user && \
    useradd -u $UID -m -g user -G plugdev user && \
	echo 'user ALL = NOPASSWD: ALL' > /etc/sudoers.d/user && \
	chmod 0440 /etc/sudoers.d/user

# ## bash-git-prompt
RUN git clone https://github.com/magicmonty/bash-git-prompt.git /home/user/.bash-git-prompt --depth=1 && \
    echo '\n \
        if [ -f "$HOME/.bash-git-prompt/gitprompt.sh" ]; then \n \
            GIT_PROMPT_ONLY_IN_REPO=1 \n \
            source $HOME/.bash-git-prompt/gitprompt.sh \n \
        fi\n' >> /home/user/.bashrc

# Set environment variables
ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}
ENV GNUARMEMB_TOOLCHAIN_PATH=/opt/toolchains/${GCC_ARM_NAME}
ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig
ENV ZEPHYR_BASE=/workspaces/zephyrproject/zephyr
