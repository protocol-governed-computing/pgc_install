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

A **fifth** clone is needed only to reach the platform over HTTP (§7), and only on
whichever node serves the boundary:

```bash
git clone https://github.com/protocol-governed-computing/protocol_transport
```

`protocol_transport` is deliberately not published. It provisions its import roots —
`adapters` and `resolver` — from its repository root rather than from an installed
package, so the boundary is composed by whoever deploys it rather than carried into
every install. Steps 4 through 6 need none of it.

**Pin what you clone.** These commands fetch the default branch, which moves. A wheel at
one version against declarations from a later branch is an incoherence nothing reports:
the implementations are one composition's and the declarations another's. Clone
`--branch <tag>` at the release matching your toolchain — `v5` for `5.0.0` — whenever the
build has to be reproducible.

### 3. The anchors

Five environment variables govern where the toolchain reads and writes. Where the compiler
writes is not one of them.

| Anchor | Read by | Meaning |
|---|---|---|
| `PGC_PLATFORM_ROOT` | compiler | the governance repository — the directory containing `registry/` |
| `PGC_DOMAIN_ROOTS` | compiler | the domain being compiled — the directory containing `registry/structures/` |
| `PGC_SNAPSHOT_ROOT` | runtime | the assembled snapshot to execute; prefer `--snapshot` |
| `PGC_SNAPSHOT_PROFILES` | assembler | the directory holding snapshot profiles |
| `PGC_DATA_ROOT` | runtime | side-effect state and traces — or pass `--data-root` |

`PGC_DOMAIN_ROOTS` names the directory that directly contains `registry/structures/`, not
the repository above it. For `conformance_workloads` that is the workload directory
(`workloads/collatz`); for `snapshot_inspector` it is the repository root. Pointing it one
level too high is silent — the build config is simply never found.

**Where a build writes is declared, not supplied.** Each build configuration names its root in
`output_configuration.root`, resolved inside the repository that declares it, and every layer's
output consolidates there. Every shipped configuration declares `snapshot`, so each domain writes
into its own repository's `snapshot/`. Two in-force configurations of one repository naming the
same root are refused, and a configuration naming none cannot be built. The compiler does not read
`PGC_SNAPSHOT_ROOT`.

### 4. Compile each domain

The platform compiles first: every other domain imports its compiled surface, which is
read from `$PGC_PLATFORM_ROOT/snapshot` regardless of where output is being written.

```bash
export PGC_PLATFORM_ROOT=$PWD/software_governance
protocol_compiler compile --structure STRUCTURE_BUILD_PLATFORM_CONFIG_V2
```

Then each domain, into the root its build configuration declares:

```bash
PGC_DOMAIN_ROOTS=$PWD/conformance_workloads/workloads/collatz \
  protocol_compiler compile --structure STRUCTURE_BUILD_WORKLOAD_CONFIG_V0

PGC_DOMAIN_ROOTS=$PWD/snapshot_inspector \
  protocol_compiler compile --structure STRUCTURE_BUILD_INSPECTION_CONFIG_V0
```

Each domain writes into its own repository's `snapshot/`, which is where the platform
already wrote its own and which every one of these repositories gitignores.

Each run reports its stages, artifact count, and whether the result verified and attested.

### 5. Assemble and seal

`--source` is repeatable and takes one compiled root per domain. The profile is the
conformance contract the assembled snapshot claims.

```bash
export PGC_SNAPSHOT_PROFILES=$PWD/pgc_github/snapshot_profiles

snapshot_assembler assemble \
  --source $PWD/software_governance/snapshot/compiled \
  --source $PWD/conformance_workloads/workloads/collatz/snapshot/compiled \
  --source $PWD/snapshot_inspector/snapshot/compiled \
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

`boot` also reads `PGC_SNAPSHOT_PROFILES`, exported in §5. A sealed snapshot's profile claim was
evaluated when it was sealed, so booting one should not need the profile root — today it does, and
reports an error before proceeding if the anchor is unset.

### 7. Reach it over HTTP

Steps 1 through 6 execute through the CLI. The interaction boundary is a separate surface, and two
of the cloned repositories ship a client for it: `conformance_workloads/workloads/collatz/client`
submits work, and `snapshot_inspector/client` reads the snapshot. Each carries its own `web/`, a
`bindings/http.json` naming which operations are reachable at which route, and a `serve.sh`.

**Those `serve.sh` scripts assume a development checkout**, where `runtime`, `inspector` and
`assembler` are sibling repository roots on `PYTHONPATH`. Here they are installed packages, so the
roots point at site-packages instead. `protocol_transport` is the exception, and is genuinely a
repository root because it is unpublished.

```bash
SP=$(python3 -c 'import site; print(site.getsitepackages()[0])')
CLIENT=$PWD/conformance_workloads/workloads/collatz/client

