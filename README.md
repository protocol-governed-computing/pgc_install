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

That is enough to compile the platform. It is not enough to assemble or execute a
snapshot — for that, see the full sequence below.

## Installing a working platform

A **Profiled Normative Platform** is a composition: a governance surface, one or more
conformance workloads, and the inspection boundary, sealed together under a profile. The
wheels carry implementations; every declaration comes from a cloned repository. Reaching a
snapshot that executes therefore means cloning four repositories and setting the anchors
that tell each build where to read and where to write.

### 1. The toolchain

```bash
python3.12 -m venv .venv && source .venv/bin/activate
pip install protocol-governed-computing
```

### 2. The declaration repositories

```bash
git clone https://github.com/protocol-governed-computing/software_governance
git clone https://github.com/protocol-governed-computing/conformance_workloads
git clone https://github.com/protocol-governed-computing/snapshot_inspector
git clone https://github.com/protocol-governed-computing/.github pgc_github
```

`software_governance` is the governance surface. `conformance_workloads` and
`snapshot_inspector` each contribute a domain the reference profile requires.
`.github` carries the snapshot profiles, which are conformance contracts rather than
code and are not published in any wheel.

### 3. The anchors

Six environment variables govern where the toolchain reads and writes.

| Anchor | Read by | Meaning |
|---|---|---|
| `PGC_PLATFORM_ROOT` | compiler | the governance repository — the directory containing `registry/` |
| `PGC_DOMAIN_ROOTS` | compiler | the domain being compiled — the directory containing `registry/structures/` |
| `PGC_SNAPSHOT_ROOT` | compiler | where compiled projections are written |
| `PGC_SNAPSHOT_ROOT` | runtime | the assembled snapshot to execute — a different meaning; prefer `--snapshot` |
| `PGC_SNAPSHOT_PROFILES` | assembler | the directory holding snapshot profiles |
| `PGC_DATA_ROOT` | runtime | side-effect state and traces — or pass `--data-root` |

`PGC_DOMAIN_ROOTS` names the directory that directly contains `registry/structures/`, not
the repository above it. For `conformance_workloads` that is the workload directory
(`workloads/collatz`); for `snapshot_inspector` it is the repository root. Pointing it one
level too high is silent — the build config is simply never found.

`PGC_SNAPSHOT_ROOT` must differ for each domain build. Every layer's output consolidates
into one snapshot root, and verification rejects any file in that root the current build
did not declare. Two domains sharing a root cannot both verify.

### 4. Compile each domain

The platform compiles first: every other domain imports its compiled surface, which is
read from `$PGC_PLATFORM_ROOT/snapshot` regardless of where output is being written.

```bash
export PGC_PLATFORM_ROOT=$PWD/software_governance
protocol_compiler compile --structure STRUCTURE_BUILD_PLATFORM_CONFIG_V1
```

Then each domain, into its own output root:

```bash
PGC_DOMAIN_ROOTS=$PWD/conformance_workloads/workloads/collatz \
PGC_SNAPSHOT_ROOT=$PWD/workload_snapshot \
  protocol_compiler compile --structure STRUCTURE_BUILD_WORKLOAD_CONFIG_V0

PGC_DOMAIN_ROOTS=$PWD/snapshot_inspector \
PGC_SNAPSHOT_ROOT=$PWD/inspection_snapshot \
  protocol_compiler compile --structure STRUCTURE_BUILD_INSPECTION_CONFIG_V0
```

Each run reports its stages, artifact count, and whether the result verified and attested.

### 5. Assemble and seal

`--source` is repeatable and takes one compiled root per domain. The profile is the
conformance contract the assembled snapshot claims.

```bash
export PGC_SNAPSHOT_PROFILES=$PWD/pgc_github/snapshot_profiles

snapshot_assembler assemble \
  --source $PWD/software_governance/snapshot/compiled \
  --source $PWD/workload_snapshot/compiled \
  --source $PWD/inspection_snapshot/compiled \
  --out $PWD/snapshot \
  --profile GOVERNANCE_SURFACE_PROFILE_V0
```

A conformant assembly reports the domains composed, the snapshot id, a round-trip verify,
and composition conformance over the artifacts it sealed.

### 6. Boot and execute

```bash
protocol_runtime boot --snapshot $PWD/snapshot

protocol_runtime run \
  --wf workload::WF_COLLATZ_CONJECTURE_V0 \
  --payload $PWD/conformance_workloads/workloads/collatz/test_payloads/01_happy_path.json \
  --snapshot $PWD/snapshot \
  --data-root $PWD/data
```

`boot` loads and hash-verifies every domain in the manifest before anything executes. The
payloads are declarations and live in the cloned repository, not in a wheel.

## Known rough edges

- **`--all-structures` and `STRUCTURE_BUILD_PLATFORM_CONFIG_V0` do not build.** The `_V0`
  config requires a layer the resolver does not map, and `--all-structures` additionally
  names domain structures that are not part of the governance surface. Compile
  `STRUCTURE_BUILD_PLATFORM_CONFIG_V1` by name.
- **`PGC_BUILD_ROOT` is inert.** It is accepted and reported, and nothing reads it.
  `PGC_SNAPSHOT_ROOT` is the anchor that controls compiled output.
- **`PGC_SNAPSHOT_ROOT` carries two meanings** — compiled output to the compiler, assembled
  snapshot to the runtime. Pass `--snapshot` to the runtime rather than relying on it.
- **`pgc` reports readiness for the platform compile only.** It reads three anchors and
  reports "Ready" once the governance surface resolves; assembly and execution need the
  other three.

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

**The published version follows the public one: `v3` opens at `3.0.0`.** The family releases in
lockstep, so the composition pins exact versions rather than ranges.

A public identity may carry more than one published version. Packaging and distribution defects are
corrected in a patch release within the same identity — `3.0.1` is still `v3` — because such a fix
changes what a wheel contains, not what the composition is or what it does. Only a change to the
composition itself takes the next public identity, and only that mints a new DOI. The current
published version is **`3.0.1`**.

The standard these packages implement is a separate artifact on its own track, is not this number,
and is published separately: https://doi.org/10.5281/zenodo.22150616
