/*
 * am335x_evm.h
 *
 * Copyright (C) 2011 Texas Instruments Incorporated - https://www.ti.com/
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation version 2.
 *
 * This program is distributed "as is" WITHOUT ANY WARRANTY of any
 * kind, whether express or implied; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#ifndef __CONFIG_AM335X_EVM_H
#define __CONFIG_AM335X_EVM_H

#include <configs/ti_am335x_common.h>
#include <linux/sizes.h>

/* Clock Defines */
#define V_OSCK				24000000  /* Clock output from T2 */
#define V_SCLK				(V_OSCK)

#define CFG_SYS_SPI_KERNEL_OFFS      0x1E0000
#define CFG_SYS_SPI_ARGS_OFFS    0x2000000
#define CFG_SYS_SPI_ARGS_SIZE   0x10000f

#ifdef CONFIG_MTD_RAW_NAND
#define NANDARGS \
	"mtdids=" CONFIG_MTDIDS_DEFAULT "\0" \
	"mtdparts=" CONFIG_MTDPARTS_DEFAULT "\0" \
	"nandargs=setenv bootargs console=${console} " \
		"${optargs} " \
		"root=${nandroot} " \
		"rootfstype=${nandrootfstype}\0" \
	"nandroot=ubi0:rootfs rw ubi.mtd=NAND.file-system,2048\0" \
	"nandrootfstype=ubifs rootwait=1\0" \
	"nandboot=echo Booting from nand ...; " \
		"run nandargs; " \
		"nand read ${fdtaddr} NAND.u-boot-spl-os; " \
		"nand read ${loadaddr} NAND.kernel; " \
		"bootz ${loadaddr} - ${fdtaddr}\0"
#else
#define NANDARGS ""
#endif

#define BOOTENV_DEV_LEGACY_MMC(devtypeu, devtypel, instance) \
	"bootcmd_" #devtypel #instance "=" \
	"gpio clear 56; " \
	"gpio clear 55; " \
	"gpio clear 54; " \
	"gpio set 53; " \
	"setenv devtype mmc; " \
	"setenv mmcdev " #instance"; "\
	"setenv bootpart " #instance":1 ; "\
	"run boot\0"

#define BOOTENV_DEV_NAME_LEGACY_MMC(devtypeu, devtypel, instance) \
	#devtypel #instance " "

#define BOOTENV_DEV_NAND(devtypeu, devtypel, instance) \
	"bootcmd_" #devtypel "=" \
	"run nandboot\0"

#define BOOTENV_DEV_NAME_NAND(devtypeu, devtypel, instance) \
	#devtypel #instance " "

#if IS_ENABLED(CONFIG_CMD_USB)
# define BOOT_TARGET_USB(func) func(USB, usb, 0)
#else
# define BOOT_TARGET_USB(func)
#endif

#if CONFIG_IS_ENABLED(CMD_PXE)
# define BOOT_TARGET_PXE(func) func(PXE, pxe, na)
#else
# define BOOT_TARGET_PXE(func)
#endif

#if CONFIG_IS_ENABLED(CMD_DHCP)
# define BOOT_TARGET_DHCP(func) func(DHCP, dhcp, na)
#else
# define BOOT_TARGET_DHCP(func)
#endif

#define BOOT_TARGET_DEVICES(func) \
	func(MMC, mmc, 0) \
	func(LEGACY_MMC, legacy_mmc, 0) \
	func(MMC, mmc, 1) \
	func(LEGACY_MMC, legacy_mmc, 1) \
	BOOT_TARGET_USB(func) \
	BOOT_TARGET_PXE(func) \
	BOOT_TARGET_DHCP(func)

#include <config_distro_bootcmd.h>

#ifndef CONFIG_SPL_BUILD
#include <env/ti/dfu.h>
#include <env/ti/mmc.h>

#if CONFIG_SPI_FALLBACK
#define INIT_SECURE_FIT_SCAN "init_secure_fit_scan=" \
		"setenv addr_fit 0x90000000;" \
		"run importbootenv;" \
		"run switch_recovery;\0" 
#else
#define INIT_SECURE_FIT_SCAN "init_secure_fit_scan=" \
		"setenv addr_fit 0x90000000;"\
		"setenv secure_fit_filename SanCloud-SecureBOOT-image.fit;" \
		"run importbootenv;\0"
#endif	
			
