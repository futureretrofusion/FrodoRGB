#!/usr/bin/env python3
from pathlib import Path
import re
import sys
root = Path(__file__).resolve().parents[1]
v = (root / 'VIC.cpp').read_text(encoding='utf-8', errors='replace')
c = (root / 'FRFBuildConfig.h').read_text(encoding='utf-8', errors='replace')
checks = {
    'FIX46 marker': 'FRF_VIC_FIX46_PHASE_SWEEP' in v,
    'normal bias macro': '#define FRF_VIC_PHASE_BIAS_NORMAL 1' in v,
    'expanded bias macro': '#define FRF_VIC_PHASE_BIAS_EXPANDED FRF_VIC_PHASE_BIAS_NORMAL' in v,
    'single row helper': v.count('frf_vic_late_sprite_row(') == 3,
    'late Y uses helper': 'int row = frf_vic_late_sprite_row(diff, (mye & sbit) != 0);' in v,
    'FIX42 retained': 'FRF_VIC_FIX42_LATE_SPRITE_Y_COMPARE' in v and 'FRF_VIC_FIX42_ENABLE_CATCHUP' in v,
    'no failed redraw': 'frf_vic_flush_late_sprite_line' not in v and 'FRF_VIC_FIX44' not in v,
    'version': 'FRF_EDITION_VERSION "1.0.26"' in c,
}
failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(('PASS' if ok else 'FAIL') + ': ' + name)
if failed:
    sys.exit(1)

def row(diff, expanded, normal_bias, expanded_bias):
    phase = max(diff - (expanded_bias if expanded else normal_bias), 0)
    return phase // 2 if expanded else phase

assert [row(i, False, 0, 0) for i in range(5)] == [0, 1, 2, 3, 4]
assert [row(i, False, 1, 1) for i in range(5)] == [0, 0, 1, 2, 3]
assert [row(i, False, 2, 2) for i in range(5)] == [0, 0, 0, 1, 2]
assert [row(i, True, 1, 1) for i in range(6)] == [0, 0, 0, 1, 1, 2]
assert [row(i, True, 2, 2) for i in range(6)] == [0, 0, 0, 0, 1, 1]
print('FRF_VIC_FIX46 phase-sweep source checks passed')