PGC_RUNTIME_ROOT=$SP PGC_INSPECTOR_ROOT=$SP PGC_ASSEMBLER_ROOT=$SP PGC_IMPL_ROOTS=$SP \
PGC_SNAPSHOT_ROOT=$PWD/snapshot \
PGC_DATA_ROOT=$PWD/data/collatz \
PGC_HTTP_BINDINGS=$CLIENT/bindings/http.json \
PGC_STATIC_MOUNTS="/=$CLIENT/web;/snapshot=$PWD/snapshot" \
PGC_HTTP_PORT=8000 \
  $PWD/protocol_transport/run_http.sh
```

Substitute `$PWD/snapshot_inspector/client` and another port for the read surface. Then:

```bash
curl -s -X POST http://localhost:8000/collatz -d '{"number":27}'
curl -s -X POST http://localhost:8001/si -d '{"operation":"si.snapshot.validate"}'
```

The read surface routes every `si.*` operation through one binding, named in the request body
rather than in the path. The boundary reads its bindings once, at startup: restart it after any
rebuild.

`run_http.sh` launches `python3`, which is the virtual environment's interpreter while §1's
environment is active. Set `PYTHON` to an absolute path if you invoke this without activating it —
not to `$(command -v python)`, which returns an alias rather than a path under some shells.

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
  root: snapshot                # where this build writes, inside your_domain
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

**`root` and all five projection paths are required.** A configuration without `root` is refused
before anything is compiled. Omitting them does not fail early: the build passes
discovery, governance and construction and dies at S7 with five `E301_WRITE_FAILED` errors naming
each missing path. It reads like a compiler fault and is a missing declaration.

**`structure_scope` names the composed domain**, not `layer_category` and not the namespace. Set it
to something generic and the snapshot composes a domain literally called that — the assembly
succeeds, conformance passes, and the domain is simply wrongly named. Nothing catches it.

**Building it** is step 4 above with your directory in place of a shipped one:

```bash
PGC_DOMAIN_ROOTS=$PWD/your_domain \
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

- **A successful compile may end with `⚠ Machine-block health: N candidate unconsumed key(s)`.**
  It is expected, and it is not a failure: the build has already verified and attested by the
  time it prints. It is a heuristic run after the build. For each artifact kind that no schema
  closes, it looks for machine-block keys whose names appear nowhere in the compiler's source. A
  key it lists is a *candidate* for a declaration nothing reads, not proof of one. `--verbose`
  shows the keys.
- **`PGC_BUILD_ROOT` is inert.** It is accepted and reported, and nothing reads it.
- **`pgc` reports readiness for the platform compile only.** It reads three anchors and
  reports "Ready" once the governance surface resolves; assembly and execution need the
  other three.
- **`protocol_runtime boot` requires `PGC_SNAPSHOT_PROFILES`.** A sealed snapshot carries its
  profile claim, and that claim was evaluated when the snapshot was sealed, so booting it should
  not need the profile root. Unset, `boot` prints an error and then proceeds and succeeds. The
  sequence above exports it in §5, so §6 inherits it — which makes the ordering load-bearing
  rather than incidental.
- **`--data-root` rejects a relative path.** `$PWD/data` above is absolute and passes. A bare
  `data` does not, which will surface first in whatever script wraps this.
- **No serving path is published for an installed platform.** Both clients' `serve.sh` resolve
  `runtime`, `inspector` and `assembler` from sibling repository roots, which exist in a
  development checkout and not in an install. §7 gives the equivalent invocation; nothing in any
  repository does.

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
public identity, tagged on every component repository; the platform is at **`v5`**.

**The published version follows the public one: `v5` opens at `5.0.0`.** The family releases in
lockstep, so the composition pins exact versions rather than ranges.

A public identity may carry more than one published version. A packaging or distribution defect can
be corrected in a patch release within the same identity, because such a fix changes what a wheel
contains and not what the composition determines. A change to what the composition determines takes
the next public identity, and only that mints a new DOI.

`v5` is the second kind. The snapshot identity now covers the claimed profile's content, so
acceptance refuses a profile changed after sealing, and refuses every snapshot sealed before `v5`.
A superseded artifact no longer confers effect. Both change what the composition admits, and a patch
release would have said otherwise.

The standard these packages implement is a separate artifact on its own track, is not this number,
and is published separately: https://doi.org/10.5281/zenodo.22150616
