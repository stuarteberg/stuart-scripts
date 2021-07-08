#!/bin/bash

#
# 2020-08-14
# Here's how to create my flyem development environment from scratch.
#
# Updated 2021-07

set -x
set -e

WORKSPACE=/Users/bergs/workspace
ENV_NAME=flyem
DEVELOP_MODE=0
CORE_ONLY=0
CLOUDVOL=0
INSTALLER=mamba

PYTHON_VERSION=3.7

core_conda_pkgs=(
    "python=${PYTHON_VERSION}"
    ipython
    jupyterlab
    nodejs
    matplotlib
    ipywidgets
    bokeh
    hvplot
    pandas
    pytest
    vol2mesh
    'libdvid-cpp>=0.3.post116'
    'neuclease>=0.4.post243'
    'flyemflows>=0.5.post.dev424'
    'neuprint-python>=0.4.14'
    #dvid
)

optional_conda_pkgs=(
    'graph-tool>=2.42'
    umap-learn
    ngspice
    plotly
    line_profiler
    'google-cloud-sdk'
    'google-cloud-bigquery>=1.26.1'
    pynrrd
)

# neuroglancer dependencies are all available via conda,
# even though neuroglancer itself isn't.
ng_conda_pkgs=(
    'sockjs-tornado' # v1.0.7 is available via flyem-forge (and soon conda-forge)
    tornado
    'google-apitools'
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

if [[ ! -z "${CORE_ONLY}" && ${CORE_ONLY} != "0" ]]; then
    ${INSTALLER} create -y -n ${ENV_NAME} -c flyem-forge -c conda-forge ${core_conda_pkgs[@]}
elif [[ ! -z "${CLOUDVOL}" && ${CLOUDVOL} != "0" ]]; then
    ${INSTALLER} create -y -n ${ENV_NAME} -c flyem-forge -c conda-forge ${core_conda_pkgs[@]} ${optional_conda_pkgs[@]} ${ng_conda_pkgs[@]} ${cloudvol_conda_pkgs[@]}
else
    ${INSTALLER} create -y -n ${ENV_NAME} -c flyem-forge -c conda-forge ${core_conda_pkgs[@]} ${optional_conda_pkgs[@]} ${ng_conda_pkgs[@]}
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

if [[ ! -z "${CORE_ONLY}" && ${CORE_ONLY} != "0" ]]; then
    echo "Skipping plotly extensions"
else
    # plotly jupyterlab support
    #
    jupyter labextension install jupyterlab-plotly
    jupyter labextension install @jupyter-widgets/jupyterlab-manager plotlywidget
fi

# These would all be pulled in by 'pip install neuroglancer cloud-volume',
# but I'll list the pip dependencies explicitly here for clarity's sake.
pip_pkgs=(
    neuroglancer
)

if [[ ! -z "${CLOUDVOL}" && ${CLOUDVOL} != "0" ]]; then
    pip_pkgs+=(
        cloud-volume # 2.0.0
        'cloud-files>=0.9.2'
        'compressed-segmentation>=1.0.0'
        'fastremap>=1.9.2'
        'fpzip>=1.1.3'
        DracoPy
        posix-ipc
        python-jsonschema-objects
    )
fi

if [[ ! -z "${CORE_ONLY}" && ${CORE_ONLY} != "0" ]]; then
    echo "Skipping optional pip installs, including neuroglancer"
else
    pip install ${pip_pkgs[@]}
fi

if [[ ! -z "${DEVELOP_MODE}" && ${DEVELOP_MODE} != "0" ]]; then

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
        ${INSTALLER} install -y -n ${ENV_NAME} --only-deps -c flyem-forge -c conda-forge ${p}
    done

    echo "Uninstalling the following packages re-installing them in 'develop' mode: ${develop_pkgs[@]}"

    for p in ${develop_pkgs[@]}; do
        rm -rf ${CONDA_PREFIX}/lib/python${PYTHON_VERSION}/site-packages/${p}*
        cd ${WORKSPACE}/${p}
        python setup.py develop
    done

fi
