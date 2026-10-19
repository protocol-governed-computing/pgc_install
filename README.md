# Protocol-Governed Computing

**Software that runs only what it has declared, and proves it.**

In Protocol-Governed Computing (PGC), declarations decide what a system does. They name who may ask,
which input is admitted, which steps run, and what each step may touch. PGC compiles the declarations
and seals them into a **snapshot**. The runtime checks the snapshot is unchanged, executes only what it
declares, refuses everything else, and records a trace of every run.

## Choose where to start

| You want to | Start here |
|---|---|
| See PGC run on your machine in a few minutes | [**Demos**](https://github.com/protocol-governed-computing/pgc_install/blob/main/README_DEMO.md) |
| Build, run and extend PGC from its parts | [**Developer guide**](https://github.com/protocol-governed-computing/pgc_install/blob/main/README_DEV.md) |
| Verify the sealed composition a paper cites | [`pgc_release`](https://github.com/protocol-governed-computing/pgc_release) |
| Read the standard PGC implements | https://doi.org/10.5281/zenodo.22150616 |

## This package

This repository publishes `protocol-governed-computing`, the whole toolchain in one install. It
brings in the nine component packages, pinned to one composition, and puts the `pgc` command on your
path.

```bash
pip install protocol-governed-computing
```

The toolchain carries no declarations. To build and run a platform, follow the
[developer guide](https://github.com/protocol-governed-computing/pgc_install/blob/main/README_DEV.md).
To see one run without building anything, start with the
[demos](https://github.com/protocol-governed-computing/pgc_install/blob/main/README_DEMO.md).

**Something failed?** Please [open an issue](https://github.com/protocol-governed-computing/pgc_install/issues).
