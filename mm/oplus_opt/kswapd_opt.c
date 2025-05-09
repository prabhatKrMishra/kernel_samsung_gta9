// SPDX-License-Identifier: GPL-2.0-only
/*
 * kswapd_opt, contain some optimisation to reduce kswapd running overhead
 * for some high-order allocation
 *
 * Copyright (C) 2023-2025 Oplus. All rights reserved.
 */

#define pr_fmt(fmt) "kswapd_opt: " fmt

#include <linux/types.h>
#include <linux/mm.h>
#include <linux/module.h>
#include <linux/seq_file.h>
#include <linux/proc_fs.h>
#include <linux/jump_label.h>
#include <linux/sched.h>
#include <linux/string.h>
#include <trace/hooks/iommu.h>
#include <trace/hooks/mm.h>

DEFINE_STATIC_KEY_TRUE(alloc_adjust_enable);

static void alloc_adjust_flags(void *data, unsigned int order, gfp_t *flags)
{
	if (!static_branch_likely(&alloc_adjust_enable))
		return;

	if (order > PAGE_ALLOC_COSTLY_ORDER)
		*flags &= ~__GFP_RECLAIM;
}

static void kvmalloc_adjust_flags(void *data, size_t size, gfp_t *kvmalloc_flags, bool *unused)
{
	if (!static_branch_likely(&alloc_adjust_enable))
		return;

	if (get_order(size) > PAGE_ALLOC_COSTLY_ORDER)
		*kvmalloc_flags &= ~__GFP_RECLAIM;
}

static int register_alloc_adjust_flags(void)
{
	return register_trace_android_vh_adjust_alloc_flags(alloc_adjust_flags, NULL);
}

static void unregister_alloc_adjust_flags(void)
{
	unregister_trace_android_vh_adjust_alloc_flags(alloc_adjust_flags, NULL);
}

static int register_kvmalloc_adjust_flags(void)
{
	return register_trace_android_vh_kvmalloc_node_use_vmalloc(kvmalloc_adjust_flags, NULL);
}

static void unregister_kvmalloc_adjust_flags(void)
{
	unregister_trace_android_vh_kvmalloc_node_use_vmalloc(kvmalloc_adjust_flags, NULL);
}

static int __init kswapd_opt_init(void)
{
	int ret = 0;

	ret = register_alloc_adjust_flags();
	if (ret)
		pr_err("alloc_adjust_flags vendor_hook register failed: %d\n", ret);

	ret = register_kvmalloc_adjust_flags();
	if (ret)
		pr_err("kvmalloc_adjust_flags vendor_hook register failed: %d\n", ret);

	pr_info("%s init done\n", __func__);
	return 0;
}

static void __exit kswapd_opt_exit(void)
{
	unregister_alloc_adjust_flags();
	unregister_kvmalloc_adjust_flags();
	pr_info("%s exit\n", __func__);
}

module_init(kswapd_opt_init);
module_exit(kswapd_opt_exit);
MODULE_LICENSE("GPL v2");
