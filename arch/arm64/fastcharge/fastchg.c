/*
 * based on sysfs interface from:
 *	Chad Froebel <chadfroebel@gmail.com> &
 *	Jean-Pierre Rasquin <yank555.lu@gmail.com>
 * for backwards compatibility
 *
 * This software is licensed under the terms of the GNU General Public
 * License version 2, as published by the Free Software Foundation, and
 * may be copied, distributed, and modified under those terms.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

/*
 * Possible values for "force_fast_charge" are :
 *
 *   0 - disabled (default)
 *   1 - custom
 *
*/

#include <linux/module.h>
#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/fastchg.h>

#define FAST_CHARGE_VERSION	"version 1.0 by Paul Reioux"
#define IVBUS_MIN_FAST_CHARGE_LEVEL 500 /* uA */
#define IVBUS_MAX_FAST_CHARGE_LEVEL 1500 /* uA */
#define USB_MIN_FAST_CHARGE_LEVEL 500 /* uA */
#define USB_MAX_FAST_CHARGE_LEVEL 900 /* uA */

int force_fast_charge; //disable by default
int fast_charge_level = 1250;
int usb_fast_charge_level = 600; //new usb fast charge level

/* sysfs interface for "force_fast_charge" */
static ssize_t force_fast_charge_show(struct kobject *kobj,
			struct kobj_attribute *attr, char *buf)
{
	return sprintf(buf, "%d\n", force_fast_charge);
}

static ssize_t force_fast_charge_store(struct kobject *kobj,
			struct kobj_attribute *attr, const char *buf,
			size_t count)
{

	int new_force_fast_charge;

	sscanf(buf, "%du", &new_force_fast_charge);

	switch(new_force_fast_charge) {
		case FAST_CHARGE_DISABLED:
		case FAST_CHARGE_ENABLED:
			force_fast_charge = new_force_fast_charge;
			return count;
		default:
			return -EINVAL;
	}
}

static ssize_t charge_level_show(struct kobject *kobj,
				struct kobj_attribute *attr, char *buf)
{
	return sprintf(buf, "%d\n", fast_charge_level);
}

static ssize_t charge_level_store(struct kobject *kobj,
			struct kobj_attribute *attr, const char *buf,
			size_t count)
{

	int new_charge_level;

	sscanf(buf, "%du", &new_charge_level);
	if(new_charge_level >= IVBUS_MIN_FAST_CHARGE_LEVEL && new_charge_level <= IVBUS_MAX_FAST_CHARGE_LEVEL){
	    fast_charge_level = new_charge_level;
	    return count;
	}
	else if(new_charge_level < IVBUS_MIN_FAST_CHARGE_LEVEL){
	    fast_charge_level = IVBUS_MIN_FAST_CHARGE_LEVEL;
	    return count;
	}
	else if(new_charge_level > IVBUS_MAX_FAST_CHARGE_LEVEL){
	    fast_charge_level = IVBUS_MAX_FAST_CHARGE_LEVEL;
	    return count;
	}
}

static ssize_t usb_charge_level_show(struct kobject *kobj,
				struct kobj_attribute *attr, char *buf)
{
	return sprintf(buf, "%d\n", usb_fast_charge_level);
}

static ssize_t usb_charge_level_store(struct kobject *kobj,
			struct kobj_attribute *attr, const char *buf,
			size_t count)
{

	int new_usb_charge_level;

	sscanf(buf, "%du", &new_usb_charge_level);
	if(new_usb_charge_level >= USB_MIN_FAST_CHARGE_LEVEL && new_usb_charge_level <= USB_MAX_FAST_CHARGE_LEVEL){
	    usb_fast_charge_level = new_usb_charge_level;
	    return count;
	}
	else if(new_usb_charge_level < USB_MIN_FAST_CHARGE_LEVEL){
	    fast_charge_level = USB_MIN_FAST_CHARGE_LEVEL;
	    return count;
	}
	else if(new_usb_charge_level > USB_MAX_FAST_CHARGE_LEVEL){
	    fast_charge_level = USB_MAX_FAST_CHARGE_LEVEL;
	    return count;
	}	
}

/* sysfs interface for "fast_charge_levels" */
static ssize_t available_charge_levels_show(struct kobject *kobj,
			struct kobj_attribute *attr, char *buf)
{
	return sprintf(buf, "%s\n", IVBUS_FAST_CHARGE_LEVELS);
	return sprintf(buf, "%s\n", USB_FAST_CHARGE_LEVELS);
}

/* sysfs interface for "version" */
static ssize_t version_show(struct kobject *kobj,
			struct kobj_attribute *attr, char *buf)
{
	return sprintf(buf, "%s\n", FAST_CHARGE_VERSION);
}

static struct kobj_attribute version_attribute =
	__ATTR(version, 0444, version_show, NULL);

static struct kobj_attribute available_charge_levels_attribute =
	__ATTR(available_charge_levels, 0444,
		available_charge_levels_show, NULL);

static struct kobj_attribute fast_charge_level_attribute =
	__ATTR(fast_charge_level, 0666,
		charge_level_show,
		charge_level_store);

static struct kobj_attribute usb_fast_charge_level_attribute =
	__ATTR(usb_fast_charge_level, 0666,
		usb_charge_level_show,
		usb_charge_level_store);

static struct kobj_attribute force_fast_charge_attribute =
	__ATTR(force_fast_charge, 0666,
		force_fast_charge_show,
		force_fast_charge_store);

static struct attribute *force_fast_charge_attrs[] = {
	&force_fast_charge_attribute.attr,
	&usb_fast_charge_level_attribute.attr,
	&fast_charge_level_attribute.attr,
	&available_charge_levels_attribute.attr,
	&version_attribute.attr,
	NULL,
};

static struct attribute_group force_fast_charge_attr_group = {
	.attrs = force_fast_charge_attrs,
};

/* Initialize fast charge sysfs folder */
static struct kobject *force_fast_charge_kobj;

int force_fast_charge_init(void)
{
	int force_fast_charge_retval;

	 /* Forced fast charge disabled by default */
	force_fast_charge = FAST_CHARGE_DISABLED;

	force_fast_charge_kobj
		= kobject_create_and_add("fast_charge", kernel_kobj);

	if (!force_fast_charge_kobj) {
		return -ENOMEM;
	}

	force_fast_charge_retval
		= sysfs_create_group(force_fast_charge_kobj,
				&force_fast_charge_attr_group);

	if (force_fast_charge_retval)
		kobject_put(force_fast_charge_kobj);

	if (force_fast_charge_retval)
		kobject_put(force_fast_charge_kobj);

	return (force_fast_charge_retval);
}

void force_fast_charge_exit(void)
{
	kobject_put(force_fast_charge_kobj);
}

module_init(force_fast_charge_init);
module_exit(force_fast_charge_exit);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Jean-Pierre Rasquin <yank555.lu@gmail.com>");
MODULE_AUTHOR("Paul Reioux <reioux@gmail.com>");
MODULE_DESCRIPTION("Fast Charge Hack for Android");