#define SECURE_FIT_BOOT \
	INIT_SECURE_FIT_SCAN \
	"secure_fit_filename=SanCloud-SecureBOOT-image.fit;\0" \
	"switch_recovery=" \
		"setenv secure_fit_filename SanCloud-SecureFALLBACK-image.fit;" \
		"setenv bootargs console=ttyS0,115200n8 rootwait coherent_pool=1M net.ifnames=0 lpj=1990656 rng_core.default_quality=100 init=/init FALLBACK=TRUE quiet;\0" \
	"boot_secureFIT=" \
				"if test \"$secure_fit_filename\" = \"SanCloud-SecureBOOT-image.fit\"; then  " \
					"echo seting bootargs for normal boot...; " \
					"setenv bootargs console=ttyS0,115200n8 root=/dev/mmcblk${devnum}p${part} ro rootfstype=ext4 rootwait coherent_pool=1M net.ifnames=0 lpj=1990656 rng_core.default_quality=100 quiet;" \
				"fi;" \
				"load ${devtype} ${devnum}:${part} ${addr_fit} ${bootdir}/${secure_fit_filename};" \
				" echo Booting ${bootdir}/${secure_fit_filename} from ${devtype} ${devnum}:${part} ...; " \
				" echo bootargs=${bootargs}; " \
				"bootm ${addr_fit}||poweroff;\0" \
	"sleep_5s=for sec in 5 4 3 2 1; do " \
	            "echo -n \" ${sec}\";" \
				"sleep 1; 	" \
			"done;\0" \
	"scan_secure_fit=" \
		"run init_secure_fit_scan;" \
		"for retry in 1 2 3 4 5 6 7 8 9 10; do " \
			"for devtype in mmc usb; do " \
				"for devnum in 0 1; do " \
					"if ${devtype} dev ${devnum}; then " \
						"for part in 1 2 3 4; do " \
							"if test -e ${devtype} ${devnum}:${part} ${bootdir}/${secure_fit_filename}; then " \
								"echo Found ${secure_fit_filename} on ${devtype} ${devnum}:${part}; " \
								"setenv devtype ${devtype}; " \
								"setenv devnum ${devnum};" \
								"setenv part ${part}; " \
								"run boot_secureFIT;" \
								"exit;" \
							"fi; " \
						"done;" \
					"fi;" \
				"done;" \
			"done;" \
			"if test \"$secure_fit_filename\" = \"SanCloud-SecureBOOT-image.fit\"; then " \
				"if test \"$retry\" = 2; then " \
					"echo switching to recovery mod;" \
					"run switch_recovery;" \
				"fi;" \
			"fi;	" \
			"echo ${secure_fit_filename} image not found;" \
			"echo -n \"Retry #${retry} starting \";" \
			"run sleep_5s;" \
			"done;\0" 



