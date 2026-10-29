SKIPUNZIP=1
ui_print "Granting Magisk superuser to ADB shell (uid 2000)"
/debug_ramdisk/magisk --sqlite "INSERT OR REPLACE INTO policies (uid,policy,until,logging,notification) VALUES (2000,2,0,1,1);" || abort "Unable to update Magisk policy"
/debug_ramdisk/magisk --sqlite "SELECT uid,policy,until FROM policies WHERE uid=2000;" || abort "Unable to verify Magisk policy"
