/****************************************************
 * defines accessable from HTML and C/C++, they have to be defined here for easier access and to have it defined only once!
 *
 * This file will be scanned and all entries in HTML files will be replaced
 *
 * There are several reasons for this:
 * - they could be stored in NVS with much shorter names to save space what makes them not as clear inside HTML code as they should be
 * - they could be renamed for any refactoring reasons
 * - we could have global naming conflicts
 *
 * You have different possibilities to use it in your code:
 * 1) provide a string array matching the enums, what is useful to get data into and out of NVS memory (see e.g. ESP32)
 * 2) create a switch/case to decide how to handle the HTTP requests
 * 3) or even a combination of them, e.g. all values up to 100 will be taken from NVS or written to it, all higher values will be handled individually
 *
 * Please note:
 * - Never use magic numbers somewhere, always use these enums, so you will never have problems!
 * - This is just a dummy file, either create your own one or copy it over into your project folder
 ****************************************************/



#ifndef HTML_ENUMS_H
#define HTML_ENUMS_H



/* Do not mess with that enum, e.g. by giving integers behind the enum values or so,
 * all you should do here is to define the new names you need or remove not needed ones, even rearranging is OK!
 *
 * These enums here will not cost you any flash at all, not in your C code and not in your HTML code,
 * so don't try to save same space by giving only short and unreadable defines!
 *
 * You can insert line comments here but do not add any block comments otherwise html2gzipc.py will fail!
 * If you want an alias for any of the entries define it inside another enum afterwards or somewhere else!
 */
enum {
    // read from and written to NVS
    __ACCESS_POINT_ALWAYS_ON__,
    __ACCESS_POINT_ENABLED__,
    __ACCESS_POINT_IP__,
    __ACCESS_POINT_MAC__,
    __ACCESS_POINT_SUBNET__,
    __ACCESS_POINT_SSID__,

    __SYSTEM_DISPLAY_TIMEOUT__,

    __WIFI_DHCP__,
    __WIFI_ENABLED__,
    __WIFI_MANUAL_GATEWAY__,
    __WIFI_MANUAL_IP__,
    __WIFI_MANUAL_SUBNET__,
    __WIFI_PASSPHRASE__,
    __WIFI_TX_POWER__,
    __WIFI_SSID__,
    __WIFI_SUBNET__,

    // included in NVS but need to be checked from code first (e.g. optional values, values that are "contained" in HW but can be overwritten, ...)
    __WIFI_MAC__,

    // handled by any code pieces
    __SYSTEM_CPU_CORE__,
    __SYSTEM_DATE__,
    __SYSTEM_FLASH_SIZE__,
    __SYSTEM_FLASH_USED__,
    __SYSTEM_HEAP_FREE__,
    __SYSTEM_HEAP_NEVER_USED__,
    __SYSTEM_RAM_SIZE__,
    __SYSTEM_TIME__,
    __SYSTEM_VERSION__,
    __SYSTEM_REBOOT__,

    __ACCESS_POINT_CONNECTED_STATIONS__,

    __WIFI_AVAILABLE_SSIDS__,
    __WIFI_GATEWAY__,
    __WIFI_HOSTNAME__,
    __WIFI_IP__,
    __WIFI_STRENGTH__,
    __WIFI_RECONNECT__,
};



#endif


