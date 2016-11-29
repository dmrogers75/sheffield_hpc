#!/bin/bash
################################################################################
# Install Relion 2 beta on Iceberg
################################################################################

################################################################################
# Define constants
################################################################################
git_commit=a622560
vers_str="2-beta-${git_commit}"
compiler=gcc
compiler_vers=4.9.2
openmpi_vers=1.10.1
cuda_short_vers=7.5
cuda_vers=7.5.18
workers=10

builddir="${TMPDIR-/tmp}/${USER}/relion/${vers_str}"
prefix="/usr/local/packages6/apps/${compiler}/${compiler_vers}/relion/${vers_str}"
modulefile="/usr/local/modulefiles/apps/${compiler}/${compiler_vers}/relion/${vers_str}"

################################################################################
# Error handling
################################################################################
handle_error () {
    errcode=$? # save the exit code as the first thing done in the trap function 
    echo "error $errorcode" 
    echo "the command executing at the
    time of the error was" echo "$BASH_COMMAND" 
    echo "on line ${BASH_LINENO[0]}"
    # do some error handling, cleanup, logging, notification $BASH_COMMAND
    # contains the command that was being executed at the time of the trap
    # ${BASH_LINENO[0]} contains the line number in the script of that command
    # exit the script or return to try again, etc.
    exit $errcode  # or use some other value or do return instead 
}
trap handle_error ERR

################################################################################
# Activate modulefiles
################################################################################
# Activate latest OpenMPI
module load mpi/gcc/openmpi/${openmpi_vers}
# Activate CUDA 7.5 (so must use older GCC i.e. 4.4.7 (system GCC); 
# CUDA 8.0 not recommended yet
module load libs/cuda/${cuda_vers}
module load compilers/${compiler}/${compiler_vers}
module load compilers/cmake/3.3.0
module load libs/${compiler}/${compiler_vers}/fltk/1.3.3
module load libs/${compiler}/${compiler_vers}/fftw/3.3.5

################################################################################
# Make dirs and set permissions
################################################################################
mkdir -m 0700 -p $builddir 
mkdir -m 2775 -p $prefix $(dirname $modulefile)
chown -R ${USER}:app-admins $prefix $(dirname $modulefile)

################################################################################
# Get source
################################################################################
pushd $builddir
# Clone Relion 2.0 beta
[[ -d relion2-beta ]] || git clone https://bitbucket.org/tcblab/relion2-beta.git
pushd relion2-beta
git checkout $git_commit

################################################################################
# Compile
################################################################################
mkdir build
pushd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} ..
make -j${workers} all install

################################################################################
# Install MotionCor2 in ${prefix}/bin
################################################################################
motioncor2_vers="10-19-2016"
motioncor2_tarball_url="http://msg.ucsf.edu/MotionCor2/MotionCor2-${motioncor2_vers}.tar.gz"
pushd ${prefix}/bin
curl -L $motioncor2_tarball_url | tar -zx
popd

################################################################################
# Install GCTF in ${prefix}/bin
################################################################################
# NB requires CUDA
gctf_vers="0.50"
gctf_tarball_url="http://www.mrc-lmb.cam.ac.uk/kzhang/Gctf/Gctf_v${gctf_vers}_and_examples.tar.gz"
gctf_tmpdir="${TMPDIR-/tmp}/${USER}/gctf/${gctf_vers}"
mkdir -m 0700 -p $gctf_tmpdir
pushd $gctf_tmpdir
curl -L $gctf_tarball_url | tar -zx
pushd Gctf_v${gctf_vers}/bin
cp Gctf-v${gctf_vers}_sm_*_cu${cuda_short_vers}_x86_64 star_replace_UVA.com ${prefix}/bin
popd
popd

