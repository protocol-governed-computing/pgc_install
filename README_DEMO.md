# PGC demos

**See Protocol-Governed Computing run on your own machine, one short demo at a time.**

Each demo stands alone and takes a few minutes. You need no knowledge of PGC to start. Demo 1
installs everything the others use.

| Demo | What you do | What you see |
|---|---|---|
| [1. Play the Collatz game](#demo-1--play-the-collatz-game) | Enter a number in a web page | A governed system run, refuse, and leave evidence |
| 2. Look inside the snapshot | Ask the snapshot questions | Why your run did what it did *(coming next)* |

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

Each time, PGC refuses at the door. No step runs, and the trace records the refusal and its reason.
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
names the snapshot that governed the run. The last records how the run ended, with success or with
the refusal and its reason.

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

**Something failed?** Please [open an issue](https://github.com/protocol-governed-computing/pgc_install/issues)
with the step and its output. A demo that fails is a defect.
