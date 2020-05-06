<?php

class Constants
{
    private const HOME_DIR = '/home/modbros';
    private const BASE_PATH = '/home/modbros/ModbrosMonitoring/web';

    public const VERSION_FILE = self::BASE_PATH . '/data/version';
    public const DISCOVERY_FILE = self::BASE_PATH . '/data/discovery';
    public const SSID_FILE = self::BASE_PATH . '/data/ssids';
    public const WIFI_FILE = self::BASE_PATH . '/data/wifi';
    public const DRIVER_FILE = self::BASE_PATH . '/data/driver';

    public const LOG_DIR = self::BASE_PATH . '/log/log';
    public const DRIVER_GOODTFT_DIR = self::HOME_DIR . '/GoodTFT-Drivers';
    public const DRIVER_WAVESHARE_DIR = self::HOME_DIR . '/Waveshare-Drivers';
}
