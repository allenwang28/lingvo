FROM tensorflow/tensorflow:custom-op-ubuntu16

ENV GITHUB_BRANCH="master"
ENV PYTHON_VERSION="3"
ENV PYTHON_MINOR_VERSION="9"
ENV PIP_MANYLINUX2010="1"

# There are some problems with the python3 installation from custom-op-ubuntu16.
# Remove it and install new ones.
RUN apt-get remove --purge -y python3.5 python3.6
RUN rm -f /etc/apt/sources.list.d/jonathonf-ubuntu-python-3_6-xenial.list
RUN apt-key del F06FC659

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA6932366A755776
RUN echo "deb http://ppa.launchpad.net/deadsnakes/ppa/ubuntu xenial main" > /etc/apt/sources.list.d/deadsnakes-ppa-xenial.list
RUN apt-get update && apt-get install -y python3.8 python3.8-distutils

RUN git clone --single-branch --branch master https://github.com/tensorflow/tensorflow.git --depth=1
WORKDIR /tensorflow
RUN install pip six 'numpy<1.19.0' wheel setuptools mock 'future>=0.17.1'

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py

# Download and install bazel.
RUN wget https://github.com/bazelbuild/bazel/releases/download/3.7.2/bazel-3.7.2-installer-linux-x86_64.sh > /dev/null
RUN bash bazel-3.7.2-installer-linux-x86_64.sh


RUN for python in python3.8; do \
      $python get-pip.py && \
      $python -m pip install --upgrade pip setuptools auditwheel && \
      $python -m pip install --upgrade \
        attrs \
        dataclasses \
        graph-compression-google-research \
        grpcio \
        matplotlib \
        mock \
        model-pruning-google-research \
        numpy \
        sympy \
        twine && \
      $python -m pip install pip six 'numpy<1.19.0' wheel setuptools mock 'future>=0.17.1' \
      $python -m pip install keras_applications --no-deps \
      $python -m pip install keras_preprocessing --no-deps \
      bazel build --config=opt --distinct_host_configuration=true --define=framework_shared_object=true --define=with_tpu_support=true --copt=-DLIBTPU_ON_GCE //tensorflow/tools/pip_package:build_pip_package \
      ./bazel-bin/tensorflow/tools/pip_package/build_pip_package --nightly_flag /tmp/tensorflow_pkg \
      $python -m pip install /tmp/tensorflow_pkg/*.whl \
      $python -m pip install tensorflow-datasets tensorflow-text --no-deps; \
    done

WORKDIR "/tmp/lingvo"
