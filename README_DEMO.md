# PGC demos

**See Protocol-Governed Computing run on your own machine, one short demo at a time.**

Each demo stands alone and takes a few minutes. You need no knowledge of PGC to start. Demo 1
installs everything the others use.

| Demo | What you do | What you see |
|---|---|---|
| [1. Play the Collatz game](#demo-1--play-the-collatz-game) | Enter a number in a web page | A governed system run, refuse, and leave evidence |
| [2. Look inside the game](#demo-2--look-inside-the-game) | Open each box of the game's diagram, then change one rule | Behavior you can read, kept apart from the code that computes |

---

## Demo 1 — Play the Collatz game

### The puzzle

Pick any whole number. If it is even, halve it. If it is odd, triple it and add one. Repeat.

Start at 6 and you get 6, 3, 10, 5, 16, 8, 4, 2, 1. Start at 27 and the numbers climb for a long
time. They reach 9,232 before they fall, and they take 111 steps to reach 1.

In 1937 the mathematician Lothar Collatz guessed that every starting number ends at 1. Computers have
checked astronomically many numbers, and every one has reached 1. Nobody has proved that every number
does. It remains one of the simplest unsolved problems in mathematics.

### Why a puzzle?

The puzzle is not the point. The point is the system that runs it.

In PGC, no program decides what the game does. A set of declarations decides it: who may ask, which
input is admitted, which steps run, and what each step may touch. PGC compiles those declarations and
seals them into a **snapshot**. The runtime executes only what the snapshot declares, and it checks
the snapshot has not changed before it runs anything.

So while you play, watch three things:

- **Admission.** The game accepts 1 to 999,999. Send anything else and PGC refuses it before any step
  runs.
- **Evidence.** Every run leaves a trace. The trace shows each step taken, and it names the exact
  snapshot that governed the run.
- **Nothing hidden.** The runtime knows nothing about Collatz. Everything it did, the snapshot
  declared.

### Install (macOS)

You need Python 3.10 or later and [pipx](https://pipx.pypa.io). With Homebrew:

```bash
brew install pipx
pipx install --include-deps protocol-governed-computing
curl -LO https://raw.githubusercontent.com/protocol-governed-computing/pgc_install/main/demo/pgc-demo.sh
```

The first command installs PGC itself: the compiler, the assembler, the runtime, the inspector and
the transport boundary, each as a command. The second fetches
[`pgc-demo.sh`](demo/pgc-demo.sh), a short script that runs those commands for you. It adds no
behavior of its own, so you can read it to see exactly what each step below runs.

On first use the script downloads the published release it names: the sealed snapshot, the web
pages and the declarations. It writes only to `~/pgc-demo`.

### 1. Play in your browser

```bash
bash pgc-demo.sh collatz
```

Your browser opens the game. Enter **27** and press *Compute Sequence*. The page shows the 111-step
sequence, its peak of 9,232, and the trace the run left. Try a few of your own. Large odd numbers
often climb surprisingly high before they fall.

### 2. See the path the run took

Below the result, the page draws the workflow the snapshot declares, and it marks the steps your run
took. It reads them from the run's trace. A run follows only paths the snapshot declares. It can
take no other.

### 3. Try to break it

Enter something the game does not admit:

| Try | What PGC does |
|---|---|
| `-5` | Refuses it: out of range |
| `0` | Refuses it: out of range |
| `1000000` | Refuses it: out of range |
| `abc` | Refuses it: not a number |

Each time, PGC refuses at the door and names the reason. No step runs, so no trace is written.
The page does not check your input first. The governed boundary does.

### 4. Do the same from the terminal

```bash
bash pgc-demo.sh collatz 27
bash pgc-demo.sh collatz -5
```

Each prints the boundary's response exactly as the page received it. The first holds the sequence,
its steps and its peak, and names its trace. The second holds the refusal and its reason. The
terminal and the browser reach the same snapshot through the same boundary, and they get the same
answers. Under the script, both run `pgc_transport`, PGC's own command for the boundary.

### 5. See what the demo recorded

```bash
bash pgc-demo.sh where
```

This opens `~/pgc-demo`. Each run you made has a trace there, one line per event. The first event
names the snapshot that governed the run. The last records how the run ended.

### Stop or remove

Press `Ctrl-C` to stop the game. To remove everything:

```bash
pipx uninstall protocol-governed-computing
rm -rf ~/pgc-demo pgc-demo.sh
```

### What just happened

You ran software whose behavior was fixed before it started. It admitted only what its declarations
admit, ran only the steps they name, and left a trace that ties every run to one sealed snapshot. The
same holds for a business system. A loan approval, a model's response or a payment can run the same
way, with the same refusals and the same evidence.

---

## Demo 2 — Look inside the game

Demo 1 showed what the game does. Demo 2 shows what it is made of. You will open every part of the
game, read what each part declares, and find the only code it contains. Then you will change one rule
without touching any code.

### Open the inspector

```bash
bash pgc-demo.sh inspect
```

Your browser opens the **snapshot inspector**, at its workflow map. It reads the sealed snapshot that ran your games in
Demo 1. It can only read. Nothing you do here changes the snapshot.

### 1. Start from the map

The inspector opens on the game's diagram. You saw it in Demo 1:

```
your number ─▶ TI entrance ─▶ IN ─▶ CC compute ─▶ CC verify ─▶ CC store ─▶ EXIT proven
                    │          │                      │
                 refused   EXIT rejected        EXIT violated       (any CC can also end at EXIT error)
```

Each box is a declaration. Its name says what kind it is:

| Prefix | Kind | What it declares |
|---|---|---|
| `TI` | entrance | what a caller may send, and where it goes |
| `IN` | entry point | what a request must carry to be admitted |
| `WF` | workflow | the boxes, the order they run in, and every way the run can end |
| `CC` | contract | one unit of work and the steps inside it |
| `CT` | transform | one computation, the only place code runs |
| `CS` | side effect | what a step may read or write, and nothing more |
| `EXIT` | ending | how a run finishes, and what it announces |

### 2. Open each box

Click a box, or run the same question from the terminal:

```bash
bash pgc-demo.sh inspect show workload::IN_COLLATZ_INPUT_VALIDATED_V0
```

Each box shows its declaration in plain text. In the terminal, the declaration as written comes
first, and the form the compiler sealed follows it. Walk the diagram from left to right:

- **The entrance** admits one whole number from 1 to 999,999 and hands it on as a list.
- **The entry point** admits a non-empty list of positive whole numbers and nothing else.
- **Compute** works out each number's whole sequence, down to 1.
- **Verify** checks that every sequence ended at 1. If one did not, the run ends at *violated*.
- **Store** records the results, and the run ends at *proven*.

Open `CC verify` and you will see it runs version 2 of its contract. The earlier versions are still
in the snapshot, and version 2 names the one it replaced. A rule changes by a new version, never by
an edit.

None of these is a program. Each one states what happens. The runtime does what it states.

### 3. Find the code

Open `CC compute` and follow its step to `CT_PURE_COLLATZ_STEP_V0`. This transform is code: it
names a Python module. Print that module:

```bash
bash pgc-demo.sh inspect code workloads.collatz.implementation.capability_transforms.atoms.ct_pure_collatz_step_v0
```

It is one short function: halve an even number, triple an odd one and add one, until it reaches 1.
It reads no file, keeps no state, and cannot reach the network. The game has two transforms of its
own, 56 lines of Python, and verify also reuses one the platform provides. Everything else, about
490 lines, is declaration you can read.

**That is the separation.** The declarations say what may happen. The code only computes.

### 4. Find the rule that refused you

In Demo 1, PGC refused 1,000,000. Find the rule that did it:

```bash
bash pgc-demo.sh inspect show workload::TI_COLLATZ_COMPUTE_V0
```

The entrance declares `max: 999999`. There is no `if number > 999999` anywhere in the code. The limit is
a declaration, and you can read it.

### 5. Change the rule

Raise the limit:

```bash
bash pgc-demo.sh collatz set-limit 9999999
```

This edits one line of the entrance's declaration, `max: 999999`, and nothing else. Then the script
runs the same build that made the published snapshot: `protocol_compiler`, `protocol_runtime
conformance` and `snapshot_assembler`. It compiles the declarations, proves the
transforms, assembles a new snapshot and seals it. The new snapshot has a new identity, and every
command uses it from now on. The first change takes a few seconds; later ones take about one.

The new snapshot holds only what the game needs: the platform, the game and the inspector. The
published one also carries business domains the game never touches. Build the same limit twice and
you get the same identity twice: a snapshot's identity depends on its declarations, not on where or
when it was built.

If the game page is open, stop it with `Ctrl-C` and start it again. A running page keeps the
snapshot it started with. Then play again:

```bash
bash pgc-demo.sh collatz 1000000
```

PGC now admits it. You changed what the game allows, and you did not touch a line of code.

The old snapshot still exists and still refuses 1,000,000. Each snapshot is sealed, and each trace
names the one that governed it. Every snapshot you build is kept in `~/pgc-demo/snapshots`. To go
back to the published one:

```bash
bash pgc-demo.sh collatz reset
```

### 6. Try to cheat

What if you skipped the rebuild and edited the sealed snapshot directly?

```bash
bash pgc-demo.sh collatz tamper
```

This copies the sealed snapshot, lowers the limit inside the copy by one, and asks the runtime to
start it with `protocol_runtime boot`. The runtime refuses before it runs anything. It names the file
that changed, and shows that its content no longer matches the hash the snapshot was sealed with. A
rule changes only through its declaration.

### What just happened

You read a system's behavior without reading its code, and you changed that behavior without writing
code. The declarations are the system. The code is a few small computations they call. In a business
system, this is what lets an auditor read the rules, and a change to a rule leave evidence.

**Something failed?** Please [open an issue](https://github.com/protocol-governed-computing/pgc_install/issues)
with the step and its output. A demo that fails is a defect.
