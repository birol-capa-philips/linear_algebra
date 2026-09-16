# !/bin/bash
# make_VIP2_SMP_POSIX.sh  creates a VIP project using the itl_generic BSP.
#  NOTES:
#  1. You must run this VIP creation script from a VxWorks 6.9.2 development shell.
#  2. You can import this VIP project in-place from your workspace into WorkBench.
#  3. Many of these components are the defaults from the BSP.
#  4. "S" parameter on bootline tells VxWorks to use a startup script
#  5. With the default itl_generic MP_TABLES, not ACPI, SMP will recognize only physical cores, not HW threads
#  6. In BSP's sysLib.c, you must add the following 8 lines at the bottom to enable
#     WRITABLE anonymous FTP privileges:
#
#     #include <ipcom_sock.h>
#     #include <ipftps.h>
#     int myAuthenticateCallback (Ipftps_session * session, char * password)
#     {
#     	 /* It should return 0 (zero) if the password is valid for the session, */
#        /* or 1 (one) if you cannot validate the password.                     */
#     	 return 0;
#     }
# -------------------------------------------------------------------------------------------------------------
set -x
cd $HOME/workspacePOSIX
#vxprj create itl_generic gnu /home/demo/workspacePOSIX/VIP2_SMP_POSIX/VIP2_SMP_POSIX.wpj -smp -ilp32 -profile PROFILE_DEVELOPMENT -vsb /home/demo/workspacePOSIX/VSB_6921
vxprj create itl_generic gnu /home/demo/workspacePOSIX/VIP2_SMP_POSIX/VIP2_SMP_POSIX.wpj -smp -ilp32 -profile PROFILE_STANDALONE_DEVELOPMENT
cd VIP2_SMP_POSIX
# Since PROFILE_STANDALONE_DEVELOPMENT (new LLL BSPs) does not include Windview, include it here:
vxprj component add INCLUDE_RBUFF
vxprj component add INCLUDE_WVUPLOAD_TSFSSOCK
vxprj component add INCLUDE_WVUPLOAD_FILE
vxprj component add INCLUDE_WINDVIEW_CLASS
vxprj component add INCLUDE_WINDVIEW
vxprj component add INCLUDE_SYS_TIMESTAMP
# The following line would probably duplicate the action of PROFILE_STANDALONE_DEVELOPMENT (new LLL BSPs)
#vxprj bundle add BUNDLE_STANDALONE_SHELL
#  C++ is often needed, so include it
vxprj component add INCLUDE_CPLUS_LANG
vxprj component add INCLUDE_CPLUS
vxprj component add INCLUDE_CTORS_DTORS
vxprj component add INCLUDE_CPLUS_DEMANGLER
#  Sometimes you will want to compile DEBUG and unoptimized
#  vxprj debug on
vxprj component remove INCLUDE_DIAB_INTRINSICS
vxprj component add INCLUDE_WDB_ALWAYS_ENABLED
# The following line would duplicate the action of PROFILE_STANDALONE_DEVELOPMENT (new LLL BSPs)
# vxprj component add INCLUDE_STANDALONE_SYM_TBL
# Need VNIC adapter for L2 Switch under Hypervisor 2.0
#vxprj component add INCLUDE_VNIC_VXB_END
#vxprj component add INCLUDE_VNIC_VXB_L2SWITCH_END
# Interrupt mode isn't supported currently so to get the best performance from
# the VNIC you need to poll at a higher rate than the clock tick. This means using
# a low priority task that catches unused cycles.
# The default poll delay is 1 tick, but has a suitably high priority task.
#vxprj parameter set VNIC_POLL_DELAY 0
# Include shared memory MIPC for Hypervisor
#vxprj component add INCLUDE_MIPC_HV
#vxprj component add INCLUDE_MIPC_HV_SM
# Include network components
vxprj component add INCLUDE_IFCONFIG
vxprj component add INCLUDE_IPNET_IFCONFIG_1
vxprj component add INCLUDE_PING
# Simics has a TFTP server built-in, so add a TFTP client:
#vxprj component add INCLUDE_IPTFTP_CLIENT_CMD
#vxprj component add INCLUDE_IPTFTPC
vxprj component add INCLUDE_FTP
vxprj component add INCLUDE_IPFTPC
vxprj component add INCLUDE_IPFTPS
vxprj parameter set FTPS_AUTH_CALLBACK_HOOK "myAuthenticateCallback"
# A backslash prevents shell expansion of the following quotation mark:
vxprj parameter set FTPS_INITIAL_DIR "\"/ram0/"\"
vxprj parameter set FTPS_ROOT_DIR "\"/"\"
# xxx GK parameter FTPS_INSTALL_CALLBACK_HOOK no longer exists in 6.9.2
#vxprj parameter set FTPS_INSTALL_CALLBACK_HOOK TRUE
vxprj component add INCLUDE_IPTELNETS
vxprj component add INCLUDE_TELNET_CLIENT
#
vxprj component add INCLUDE_PCI_BUS_SHOW
vxprj component add INCLUDE_VXBUS_SHOW
#  Remove or add HDD controllers as needed
vxprj component remove INCLUDE_DRV_STORAGE_INTEL_ICH
vxprj component remove INCLUDE_DRV_STORAGE_INTEL_AHCI
# Reduce unnecessary serial character output using the next 2 lines. Best not to output characters early in the boot.
#vxprj component remove INCLUDE_SHELL_BANNER
#vxprj component remove INCLUDE_WDB_BANNER
#
# Not sure how to make a larger INCLUDE_IPCOM_USE_RAM_DISK, so use a
# conventional RAM DISK instead, sized to 16MB. This requires the
# following call to be added to usrAppInit() in usrAppInit.c:
#      dosfsDiskFormat("/ram0");
vxprj component add INCLUDE_RAM_DISK
vxprj parameter set RAM_DISK_SIZE 0x1000000
# The following 6 lines plus OHCI would duplicate the action of PROFILE_STANDALONE_DEVELOPMENT (new LLL BSPs use USB2*)
#vxprj component add INCLUDE_USB
#vxprj component add INCLUDE_USB_INIT
#vxprj component add INCLUDE_UHCI
#vxprj component add INCLUDE_UHCI_INIT
#vxprj component add INCLUDE_EHCI
#vxprj component add INCLUDE_EHCI_INIT
# The following 5 lines would duplicate the action of PROFILE_STANDALONE_DEVELOPMENT (new LLL BSPs use USB2*)
#vxprj component add INCLUDE_USB_KEYBOARD
#vxprj component add INCLUDE_USB_KEYBOARD_INIT
#  Use "remove" instead on the next 2 lines for SIO terminal only (no PC CONSOLE)
#vxprj component add INCLUDE_USB_KEYBOARD_SHELL_ATTACH
#vxprj component add INCLUDE_PC_CONSOLE
# The following 2 lines would duplicate the action of PROFILE_STANDALONE_DEVELOPMENT (new LLL BSPs use USB2*)
#vxprj component add INCLUDE_USB_MS_BULKONLY_INIT
#vxprj component add INCLUDE_USB_MS_BULKONLY
vxprj component add INCLUDE_DOSFS_FMT
vxprj component add INCLUDE_FS_MONITOR
# Add POSIX Support
vxprj bundle add BUNDLE_POSIX
vxprj component add INCLUDE_POSIX_CLOCKS
vxprj component add INCLUDE_TLS
# The next 3 components are already included by the previous 3 POSIX inclusions
# vxprj component add INCLUDE_GETADDRINFO_SYSCTL
# vxprj component add INCLUDE_POSIX_PTHREADS
# vxprj component add INCLUDE_POSIX_PTHREAD_SCHEDULER
# RTP with userspace POSIX Support. Switch DEVELOP to DEPLOY when ready to ship product.
vxprj bundle add BUNDLE_RTP_DEVELOP
vxprj bundle add BUNDLE_RTP_POSIX_PSE52
# Remove VRFS component that causes problems for CANBUS driver
vxprj component remove INCLUDE_VRFS
# Increase system clock speed from 60 to 500Hz to improve POSIX timer resolution to 2ms
vxprj parameter set SYS_CLK_RATE 500
# Add timing support
vxprj component add INCLUDE_TIMESTAMP
# New 11-08-2012 - add TSC timestamp
vxprj component add DRV_TIMER_IA_TIMESTAMP
# See prjParams.h: defined string must be in quotation marks, and need to add a backslash in this file before each double quotation mark:
#vxprj parameter set DEFAULT_BOOT_LINE "\"gei(0,0)host:/home/demo/workspacePOSIX/VIP2_SMP_POSIX/default/vxWorks h=128.224.88.80 e=128.224.88.23:ffffff00 g=128.224.88.1 u=demo pw=demo f=0x8 tn=Kontronivy\""
#vxprj parameter set IFCONFIG_1 "\"ifname gei0\",\"devname gei0\",\"inet driver\",\"gateway driver\""
#  Run optional checks
# vxprj tccheck
# vxprj check
# vxprj validateBsp
#  Build the VIP
vxprj build
set +x

