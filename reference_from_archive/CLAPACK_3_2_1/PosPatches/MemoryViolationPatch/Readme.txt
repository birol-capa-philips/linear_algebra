The folder contain patch that are needed to fix memory violations report by ASAN.
The original files are suffixed with .original extension. 
The src already contains the patched coded. Hence we do not need to take any action,
These files are here just for information on what has changed. 
When we take new version from CLAPACK. Please apply these changes to fix the memory violations.
Any future issues that are found also need to be patched and included in this folder.
Update four *.a static libs in \PENTIUMgnu. These are generated with running VxWorks build

Revision history
----------------
1. 16-OCT-2025: Fixed files dgesvd.c and ilaenv.c for memory violations reported by ASAN run.