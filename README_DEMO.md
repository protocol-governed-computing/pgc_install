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
pipx install protocol-governed-computing-demo
```

One install brings the runtime, the sealed snapshot and the demo pages. It builds nothing, and it
writes only to `~/pgc-demo`.

### 1. Play in your browser

```bash
pgc-demo collatz
```

Your browser opens the game. Enter **27** and press *Run*. The page shows the 111-step sequence and
confirms that the number reached 1. Try a few of your own. Large odd numbers often climb surprisingly
high before they fall.

### 2. See the path the run took

Below the result, the page draws the workflow the snapshot declares, and it marks the steps your run
took. A run follows only paths the snapshot declares. It can take no other.

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
pgc-demo collatz 27
pgc-demo collatz -5
```

The first prints the sequence. The second prints the refusal and its reason. The terminal and the
browser reach the same snapshot through the same boundary, and they get the same answers.

### 5. See what the demo recorded

```bash
pgc-demo where
```

This opens `~/pgc-demo`. Each run you made has a trace there, one line per event. The first event
names the snapshot that governed the run. The last records how the run ended.

### Stop or remove

Press `Ctrl-C` to stop the game. To remove everything:

```bash
pipx uninstall protocol-governed-computing-demo
rm -rf ~/pgc-demo
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
pgc-demo inspect
```

Your browser opens the **snapshot inspector**. It reads the sealed snapshot that ran your games in
Demo 1. It can only read. Nothing you do here changes the snapshot.

### 1. Start from the map

The inspector opens on the game's diagram. You saw it in Demo 1:

```
  your number ─▶ IN  ─▶ CC compute ─▶ CC verify ─▶ CC store ─▶ EXIT proven
                 │                                            
                 └─▶ EXIT rejected        (and EXIT violated, EXIT error)
```

Each box is a declaration. Its name says what kind it is:

| Prefix | Kind | What it declares |
|---|---|---|
| `TI` | entrance | what a caller may send, and where it goes |
| `IN` | entry point | what a request must carry to be admitted |
| `WF` | workflow | the boxes, the order they run in, and every way the run can end |
| `CC` | contract | one unit of work and the steps inside it |
| `CT` | transform | one computation, the only place code runs |
| `EXIT` | ending | how a run finishes, and what it announces |

### 2. Open each box

Click a box, or run the same question from the terminal:

```bash
pgc-demo inspect show IN_COLLATZ_INPUT_VALIDATED_V0
```

Each box shows its declaration in plain text. Walk the diagram from left to right:

- **The entry point** admits a list of positive whole numbers and nothing else.
- **Compute** runs one step of the puzzle, over and over, until each number reaches 1.
- **Verify** confirms every sequence ended at 1. It refuses the run if one did not.
- **Store** records the results.

None of these is a program. Each one states what happens. The runtime does what it states.

### 3. Find the code

Open `CC compute` and follow its step to `CT_PURE_COLLATZ_STEP_V0`. This transform is code. The
inspector shows the Python module the transform names:

```bash
pgc-demo inspect code CT_PURE_COLLATZ_STEP_V0
```

It is one short function that halves or triples a number. It reads no file, keeps no state, and cannot reach
the network. The whole game has two such transforms, about 56 lines of Python. Everything else, about
570 lines, is declaration you can read.

**That is the separation.** The declarations say what may happen. The code only computes.

### 4. Find the rule that refused you

In Demo 1, PGC refused 1,000,000. Find the rule that did it:

```bash
pgc-demo inspect show TI_COLLATZ_COMPUTE_V0
```

The entrance declares `max: 999999`. There is no `if number > 999999` anywhere in the code. The limit is
a declaration, and you can read it.

### 5. Change the rule

Raise the limit, or remove it:

```bash
pgc-demo collatz set-limit 9999999
```

PGC compiles the changed declaration, assembles a new snapshot and seals it. The new snapshot has a
new identity. Play again:

```bash
pgc-demo collatz 1000000
```

PGC now admits it. You changed what the game allows, and you did not touch a line of code.

The old snapshot still exists and still refuses 1,000,000. Each snapshot is sealed, and each trace
names the one that governed it. To go back:

```bash
pgc-demo collatz reset
```

### 6. Try to cheat

What if you skipped the rebuild and edited the sealed snapshot directly?

```bash
pgc-demo collatz tamper
```

This changes one byte in a copy of the sealed snapshot and asks the runtime to start it. The runtime
refuses, and names the file that changed. A rule changes only through its declaration.

### What just happened

You read a system's behavior without reading its code, and you changed that behavior without writing
code. The declarations are the system. The code is a few small computations they call. In a business
system, this is what lets an auditor read the rules, and a change to a rule leave evidence.

**Something failed?** Please [open an issue](https://github.com/protocol-governed-computing/pgc_install/issues)
with the step and its output. A demo that fails is a defect.
