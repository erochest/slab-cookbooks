<?php
/**
 * @version $Id$
 * @copyright Center for History and New Media, 2009
 * @license http://www.gnu.org/licenses/gpl-3.0.txt
 * @package Omeka
 * @access private
 **/

/**
 * @internal This implements Omeka internals and is not part of the public API.
 * @access private
 * @package Omeka
 * @copyright Center for History and New Media, 2009
 **/
class Installer_Requirements
{
    const OMEKA_PHP_VERSION = '5.2.4';
    const OMEKA_MYSQL_VERSION = '5.0';
    
    private $_dbAdapter;
    
    private $_errorMessages = array();
    private $_warningMessages = array();
    
    public function check()
    {
        $this->_checkPhpVersionIsValid();
        $this->_checkMysqliIsAvailable();
        $this->_checkMysqlVersionIsValid();
        $this->_checkHtaccessFilesExist();
        $this->_checkRegisterGlobalsIsOff();
        $this->_checkExifModuleIsLoaded();
        // $this->_checkModRewriteIsEnabled();
        $this->_checkArchiveDirectoriesAreWritable();
    }
    
    public function getErrorMessages()
    {
        return $this->_errorMessages;
    }
    
    public function getWarningMessages()
    {
        return $this->_warningMessages;
    }
    
    public function hasError()
    {
        return (boolean)count($this->getErrorMessages());
    }

    public function hasWarning()
    {
        return (boolean)count($this->getWarningMessages());
    }
    
    public function setDbAdapter(Zend_Db_Adapter_Abstract $db)
    {
        $this->_dbAdapter = $db;
    }
    
    private function _checkPhpVersionIsValid()
    {
        if (version_compare(PHP_VERSION, self::OMEKA_PHP_VERSION, '<')) {
            $header = 'Incorrect version of PHP';
            $message = "Omeka requires PHP " . self::OMEKA_PHP_VERSION . " or 
            greater to be installed. PHP " . PHP_VERSION . " is currently 
            installed. <a href=\"http://www.php.net/manual/en/migration5.php\">Instructions 
            for upgrading</a> are on the PHP website.";
            $this->_errorMessages[] = compact('header', 'message');
        }
    }
    
    private function _checkMysqliIsAvailable()
    {
        if (!function_exists('mysqli_get_server_info')) {
            $header = 'Mysqli extension is not available';
            $message = "The mysqli PHP extension is required for Omeka to run. 
            Please check with your server administrator to <a href=\"http://www.php.net/manual/en/mysqli.installation.php\">enable 
            this extension</a> and then try again.";
            $this->_errorMessages[] = compact('header', 'message');
        }
    }
    
    private function _checkMysqlVersionIsValid()
    {
        $mysqlVersion = $this->_dbAdapter->getServerVersion();
        if (version_compare($mysqlVersion, self::OMEKA_MYSQL_VERSION, '<')) {
            $header = 'Incorrect version of MySQL';
            $message = "Omeka requires MySQL " . self::OMEKA_MYSQL_VERSION . " 
            or greater to be installed. MySQL $mysqlVersion is currently 
            installed. <a href=\"http://dev.mysql.com/doc/refman/5.0/en/upgrade.html\">Instructions 
            for upgrading</a> are on the MySQL website.";
            $this->_errorMessages[] = compact('header', 'message');
        }
    }
    
    private function _checkHtaccessFilesExist()
    {
        if (!file_exists(BASE_DIR . DIRECTORY_SEPARATOR . '.htaccess')) {
            $header = 'Missing .htaccess File';
            $message = "Omeka's .htaccess file is missing. Please make sure this 
            file has been uploaded correctly and try again.";
            $this->_errorMessages[] = compact('header', 'message');
        }
        
        if (!file_exists(ADMIN_DIR . DIRECTORY_SEPARATOR . '.htaccess')) {
            $header = 'Missing admin/.htaccess File';
            $message = "Omeka's admin/.htaccess file is missing. Please make 
            sure this file has been uploaded correctly and try again.";
            $this->_errorMessages[] = compact('header', 'message');
        }
    }
    
    private function _checkRegisterGlobalsIsOff()
    {
        if (ini_get('register_globals')) {
            $header = '"register_globals" is enabled';
            $message = "Having PHP's <a href=\"http://www.php.net/manual/en/security.globals.php\">register_globals</a> 
            setting enabled represents a security risk to your Omeka 
            installation. Also, having this setting enabled might indicate that 
            Omeka's .htaccess file is not being properly parsed by Apache, which 
            can cause any number of strange errors. It is recommended (but not 
            required) that you disable register_globals for your Omeka 
            installation.";
            $this->_warningMessages[] = compact('header', 'message');
        }
    }
    
    private function _checkExifModuleIsLoaded()
    {
        if (!extension_loaded('exif')) {
            $header = '"exif" module not loaded';
            $message = "Without the <a href=\"http://www.php.net/manual/en/book.exif.php\">exif 
            module</a> loaded into PHP, Exif data cannot be automatically 
            extracted from uploaded images.";
            $this->_warningMessages[] = compact('header', 'message');
        }
    }
    
    private function _checkModRewriteIsEnabled()
    {
        $modRewriteUrl = WEB_ROOT . '/check-mod-rewrite.html';
        
        // Set the http timeout to 5 to prevent recursion, which leads to a 
        // MySQL "too many connections" error. This assumes Apache needs only 5 
        // second to rewrite the URL.
        $context = stream_context_create(array('http' => array('timeout' => 5))); 
        
        // If we can't use the http wrapper for file_get_contents(), warn that 
        // we were unable to check for mod_rewrite.
        if (!ini_get('allow_url_fopen')) {
            $header = 'Unable to check for mod_rewrite';
            $message = "Unable to verify that <a href=\"http://httpd.apache.org/docs/1.3/mod/mod_rewrite.html\">mod_rewrite</a> 
            is enabled on your server. mod_rewrite is an Apache extension that 
            is required for Omeka to work properly. Omeka is unable to check 
            because your php.ini <a href=\"http://us2.php.net/manual/en/filesystem.configuration.php#ini.allow-url-fopen\">allow_url_fopen</a> 
            setting has been disabled. You can manually verify that Omeka 
            mod_rewrite by checking to see that the following URL works in your 
            browser: <a href=\"$modRewriteUrl\">$modRewriteUrl</a>";
            $this->_warningMessages[] = compact('header', 'message');
        
        // We are trying to retrieve this URL.
        } else if (!$modRewrite = @file_get_contents($modRewriteUrl, false, $context)) {
            $header = 'mod_rewrite is not enabled';
            $message = "Apache's <a href=\"http://httpd.apache.org/docs/1.3/mod/mod_rewrite.html\">mod_rewrite</a> 
            extension must be enabled for Omeka to work properly. Please enable 
            mod_rewrite and try again.";
            $this->_errorMessages[] = compact('header', 'message');
        }
    }
    
    private function _checkArchiveDirectoriesAreWritable()
    {
        $archiveDirectories = array(ARCHIVE_DIR, FILES_DIR, FULLSIZE_DIR, 
                                    THUMBNAIL_DIR, SQUARE_THUMBNAIL_DIR);
        foreach ($archiveDirectories as $archiveDirectory) {
            if (!is_writable($archiveDirectory)) {
                $header = 'Archive directory not writable';
                $message = "The following directory must be writable by your web 
                server before installing Omeka: $archiveDirectory";
                $this->_errorMessages[] = compact('header', 'message');
            }
        }
    }
    
}