#define CFG_EXTRA_ENV_SETTINGS \
	DEFAULT_LINUX_BOOT_ENV \
	DEFAULT_MMC_TI_ARGS \
	"bootpart=0:2\0" \
	"bootdir=/boot\0" \
	"bootfile=zImage\0" \
	"board_eeprom_header=undefined\0" \
	"fdtfile=undefined\0" \
	"console=ttyS0,115200n8\0" \
	"partitions=" \
		"uuid_disk=${uuid_gpt_disk};" \
		"name=bootloader,start=384K,size=1792K," \
			"uuid=${uuid_gpt_bootloader};" \
		"name=rootfs,start=2688K,size=-,uuid=${uuid_gpt_rootfs}\0" \
	"optargs=\0" \
	"ramroot=/dev/ram0 rw\0" \
	"ramrootfstype=ext2\0" \
	"spiroot=/dev/mtdblock4 rw\0" \
	"spirootfstype=jffs2\0" \
	"spisrcaddr=0xe0000\0" \
	"spiimgsize=0x362000\0" \
	"spibusno=0\0" \
	"spiargs=setenv bootargs console=${console} " \
		"${optargs} " \
		"root=${spiroot} " \
		"rootfstype=${spirootfstype}\0" \
	"ramargs=setenv bootargs console=${console} " \
		"${optargs} " \
		"root=${ramroot} " \
		"rootfstype=${ramrootfstype}\0" \
	"loadramdisk=load mmc ${mmcdev} ${rdaddr} ramdisk.gz\0" \
	"spiboot=echo Booting from spi ...; " \
		"run spiargs; " \
		"sf probe ${spibusno}:0; " \
		"sf read ${loadaddr} ${spisrcaddr} ${spiimgsize}; " \
		"bootz ${loadaddr}\0" \
	"eeprom_program="\
		"if test $board_eeprom_header = bbb_blank; then " \
			"run eeprom_dump; run eeprom_blank; run eeprom_bbb_header; run eeprom_dump; reset; fi; " \
		"if test $board_eeprom_header = bbbl_blank; then " \
			"run eeprom_dump; run eeprom_blank; run eeprom_bbb_header; run eeprom_bbbl_footer; run eeprom_dump; reset; fi; " \
		"if test $board_eeprom_header = bbbw_blank; then " \
			"run eeprom_dump; run eeprom_blank; run eeprom_bbb_header; run eeprom_bbbw_footer; run eeprom_dump; reset; fi; " \
		"if test $board_eeprom_header = pocketbeagle_blank; then " \
			"run eeprom_dump; run eeprom_blank; run eeprom_pocketbeagle; run eeprom_dump; reset; fi; " \
		"if test $board_eeprom_header = bbgg_blank; then " \
			"run eeprom_dump; run eeprom_blank; run eeprom_bbb_header; run eeprom_bbgg_footer; run eeprom_dump; reset; fi; " \
		"if test $board_eeprom_header = beaglelogic_blank; then " \
			"run eeprom_dump; run eeprom_blank; run eeprom_beaglelogic; run eeprom_dump; reset; fi;  \0" \
	"ramboot=echo Booting from ramdisk ...; " \
		"run ramargs; " \
		"bootz ${loadaddr} ${rdaddr} ${fdtaddr}\0" \
	"findfdt="\
		"echo board_name=[$board_name] ...; " \
		"if test $board_name = A335BLGC; then " \
			"setenv fdtfile am335x-beaglelogic.dtb; fi; " \
		"if test $board_name = A335BONE; then " \
			"setenv fdtfile am335x-bone.dtb; fi; " \
		"if test $board_name = A335BNLT; then " \
			"echo board_rev=[$board_rev] ...; " \
			"if test $board_rev = GH01; then " \
				"setenv fdtfile am335x-boneblack.dtb; " \
			"elif test $board_rev = BBG1; then " \
				"setenv fdtfile am335x-bonegreen.dtb; " \
			"elif test $board_rev = BP00; then " \
				"setenv fdtfile am335x-pocketbone.dtb; " \
			"elif test $board_rev = GW1A; then " \
				"setenv fdtfile am335x-bonegreen-wireless.dtb; " \
			"elif test $board_rev = GG1A; then " \
				"setenv fdtfile am335x-bonegreen-gateway.dtb; " \
			"elif test $board_rev = AIA0; then " \
				"setenv fdtfile am335x-abbbi.dtb; " \
			"elif test $board_rev = EIA0; then " \
				"setenv fdtfile am335x-boneblack.dtb; " \
			"elif test $board_rev = ME06; then " \
				"setenv fdtfile am335x-bonegreen.dtb; " \
			"elif test $board_rev = OS00; then " \
				"setenv fdtfile am335x-osd3358-sm-red.dtb; " \
			"elif test $board_rev = OS01; then " \
				"setenv fdtfile am335x-osd3358-sm-red-v4.dtb; " \
			"else " \
				"setenv fdtfile am335x-boneblack.dtb; " \
			"fi; " \
		"fi; " \
		"if test $board_name = A335PBGL; then " \
			"setenv fdtfile am335x-pocketbeagle.dtb; fi; " \
		"if test $board_name = BBBW; then " \
			"setenv fdtfile am335x-boneblack-wireless.dtb; fi; " \
		"if test $board_name = BBG1; then " \
			"setenv fdtfile am335x-bonegreen.dtb; fi; " \
		"if test $board_name = BBGW; then " \
			"setenv fdtfile am335x-bonegreen-wireless.dtb; fi; " \
		"if test $board_name = BBGG; then " \
			"setenv fdtfile am335x-bonegreen-gateway.dtb; fi; " \
		"if test $board_name = BBBL; then " \
			"setenv fdtfile am335x-boneblue.dtb; fi; " \
		"if test $board_name = BBEN; then " \
			"setenv fdtfile am335x-sancloud-bbe.dtb; fi; " \
		"if test $board_name = BBELITE; then " \
			"setenv fdtfile am335x-sancloud-bbe-lite.dtb; fi; " \
		"if test $board_name = BBE_EX_WIFI; then " \
			"setenv fdtfile am335x-sancloud-bbe-extended-wifi.dtb; fi; " \
		"if test $board_name = OS00; then " \
			"setenv fdtfile am335x-osd3358-sm-red.dtb; fi; " \
		"if test $board_name = OS01; then " \
			"setenv fdtfile am335x-osd3358-sm-red-v4.dtb; fi; " \
		"if test $board_name = A33515BB; then " \
			"setenv fdtfile am335x-evm.dtb; fi; " \
		"if test $board_name = A335X_SK; then " \
			"setenv fdtfile am335x-evmsk.dtb; fi; " \
		"if test $board_name = A335_ICE; then " \
			"setenv fdtfile am335x-icev2.dtb; " \
			"if test $ice_mii = mii; then " \
				"setenv pxe_label_override Pruss; fi;" \
		"fi; " \
		"if test $fdtfile = undefined; then " \
			"setenv board_name A335BNLT; " \
			"setenv board_rev EMMC; " \
			"setenv fdtfile am335x-bonegreen.dtb; " \
		"fi; \0" \
		"init_console=" \
		"if test $board_name = A335_ICE; then "\
			"setenv console ttyS3,115200n8;" \
		"elif test $board_name = A335BLGC; then " \
			"setenv console ttyS4,115200n8;" \
		"else " \
			"setenv console ttyS0,115200n8;" \
		"fi;\0" \
	EEWIKI_BOOT \
	SECURE_FIT_BOOT \
	EEWIKI_UNAME_BOOT \
	EEPROM_PROGRAMMING \
	NANDARGS \
	NETARGS \
	DFUARGS \
	BOOTENV
