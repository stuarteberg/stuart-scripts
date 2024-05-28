#!/bin/bash

#
# 2020-08-14
# Here's how to create my flyem development environment from scratch.
#
# Updated 2024-05

set -x
set -e

WORKSPACE=/Users/bergs/workspace
ENV_NAME=flyem-312
#CONDA_CMD=create
CONDA_CMD=install

DEVELOP_MODE=0
CORE_CONDA_FORGE=1
CORE_FLYEM=1
OPTIONAL_CONDA_FORGE=1
NEUROGLANCER=1
CLOUDVOL=0
INSTALLER=conda

STUART_CREDENTIALS=0  # Non-portable stuff

PYTHON_VERSION=3.12

core_conda_pkgs=(
    "python=${PYTHON_VERSION}"
    ipython
    jupyterlab
    nodejs
    ipywidgets
    bokeh
    selenium     # Required for rendering bokeh plot images, also for neuroglancer's video tool
    firefox      # ditto
    geckodriver  # ditto
    datashader
    jupyter_bokeh
    hvplot
    pandas
    pytest
    lemon
    'zarr=2.18'
    matplotlib-base
    dill
    h5py
    vigra
    tensorstore
)

core_flyem_packages=(
    'dvid>=1.0'
    'vol2mesh>=0.1.post20'
    'libdvid-cpp>=0.5.post4'
    'neuclease>=0.6.post0.dev142'
    'flyemflows>=0.5.post0.dev571'
    'neuprint-python>=0.4.26'
)

optional_conda_pkgs=(
    graph-tool
    #'graspologic>=2.0'  # Sadly, not yet available for python-3.12
    umap-learn
    ngspice
    plotly
    line_profiler
    'google-cloud-sdk'
    'google-cloud-bigquery>=1.26.1'
    crcmod  # optional dependency of gsutil rsync, for faster checksums
    pynrrd
    cython
    anytree
    pot
    'gensim>=4.0'
    atomicwrites
    fastremap
    beartype
    brotli
    fastremap   # Cool, there's a conda package for this...
    future
    multiprocess
    orjson
    pathos
    pox
    ppft
    pysimdjson
    zfpy # This is optional, but if something brings it in via pip, it breaks numcodecs and zarr.
)

# neuroglancer dependencies are all available via conda,
# even though neuroglancer itself isn't.
ng_conda_pkgs=(
    'sockjs-tornado>=1.0.7'
    'tornado>=6'
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
    fastremap
)

PACKAGES=()
if [[ ! -z "${CORE_CONDA_FORGE}" && ${CORE_CONDA_FORGE} != "0" ]]; then
    PACKAGES+=("${core_conda_pkgs[@]}")
fi

if [[ ! -z "${CORE_FLYEM}" && ${CORE_FLYEM} != "0" ]]; then
    PACKAGES+=("${core_flyem_packages[@]}")
fi

if [[ ! -z "${OPTIONAL_CONDA_FORGE}" && ${OPTIONAL_CONDA_FORGE} != "0" ]]; then
    PACKAGES+=("${optional_conda_pkgs[@]}")
fi

if [[ ! -z "${NEUROGLANCER}" && ${NEUROGLANCER} != "0" ]]; then
    PACKAGES+=("${ng_conda_pkgs[@]}")
fi

if [[ ! -z "${CLOUDVOL}" && ${CLOUDVOL} != "0" ]]; then
    PACKAGES+=("${cloudvol_conda_pkgs[@]}")
fi


${INSTALLER} ${CONDA_CMD} -y -n ${ENV_NAME} -c flyem-forge -c conda-forge ${PACKAGES[@]}

if [[ ! -z "${STUART_CREDENTIALS}" && ${STUART_CREDENTIALS} != "0" ]]; then
    # This is related to my personal credentials files.  Not portable!
    ${INSTALLER} install -y -n ${ENV_NAME} $(ls ${WORKSPACE}/stuart-credentials/pkgs/stuart-credentials-*.tar.bz2 | tail -n1)
fi

set +x
# https://github.com/conda/conda/issues/7980#issuecomment-492784093
eval "$(conda shell.bash hook)"
conda activate ${ENV_NAME}
set -x

pip_pkgs=()

if [[ ! -z "${NEUROGLANCER}" && ${NEUROGLANCER} != "0" ]]; then
    # These would all be pulled in by 'pip install neuroglancer cloud-volume',
    # but I'll list the pip dependencies explicitly here for clarity's sake.
    pip_pkgs+=(
        neuroglancer
    )
fi

if [[ ! -z "${CLOUDVOL}" && ${CLOUDVOL} != "0" ]]; then
    pip_pkgs+=(
        cloud-volume # 2.0.0
        'cloud-files>=0.9.2'
        'compressed-segmentation>=1.0.0'
        'fpzip>=1.1.3'
        DracoPy
        posix-ipc
        python-jsonschema-objects
    )
fi

if [ ${#pip_pkgs[@]} -eq 0 ]; then
    echo "No pip packages to install"
else
    pip install ${pip_pkgs[@]}
fi

if [[ ! -z "${DEVELOP_MODE}" && ${DEVELOP_MODE} != "0" ]]; then

    # It is assumed you already have git repos for these in ${WORKSPACE}/
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

    echo "Uninstalling the following packages and re-installing them in 'develop' mode: ${develop_pkgs[@]}"

    for p in ${develop_pkgs[@]}; do
        rm -rf ${CONDA_PREFIX}/lib/python${PYTHON_VERSION}/site-packages/${p}*
        cd ${WORKSPACE}/${p}
        python setup.py develop
    done

fi
