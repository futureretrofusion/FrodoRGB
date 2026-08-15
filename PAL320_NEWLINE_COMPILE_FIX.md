# PAL320 generated-newline compile correction

v1.0.22 accidentally stored the newly inserted PAL320 implementation as one source line containing literal `\n` sequences. GCC consequently reported `nstatic does not name a type` and stray `n` tokens.

v1.0.23 replaces those sequences with real line breaks and adds a source-integrity test. No runtime display logic changed.
