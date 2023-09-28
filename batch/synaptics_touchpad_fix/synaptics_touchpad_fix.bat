:: Prevent Synaptics Touchpad driver causing a diagnostics dialogue pop-up
@reg add HKLM\SYSTEM\CurrentControlSet\services\SynTP\Parameters\Debug /v DumpKernel /d 00000000 /t REG_DWORD