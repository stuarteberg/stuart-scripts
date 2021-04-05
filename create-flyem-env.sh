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
CORE_ONLY=0

PYTHON_VERSION=3.7

core_conda_pkgs=(
    python=${PYTHON_VERSION}
    ipython
    jupyterlab
    matplotlib
    ipywidgets
    bokeh
    hvplot
    'pandas<1'
    vol2mesh
    'neuclease>=0.4.post128'
    flyemflows
    neuprint-python
    dvid
    pytest
)

optional_conda_pkgs=(
    graph-tool=2.33
    umap-learn
    ngspice
    plotly
    line_profiler
    google-cloud-sdk
    'google-cloud-bigquery>=1.26.1'
    pynrrd
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

if [[ ${CORE_ONLY} == "1" ]]; then
    conda create -y -n ${ENV_NAME} -c flyem-forge -c conda-forge ${core_conda_pkgs[@]}
    #mamba create -y -n ${ENV_NAME} -c flyem-forge -c conda-forge ${core_conda_pkgs[@]}
else
    conda create -y -n ${ENV_NAME} -c flyem-forge -c conda-forge ${core_conda_pkgs[@]} ${optional_conda_pkgs[@]} ${ng_conda_pkgs} ${cloudvol_conda_pkgs[@]}
    #mamba create -y -n ${ENV_NAME} -c flyem-forge -c conda-forge ${core_conda_pkgs[@]} ${optional_conda_pkgs[@]} ${ng_conda_pkgs} ${cloudvol_conda_pkgs[@]}
fi

# This is related to my personal credentials files.  Not portable!
#conda install -y -n ${ENV_NAME} $(ls ${WORKSPACE}/stuart-credentials/pkgs/stuart-credentials-*.tar.bz2 | tail -n1)

set +x
# https://github.com/conda/conda/issues/7980#issuecomment-492784093
eval "$(conda shell.bash hook)"
conda activate ${ENV_NAME}
set -x

jupyter nbextension enable --py widgetsnbextension
jupyter labextension install @jupyter-widgets/jupyterlab-manager

if [[ ${CORE_ONLY} == "1" ]]; then
    echo "Skipping plotly extensions"
else
    # plotly jupyterlab support
    #
    jupyter labextension install jupyterlab-plotly@4.10.0
    jupyter labextension install @jupyter-widgets/jupyterlab-manager plotlywidget@4.10.0
fi

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

if [[ ${CORE_ONLY} == "1" ]]; then
    echo "Skipping optional pip installs, including neuroglancer"
else
    pip install ${pip_pkgs[@]}
fi

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
        conda install -y -n ${ENV_NAME} --only-deps -c flyem-forge -c conda-forge ${p}
    done

    echo "Uninstalling the following packages re-installing them in 'develop' mode: ${develop_pkgs[@]}"

    for p in ${develop_pkgs[@]}; do
        rm -rf ${CONDA_PREFIX}/lib/python${PYTHON_VERSION}/site-packages/${p}*
        cd ${WORKSPACE}/${p}
        python setup.py develop
    done

fi
