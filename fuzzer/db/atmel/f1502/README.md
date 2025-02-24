## Product Term Cofiguration

* Fi — foldback outputs, i — 1-based.
* Pi — positive (non-inverted) outputs from UIM, 0-based.
* Ni — negative (inverted) outputs from UIM, 0-based.

Product term connections to Fi, Pi and Ni controlled by single bit,
active-low. Control bit positions:

* Fi — base + (i - 1).
* Pi — base + 16 + (i × 2) + (i ∧ 1).
* Ni — base + 16 + (i × 2) + (i ∧ 1 ⊕ 1).

Where:

* base is a product term base address;
* 16 — number of foldback outputs per LAB.

## Proposed MC Expressions

* CK0..CK1 — Clock source selection.
* PM1..PM5 — Mask-out PT1..PT5 for special function.
* OE0..OE2 — Output Enable source selection.

### MC Control bits

0. PM3 — Mask-out PT3: disable for OR, enable for PTAR.
1. PM4 — Mask-out PT4: disable for OR, enable for PTCK/PTCE.
2. PM5 — Mask-out PT5: disable for OR, enable for PTAR/PTOE.
3. NEG — Negate OR output.
4. PM1 — Mask-out PT1: disable for OR, enable for foldback/XOR.
5. XFA — XOR-gate lower input Function.
6. PM2 — Mask-out PT2: disable for OR, enable for XNOR/Fast-In.
7. TFF — select register output as upper input of XOR gate.
8. OD — Open Drain output, push-pull output otherwise.
9. FC — Feedback Combinatorial (not registered).
10. LP — Low Power mode.
11. PD — Power Down: disable PT power for this MC.
12. CK1 — Clock source selection, bit 1, active-low.
13. CK0 — Clock source selection, bit 0, active-high.
14. SLOW — Slow slew rate, fast slew rate otherwise.
15. CE — Clock Enable: enable clock unconditionally, use PT4 function otherwise.
16. FF — flip-flop mode, latch mode otherwise.
17. FI — Fast-In: if output registered then use MC pin as a register source
    else use PT2 as a source (active-low), OR/XOR output otherwise.
18. OC — Output Combinatorial, registered otherwise.
19. GAR — Global Async Reset Enable (active-low).
20. OE2 — Output Enable source selection, bit 2.
21. OE1 — Output Enable source selection, bit 1.
22. PAP — PT Async Preset: use PF5 as asynchronous preset, use PF5 as output
    enable otherwise (if enabled by OE switch).
23. OE0 — Output Enable source selection, bit 0.

Control bit positions:

* k    = (i₁ ? m : !m)
* addr = base + 16 + (i₀ ⊕ k₀) + (k × 2) + (i₁ × 32) + (i/4 × 80)

Where:

* base is a LAB base address;
* 16 — number of reserved bits;
* i — 0-based control bit index;
* m — 0-based MC index in LAB.

### Product Term Allocator

The product term allocator (PTA) receives the product terms of the current
MC, the cascaded output of the previous MC, and produces values for logical
summation, as well as values for forming special functions and fast
combinatorial function output.

```c
OR1 = PM1 ? 0 : PT1	= PT1 & !PM1
OR2 = PM2 ? 0 : PT2	= PT2 & !PM2
OR3 = PM3 ? 0 : PT3	= PT3 & !PM3
OR4 = PM4 ? 0 : PT4	= PT4 & !PM4
OR5 = PM5 ? 0 : PT5	= PT5 & !PM5
OR6 = CI					/* Cascade-In		*/

PF1 = PM1 ? PT1 : 1	= PT1 | !PM1		/* foldback, XOR	*/
PF2 = PM2 ? PT2 : 1	= PT2 |	!PM2		/* XA, Fast-In		*/
PF3 = PM3 ? PT3 : 0	= PT3 &  PM3		/* PTAR			*/
PF4 = PM4 ? PT4 : 1	= PT4 | !PM4		/* PTCK, PTCE		*/
PF5 = PM5 ? PT5 : 1	= PT5 | !PM5		/* PTOE, PTAP		*/
```

### Logical Function Block

The logic function block computes a combinatorial function from product
terms and provides the computed values for the combinatorial output and
feedback, for the register input, and for the foldback and cascade outputs.

```c
OR  = OR1 | OR2 | OR3 | OR4 | OR5 | OR6		/* Logical summ		*/

XA  = XFA ? PF2 : OR
CO  = XFA ? OR  : 0	= XFA & OR		/* Cascade-Out		*/

FO  = !PF1					/* Foldback Output	*/
FV  = XA ^ NEG ^ PF1 ^ !(TFF & R.q)		/* Function Value	*/
```

### Register and Output Block

The register and output block calculates values for the register inputs,
the feedback and pin output values, and the tri-state output buffer control
signal.

```c
R.d  = FI ? (OC ? PT2 : PI) : FV		/* PI — pin input	*/

R.ar = PF3 | GCLR & GAR

R.ck = CK1 ? (CK0 ? GCK3 : (CE ? PF4 : GCK2)) :
             (CK0 ? GCK1 : GND              )
R.ce = CE | PF4

R.ap = PAP & PF5
PTOE = PAP | PF5

FB   = FC ? FV : R.q				/* Feedback Output	*/
PO   = OC ? FV : R.q				/* Pin Output		*/

PO.oe = [0, GOE1, GOE2, GOE3, GOE4, GOE5, GOE6, PTOE][OE2..OE0]
```
