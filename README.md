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
`pgc` on the path. To run the sealed composition a paper cites, rather than build one, see
[`pgc_release`](https://github.com/protocol-governed-computing/pgc_release).

## Two steps, not one

Installing the toolchain installs the machinery, not the declarations that govern it. PGC reads those declarations from the repository named by `PGC_PLATFORM_ROOT` — fail-hard, cwd-independent, with no inference. The wheel supplies the implementation; the repository supplies the governance surface.


```bash
git clone https://github.com/protocol-governed-computing/software_governance
export PGC_PLATFORM_ROOT=$PWD/software_governance
pgc            # reports what is installed and whether the anchor resolves
```

These two steps establish the working platform: install the toolchain, then point it at its governance surface. The compiler can now resolve and compile the platform. Assembling and executing a snapshot requires additional repositories and anchors, described below.

## Who this is for

Two kinds of work start here, and they diverge after the toolchain is installed.

**Kicking the tires — you want to see the platform build and run.** Clone the declaration
repositories, compile them, assemble a snapshot, execute a workflow. That is the sequence below,
unmodified.

**Adding a domain — you trust the platform and want to author against it.** Same sequence, with
your own domain in place of the shipped ones. See *Adding your own domain*.

A third case is not served here: **verifying the sealed composition a paper cites**. That artifact
is published separately and needs no build — see
[`pgc_release`](https://github.com/protocol-governed-computing/pgc_release).

**One thing surprises domain authors, so it is worth saying early.** You must clone
`software_governance` even though you never modify it. The wheels give you the toolchain *and* the
platform's capability implementations; they do not give you the governance surface, because
declarations never ship in a wheel. Trusting the platform does not spare you the clone.

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

## Adding your own domain

A domain is a directory the compiler is pointed at. It declares what it contributes, compiles against
the platform's compiled surface, and composes into a snapshot alongside it. You author it; nothing
generates it for you.

The smallest domain that admits a request, does work, and returns a result is **six files producing
seventeen artifacts**. `.github/process/domain_authoring.py` builds exactly that from scratch on every
regression run, so what follows is executed rather than described.

**The shape.**

```
your_domain/
  registry/
    structures/STRUCTURE_BUILD_YOUR_DOMAIN_CONFIG_V0.md   the build manifest
    <subdomain>/
      actors/AC_*.md              intents/IN_*.md         workflows/WF_*.md
      capability_contracts/CC_*.md    capability_transforms/CT_*.md
  implementation/
    capability_transforms/atoms/*.py   one module per CT, each exposing execute(inputs, context)
```

**The build manifest.** Three parts of it are easy to get wrong, and each fails in its own way:

```yaml
fqdn: your_domain::STRUCTURE_BUILD_YOUR_DOMAIN_CONFIG_V0
artifact_kind: STRUCTURE
version: V0
governed_by: structure::CONSTITUTION_STRUCTURE_V0
authority: pgc.platform
concern: your_domain
structure_scope: your_domain        # names the composed domain — see below
reuse_visibility: business
core:
  summary: Build-time STRUCTURE manifest for the your_domain scope
layer_definitions:
  YOUR_DOMAIN:
    domain_subpath: registry
    registry_module: your_domain.registry
    implementation_namespace: your_domain.implementation.capability_transforms.atoms
    layer_category: domain
identity_rules:
- match: your_domain.registry
  namespace: your_domain
artifact_discovery:
  search_layers:
  - YOUR_DOMAIN
  import_surface:
    domain: platform              # compile against the platform's compiled surface
  artifact_types: [AC, IN, WF, CC, CT]
output_configuration:
  artifacts:
    layer: PROTOCOL_BUILD_ROOT
    subpath: compiled/canonical
  vocabulary_projection_path:   {layer: GOVERNANCE, subpath: compiled/vocabulary}
  tokenized_projection_path:    {layer: GOVERNANCE, subpath: compiled/tokenized}
  evidence_projection_path:     {layer: GOVERNANCE, subpath: compiled/evidence}
  trust_attestation_path:       {layer: GOVERNANCE, subpath: compiled/trust}
  visualization_projection_path: {layer: GOVERNANCE, subpath: compiled/visualization}
  layer_outputs:
    YOUR_DOMAIN:
      layer: YOUR_DOMAIN
      subpath: compiled/canonical
```

**All five projection paths are required.** Omitting them does not fail early: the build passes
discovery, governance and construction and dies at S7 with five `E301_WRITE_FAILED` errors naming
each missing path. It reads like a compiler fault and is a missing declaration.

**`structure_scope` names the composed domain**, not `layer_category` and not the namespace. Set it
to something generic and the snapshot composes a domain literally called that — the assembly
succeeds, conformance passes, and the domain is simply wrongly named. Nothing catches it.

**Building it** is step 4 above with your directory in place of a shipped one:

```bash
PGC_DOMAIN_ROOTS=$PWD/your_domain \
PGC_SNAPSHOT_ROOT=$PWD/your_domain/snapshot \
  protocol_compiler compile --structure STRUCTURE_BUILD_YOUR_DOMAIN_CONFIG_V0
```

Then add `--source $PWD/your_domain/snapshot/compiled` to the assemble in step 5. The platform must
be compiled first: `import_surface` reads its compiled vocabulary, and a domain cannot compile
against a surface that does not yet exist.

**Your domain must be importable at execution time.** The compiler reads declarations from the
filesystem, but the runtime *imports* the module a CT names. If your package is not on the path, the
workflow does not raise — it returns `VIOLATION` with the transform's outputs null, which looks like
a failed business rule rather than a missing module. Either `pip install -e your_domain` or:

```bash
export PYTHONPATH=$PWD
```

**What you do not need:** `conformance_workloads`. It contributes the collatz workload, which the
profile in force does not require — verified by building this path without it. You still need
`software_governance` for the declarations and `snapshot_inspector` for the inspection domain the
profile does require.

**A profile permits more than it requires.** Composing your domain alongside the platform does not
violate the claimed profile: a snapshot may carry more than a profile requires and still conform.

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
public identity, tagged on every component repository; the platform is at **`v4`**.

**The published version follows the public one: `v4` opens at `4.0.0`.** The family releases in
lockstep, so the composition pins exact versions rather than ranges.

A public identity may carry more than one published version. A packaging or distribution defect can
be corrected in a patch release within the same identity, because such a fix changes what a wheel
contains and not what the composition determines. A change to what the composition determines takes
the next public identity, and only that mints a new DOI.

`v4` is the second kind. The wheels stopped shipping declarations, which is the first; but an
identity published by more than one domain now resolves to its authoring copy rather than to
whichever sorted last, and that changes what the composition answers. A patch release would have
said otherwise.

The standard these packages implement is a separate artifact on its own track, is not this number,
and is published separately: https://doi.org/10.5281/zenodo.22150616