#endif

/* NS16550 Configuration */
#define CFG_SYS_NS16550_COM1		0x44e09000	/* Base EVM has UART0 */
#define CFG_SYS_NS16550_COM2		0x48022000	/* UART1 */
#define CFG_SYS_NS16550_COM3		0x48024000	/* UART2 */
#define CFG_SYS_NS16550_COM4		0x481a6000	/* UART3 */
#define CFG_SYS_NS16550_COM5		0x481a8000	/* UART4 */
#define CFG_SYS_NS16550_COM6		0x481aa000	/* UART5 */

/* SPL */
#ifndef CONFIG_NOR_BOOT

/* USB gadget RNDIS */
#endif

#ifdef CONFIG_MTD_RAW_NAND
/* NAND: device related configs */
/* NAND: driver related configs */
#define CFG_SYS_NAND_ECCPOS		{ 2, 3, 4, 5, 6, 7, 8, 9, \
					 10, 11, 12, 13, 14, 15, 16, 17, \
					 18, 19, 20, 21, 22, 23, 24, 25, \
					 26, 27, 28, 29, 30, 31, 32, 33, \
					 34, 35, 36, 37, 38, 39, 40, 41, \
					 42, 43, 44, 45, 46, 47, 48, 49, \
					 50, 51, 52, 53, 54, 55, 56, 57, }

#define CFG_SYS_NAND_ECCSIZE		512
#define CFG_SYS_NAND_ECCBYTES	14
#endif /* !CONFIG_MTD_RAW_NAND */

/*
 * For NOR boot, we must set this to the start of where NOR is mapped
 * in memory.
 */


/*
 * Disable MMC DM for SPL build and can be re-enabled after adding
 * DM support in SPL
 */
#ifdef CONFIG_SPL_BUILD
#undef CONFIG_DM_MMC
#undef CONFIG_TIMER
#endif

#if defined(CONFIG_SPL_BUILD) && defined(CONFIG_SPL_USB_ETHER)
/* Remove other SPL modes. */
/* disable host part of MUSB in SPL */
/* disable EFI partitions and partition UUID support */
#endif

/* USB Device Firmware Update support */
#ifndef CONFIG_SPL_BUILD
#define DFUARGS \
	DFU_ALT_INFO_EMMC \
	DFU_ALT_INFO_MMC \
	DFU_ALT_INFO_RAM \
	DFU_ALT_INFO_NAND
#endif

/*
 * NOR Size = 16 MiB
 * Number of Sectors/Blocks = 128
 * Sector Size = 128 KiB
 * Word length = 16 bits
 * Default layout:
 * 0x000000 - 0x07FFFF : U-Boot (512 KiB)
 * 0x080000 - 0x09FFFF : First copy of U-Boot Environment (128 KiB)
 * 0x0A0000 - 0x0BFFFF : Second copy of U-Boot Environment (128 KiB)
 * 0x0C0000 - 0x4BFFFF : Linux Kernel (4 MiB)
 * 0x4C0000 - 0xFFFFFF : Userland (11 MiB + 256 KiB)
 */
#if defined(CONFIG_NOR)
#define CONFIG_SYS_MAX_FLASH_SECT	128
#define CFG_SYS_FLASH_BASE		(0x08000000)
#define CONFIG_SYS_FLASH_CFI_WIDTH	FLASH_CFI_16BIT
#define CFG_SYS_FLASH_SIZE		0x01000000
#define CONFIG_SYS_MONITOR_BASE		CONFIG_SYS_FLASH_BASE
#endif  /* NOR support */

#endif	/* ! __CONFIG_AM335X_EVM_H */
