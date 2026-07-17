# OOD Container Images on Rikyu

We use **two separate container images**. Do not merge them (see below).

## 1. ubuntu2404.sif — Desktop apps

- Def file: `misc/ubuntu2404.def` (base: `ubuntu:24.04`)
- Used by: Desktop, Gnuplot, ParaView, PyMOL, OVITO
- Image path is set in `misc/config.yml` (`container_image`)

## 2. jupyterlab.sif — JupyterLab

- Def file: `misc/jupyterlab.def` (base: `nvcr.io/nvidia/pytorch:25.06-py3`)
- JupyterLab itself comes with the NGC base image.
  We only add: `lmod`, `emacs-nox`, `jupyterlab-git`, `ipympl`
- Image path is written directly in `JupyterLab/template/script.sh.erb`
- User extensions and pip packages go to `~/ondemand/JupyterLab`
  (`PYTHONUSERBASE`), so they survive image updates

## Why two images (lesson learned)

We once merged both into one image on the NGC base. It failed:

- The NGC base sets `OPAL_PREFIX=/opt/hpcx/ompi` for its bundled Open MPI (HPC-X)
- Ubuntu's ParaView links against apt Open MPI, which also reads `OPAL_PREFIX`,
  loads wrong components, and dies with `opal_init failed`
- Workaround was `env -u OPAL_PREFIX` (still in the Paraview app script; harmless)

**Lesson: a base image brings not only files but also environment variables
(`ENV`), such as `OPAL_PREFIX` and `LD_LIBRARY_PATH`. Mixing NGC and apt
software stacks in one image causes this kind of conflict.**

## How to build

Build on rikyu login node `c000` (aarch64). The def files live in this
directory (`misc/`) on sv01, which c000 cannot see — copy the def to your
home first (home is shared between sv01 and c000):

```bash
# on sv01
cp /var/www/ood/apps/sys/ondemand_rikyu/misc/jupyterlab.def ~/
```

```bash
# on c000
# Cache/tmp on local NVMe (/tmp, 7TB). Never let the build touch $HOME
# (small quota + known EDQUOT problem).
export APPTAINER_CACHEDIR=/tmp/$USER/cache
export APPTAINER_TMPDIR=/tmp/$USER/tmp
mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR"

# Build to /tmp first, not directly to /shared
apptainer build ~/jupyterlab.sif jupyterlab.def

# Smoke test
apptainer exec ~/jupyterlab.sif jupyter-lab --version

# Deploy: keep the old SIF until the new one is tested (rollback = mv back)
cd /shared/software/OpenOnDemand/images
mv jupyterlab.sif jupyterlab.sif.old
cp ~/jupyterlab.sif .
```

Same procedure for the Desktop image: `ubuntu2404.def` →
`ubuntu2404.sif`. (`singularity` and `apptainer` are the same
command on rikyu.)

If the build dies with `unexpected EOF` during download, run the same
command again — finished layers are cached, so it resumes.

## When bumping the NGC base image

1. Check the required NVIDIA driver in the release notes:
   https://docs.nvidia.com/deeplearning/frameworks/pytorch-release-notes/
2. Update the tag in `JupyterLab/manifest.yml` (two places)
3. Test: JupyterLab starts, GPU works (`torch.cuda.is_available()`),
   extension manager works, `module avail` works
