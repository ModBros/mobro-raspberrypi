<?php

class Constants
{
    private const HOME_DIR = '/home/modbros';
    private const BASE_PATH = '/home/modbros/mobro-raspberrypi';

    public const FILE_VERSION = self::BASE_PATH . '/data/version';
    public const FILE_SSID = self::BASE_PATH . '/data/ssids';
    public const FILE_MOBRO_CONFIG = self::BASE_PATH . '/data/mobro_config';
    public const FILE_TIMEZONES = self::BASE_PATH . '/web/resources/timezones.txt';
    public const FILE_REST_API = self::BASE_PATH . '/web/resources/rest_api_doc.txt';

    public const DIR_LOG = self::BASE_PATH . '/log';
    public const DIR_DRIVER_GOODTFT = self::HOME_DIR . '/display-drivers/GoodTFT';
    public const DIR_DRIVER_WAVESHARE = self::HOME_DIR . '/display-drivers/Waveshare';

    public const SCRIPT_APPLY_CONFIG = self::BASE_PATH . '/scripts/apply_new_config.sh';
    public const SCRIPT_SHUTDOWN = self::BASE_PATH . '/scripts/shutdown.sh';
    public const SCRIPT_SERVICE = self::BASE_PATH . '/scripts/service.sh';
    public const SCRIPT_SYSLOG = self::BASE_PATH . '/scripts/syslog.sh';
    public const SCRIPT_CPU_STATS = self::BASE_PATH . '/scripts/cpu_stats.sh';
    public const SCRIPT_MEMORY_STATS = self::BASE_PATH . '/scripts/memory_stats.sh';
    public const SCRIPT_FILESYSTEM_STATS = self::BASE_PATH . '/scripts/fs_stats.sh';
}
