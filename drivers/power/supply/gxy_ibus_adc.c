#include <linux/device.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/of.h>
#include <linux/iio/consumer.h>
#include <linux/iio/iio.h>
#include <linux/platform_device.h>    /* platform device */
#include "gxy_ibus_adc.h"
#include <linux/power/gxy_psy_sysfs.h>
static struct platform_device *g_md_adc_pdev;
static int g_adc_num;
static int g_adc_val;

static int gxy_ibus_get_adc_info(struct device *dev)
{
    int ret, val;
    struct iio_channel *md_channel;

    md_channel = iio_channel_get(dev, "gxy-ibus");

    ret = IS_ERR(md_channel);
    if (ret) {
        if (PTR_ERR(md_channel) == -EPROBE_DEFER) {
            pr_err("%s EPROBE_DEFER\r\n",
                    __func__);
            return -EPROBE_DEFER;
        }
        pr_err("fail to get iio channel (%d)\n", ret);
        goto Fail;
    }
    g_adc_num = md_channel->channel->channel;
    ret = iio_read_channel_raw(md_channel, &val);
    iio_channel_release(md_channel);
    if (ret < 0) {
        pr_err("iio_read_channel_raw fail\n");
        goto Fail;
    }

    g_adc_val = val;
    pr_info("md_ch = %d, val = %d\n", g_adc_num, g_adc_val);
    return ret;
Fail:
    return -1;
}

int gxy_ibus_get_adc_num(void)
{
    return g_adc_num;
}
EXPORT_SYMBOL(gxy_ibus_get_adc_num);

int gxy_ibus_get_adc_val(void)
{
    return g_adc_val;
}
EXPORT_SYMBOL(gxy_ibus_get_adc_val);

signed int battery_get_ibus_voltage(void)
{
    struct iio_channel *channel;
    int ret, val, number;

    if (!g_md_adc_pdev) {
        pr_err("fail to get g_md_adc_pdev\n");
        goto BAT_Fail;
    }
    channel = iio_channel_get(&g_md_adc_pdev->dev, "gxy-ibus");

    ret = IS_ERR(channel);
    if (ret) {
        pr_err("fail to get iio channel 3 (%d)\n", ret);
        goto BAT_Fail;
    }
    number = channel->channel->channel;
    ret = iio_read_channel_processed(channel, &val);
    iio_channel_release(channel);
    if (ret < 0) {
        pr_err("iio_read_channel_processed fail\n");
        goto BAT_Fail;
    }
    pr_debug("md_battery = %d, val = %d\n", number, val);

    return val;
BAT_Fail:
    pr_err("BAT_Fail, load default profile\n");
    return 0;

}

int battery_get_ibus_value(void)
{
    g_adc_val = battery_get_ibus_voltage();
    return g_adc_val;
}
EXPORT_SYMBOL(battery_get_ibus_value);

int gxy_ibus_adc_probe(struct platform_device *pdev)
{
    int ret;

    pr_info("gxy_ibus_adc probe start.\n");
    ret = gxy_ibus_get_adc_info(&pdev->dev);
    if (ret < 0) {
        pr_err("gxy_ibus get adc info fail");
        return ret;
    }
    g_md_adc_pdev = pdev;
    pr_info("gxy_ibus_adc probe end.\n");
    return 0;
}


static const struct of_device_id gxy_ibus_auxadc_of_ids[] = {
    {.compatible = "gxy, ibus_adc"},
    {}
};


static struct platform_driver gxy_ibus_adc_driver = {

    .driver = {
            .name = "gxy_ibus_adc",
            .of_match_table = gxy_ibus_auxadc_of_ids,
    },

    .probe = gxy_ibus_adc_probe,
};

static int __init gxy_ibus_adc_init(void)
{
    int ret;

    ret = platform_driver_register(&gxy_ibus_adc_driver);
    if (ret) {
        pr_err("gxy_ibus adc driver init fail %d", ret);
        return ret;
    }
    return 0;
}

module_init(gxy_ibus_adc_init);

MODULE_AUTHOR("zh");
MODULE_DESCRIPTION("battery adc driver");
MODULE_LICENSE("GPL");
