# pgc_install

**Protocol-Governed Computing — the whole toolchain in one install.**

This repository publishes the `protocol-governed-computing` distribution. PyPI prohibits the
short name `pgc`, so the composition carries the full project name; the command it installs is
still `pgc`. It is the composition as *installable
software*, the counterpart to `pgc_release`, which is the same composition as *sealed
evidence* — assembled, immutable, and cited by DOI. The parallel is in role, not in citation:
a release is a thing a paper points at; an install is a thing that changes each version.

```bash
pip install protocol-governed-computing
```

That brings in the eight component packages of the family, pinned to one composition, and puts
`pgc` on the path.

## Two steps, not one

Installing the toolchain is half of a working environment. The compiler resolves the
governance surface from `PGC_PLATFORM_ROOT` — fail-hard, cwd-independent, zero
inference — so the **declarations come from a repository you point at, not from a
wheel**. A registry inside a package would be a second governance surface competing
with the repository's, and a build could then be governed by a stale copy.

```bash
git clone https://github.com/protocol-governed-computing/software_governance
export PGC_PLATFORM_ROOT=$PWD/software_governance
pgc            # reports what is installed and whether the anchor resolves
```

## The family

| Package | Role |
|---|---|
| `pgc-compiler` | declarations → compiled projections |
| `pgc-assembler` | projections → sealed snapshot |
| `pgc-runtime` | snapshot → governed execution |
| `pgc-inspector` | snapshot → read-only inspection |
| `pgc-transformation` | change request → protocol artifacts |
| `pgc-governance` | the governance surface and its capability implementations |
| `pgc-workloads` | the workloads that make conformance observable |
| `pgc-domains` | the business domain implementations the composed snapshot binds |

**Versioning.** Two schemes. Each repository's `VERSION` is a monotonic composition ordinal —
internal build accounting, tagged `release-<N>`, never published. `PUBLIC_VERSION` is the platform's
public identity, tagged on every component repository; the platform is at **`v3`**.

**The published version is the public one: `v3` is `3.0.0`.** The family releases in lockstep, so the
composition pins exact versions rather than ranges. The standard these packages implement is a separate artifact on
its own track and is not this number.

The standard these packages implement is published separately:
https://doi.org/10.5281/zenodo.22150616
