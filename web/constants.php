<?php

class Constants
{
    private const TMP_DIR = '/tmp';
    private const HOME_DIR = '/home/modbros';
    private const BASE_PATH = '/home/modbros/mobro-raspberrypi';

    public const FILE_SSID = self::TMP_DIR . '/mobro_ssids';
    public const FILE_VERSION = self::BASE_PATH . '/config/version';
    public const FILE_MOBRO_CONFIG_READ = self::BASE_PATH . '/config/mobro_config';
    public const FILE_MOBRO_CONFIG_WRITE = self::TMP_DIR . '/mobro_config';
    public const FILE_TIMEZONES = self::BASE_PATH . '/web/resources/timezones.txt';
    public const FILE_REST_API = self::BASE_PATH . '/web/resources/rest_api_doc.txt';
    public const FILE_LOG = self::TMP_DIR . '/mobro_log';
    public const FILE_CONFIGTXT = '/boot/config.txt';
    public const FILE_MOBRO_CONFIGTXT_READ = self::BASE_PATH . '/config/mobro_configtxt';
    public const FILE_MOBRO_CONFIGTXT_WRITE = self::TMP_DIR . '/mobro_configtxt';

    public const DIR_DRIVER_GOODTFT = self::HOME_DIR . '/display-drivers/GoodTFT';
    public const DIR_DRIVER_WAVESHARE = self::HOME_DIR . '/display-drivers/Waveshare';

    public const SCRIPT_APPLY_CONFIG = self::BASE_PATH . '/scripts/apply_new_config.sh';
    public const SCRIPT_SHUTDOWN = self::BASE_PATH . '/scripts/shutdown.sh';
    public const SCRIPT_SERVICE = self::BASE_PATH . '/scripts/service.sh';
    public const SCRIPT_SYSLOG = self::BASE_PATH . '/scripts/syslog.sh';
    public const SCRIPT_CPU_STATS = self::BASE_PATH . '/scripts/cpu_stats.sh';
    public const SCRIPT_MEMORY_STATS = self::BASE_PATH . '/scripts/memory_stats.sh';
    public const SCRIPT_FILESYSTEM_STATS = self::BASE_PATH . '/scripts/fs_stats.sh';
    public const SCRIPT_WIFI_STATS = self::BASE_PATH . '/scripts/wifi_stats.sh';
}
