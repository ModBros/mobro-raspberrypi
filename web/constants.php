<?php

class Constants
{
    private const HOME_DIR = '/home/modbros';
    private const BASE_PATH = '/home/modbros/ModbrosMonitoring';

    public const FILE_VERSION = self::BASE_PATH . '/data/version';
    public const FILE_DISCOVERY = self::BASE_PATH . '/data/discovery';
    public const FILE_SSID = self::BASE_PATH . '/data/ssids';
    public const FILE_WIFI = self::BASE_PATH . '/data/wifi';
    public const FILE_DRIVER = self::BASE_PATH . '/data/driver';

    public const DIR_LOG = self::BASE_PATH . '/log';
    public const DIR_DRIVER_GOODTFT = self::HOME_DIR . '/DisplayDrivers/GoodTFT';
    public const DIR_DRIVER_WAVESHARE = self::HOME_DIR . '/DisplayDrivers/Waveshare';

    public const SCRIPT_APPLY_CONFIG = self::BASE_PATH . '/scripts/apply_new_config.sh';
    public const SCRIPT_SHUTDOWN = self::BASE_PATH . '/scripts/shutdown.sh';
}
