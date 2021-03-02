#!/bin/bash

#
# 2020-08-14
# Here's how to create my flyem development environment from scratch.
#

set -x
set -e

WORKSPACE=/Users/bergs/workspace
ENV_NAME=flyem
DEVELOP_MODE=1

PYTHON_VERSION=3.7

conda_pkgs=(
    python=${PYTHON_VERSION}
    graph-tool=2.33
    umap-learn
    ngspice
    matplotlib
    'pandas<1'
    ipython
    jupyterlab
    ipywidgets
    bokeh
    hvplot
    plotly
    line_profiler
    pytest
    google-cloud-sdk
    'google-cloud-bigquery>=1.26.1'
    pynrrd
    dvid
    vol2mesh
    neuclease
    flyemflows
    neuprint-python
)

# neuroglancer dependencies are all available via conda,
# even though neuroglancer itself isn't.
ng_conda_pkgs=(
    sockjs-tornado # v1.0.6 is available via conda (defaults channel), but v1.0.7 is only available via pip at the moment
    'tornado=5'  # sockjs-tornado v1.0.6 isn't compatible with 6
    google-apitools
    nodejs
)

# Some cloudvol dependencies aren't on conda-forge,
# but these ones are
cloudvol_conda_pkgs=(
    boto3
    brotli
    brotlipy
    chardet
    crc32c
    gevent
    google-auth
    google-cloud-core
    'google-cloud-storage>=1.30'
    inflection
    json5
    protobuf
    psutil
    python-dateutil
    tenacity
    zstandard
)

conda create -y -n ${ENV_NAME} -c flyem-forge -c conda-forge ${conda_pkgs[@]} ${ng_conda_pkgs} ${cloudvol_conda_pkgs[@]}

# This is related to my personal credentials files.  Not portable!
#conda install -y -n ${ENV_NAME} $(ls ${WORKSPACE}/stuart-credentials/pkgs/stuart-credentials-*.tar.bz2 | tail -n1)

set +x
# https://github.com/conda/conda/issues/7980#issuecomment-492784093
eval "$(conda shell.bash hook)"
conda activate ${ENV_NAME}
set -x

jupyter nbextension enable --py widgetsnbextension
jupyter labextension install @jupyter-widgets/jupyterlab-manager

# plotly jupyterlab support
# 
jupyter labextension install jupyterlab-plotly@4.10.0
jupyter labextension install @jupyter-widgets/jupyterlab-manager plotlywidget@4.10.0


# These would all be pulled in by 'pip install neuroglancer cloud-volume',
# but I'll list the pip dependencies explicitly here for clarity's sake.
pip_pkgs=(
    neuroglancer
    cloud-volume # 2.0.0
    'cloud-files>=0.9.2'
    'compressed-segmentation>=1.0.0'
    'fastremap>=1.9.2'
    'fpzip>=1.1.3'
    DracoPy
    posix-ipc
    python-jsonschema-objects
)

pip install ${pip_pkgs[@]}

if [[ ! -z "${DEVELOP_MODE}" ]]; then

    develop_pkgs=(
        vol2mesh
        neuclease
        flyemflows
        neuprint-python
    )

    # Explicitly install the dependencies,
    # even though they're already installed.
    # This ensures that they get entries in the environment specs,
    # so they don't get automatically removed when we run 'conda update ...'.
    # (conda tends to automatically remove packages that aren't explicitly required by your environment specs.)
    for p in ${develop_pkgs[@]}; do
        conda install -y -n ${ENV_NAME} --only-deps -c conda-forge ${p}
    done

    echo "Uninstalling the following packages re-installing them in 'develop' mode: ${develop_pkgs[@]}"

    for p in ${develop_pkgs[@]}; do
        rm -rf ${CONDA_PREFIX}/lib/python${PYTHON_VERSION}/site-packages/${p}*
        cd ${WORKSPACE}/${p}
        python setup.py develop
    done

fi
