/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _AW35615_GLOBAL_H_
#define _AW35615_GLOBAL_H_

#include <linux/i2c.h>
#include <linux/hrtimer.h>
#include <linux/semaphore.h>
#include <linux/workqueue.h>
#include <linux/regulator/consumer.h>
/* Tab A9_V code for AL6739VDEV-13 by zhangziyi at 20240925 start */
#include <linux/pm_qos.h>
#include <linux/alarmtimer.h>
/* Tab A9_V code for AL6739VDEV-13 by zhangziyi at 20240925 end */

#include "Port.h"
#include "modules/dpm.h"
#include "../inc/tcpci.h"
#include "../inc/tcpm.h"

#ifdef AW_KERNEL_VER_OVER_4_19_1
#include <linux/pm_wakeup.h>
#else
#include <linux/wakelock.h>
#endif

#ifdef AW_DEBUG
#include <linux/debugfs.h>
#endif // AW_DEBUG

/*Tab A9 code for AX6739A-224 by wenyaqi at 20230603 start*/
#define TICK_SCALE_TO_MS            (1)
/* Tab A9_V code for AL6739VDEV-13 by zhangziyi at 20240925 start */
#define AW35615_CHIP_ID				(0x344f)
/* Tab A9_V code for AL6739VDEV-13 by zhangziyi at 20240925 end */

struct aw35615_chip {
    struct i2c_client *client;
    struct tcpc_device *tcpc;
    struct tcpc_desc *tcpc_desc;
    /* Tab A9_V code for AL6739VDEV-13 by zhangziyi at 20240925 start */
    struct pm_qos_request pm_gos_request;
    AW_U16 chip_id;
    AW_BOOL is_vbus_present;
    AW_U8 old_event;

    AW_BOOL wakelock_flag;
    #ifdef AW_KERNEL_VER_OVER_4_19_1
    struct wakeup_source *aw35615_wakelock;          // Wake lock
    #else
    struct wake_lock aw35615_wakelock;               // Wake lock
    #endif // AW_KERNEL_VER_OVER_4_19_1

    struct semaphore suspend_lock;

    /* Internal config data */
    AW_S32 numRetriesI2C;

    /* GPIO */
    AW_S32 gpio_IntN; /* INT_N GPIO pin */
    AW_S32 gpio_IntN_irq; /* IRQ assigned to INT_N GPIO pin */

    /* Threads */
    struct work_struct sm_worker; /* Main state machine actions */
    struct workqueue_struct *highpri_wq;
    struct delayed_work init_delay_work;
    struct work_struct bist_work;
    /* Tab A9_V code for P241112-05620 by xiongxiaoliang at 20241225 start */
    struct delayed_work notify_work;
    /* Tab A9_V code for P241112-05620 by xiongxiaoliang at 20241225 end */
    AW_BOOL queued;

    /* Timers */
    struct hrtimer bist_timer;
    struct hrtimer sm_timer;
    struct alarm alarmtimer;
    AW_U32 sink_timer;
    AW_U32 source_timer;
    AW_U32 source_end_timer;
    AW_U8 sink_reg_bist;
    AW_U8 source_reg_bist;
    /* Tab A9_V code for AL6739VDEV-13 by zhangziyi at 20240925 end */

    /* Port Object */
    Port_t port;
    DevicePolicyPtr_t dpm;
};
/*Tab A9 code for AX6739A-224 by wenyaqi at 20230603 end*/

extern struct aw35615_chip *g_chip;

struct aw35615_chip *aw35615_GetChip(void);         // Getter for the global chip structure
void aw35615_SetChip(struct aw35615_chip *newChip); // Setter for the global chip structure

#endif /* _AW35615_GLOBAL_H_ */

