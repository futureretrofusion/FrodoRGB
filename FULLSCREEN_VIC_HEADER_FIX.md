# v1.0.19 fullscreen VIC header compile fix

Compiler error fixed:

```text
invalid use of incomplete type 'class MOS6569'
```

Cause: `C64.h` contains only `class MOS6569;`. Calling `ReInitColors()` requires the full class definition from `VIC.h`.

Correction:

```cpp
#include "C64.h"
#include "VIC.h"
```

No runtime logic was changed.
