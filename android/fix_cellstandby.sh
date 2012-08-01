#!/bin/sh
mkdir tmp
mkdir tmp/tools

# baksmali-1.3.2.jar
curl -O http://smali.googlecode.com/files/baksmali-1.3.2.jar
mv baksmali-1.3.2.jar tmp/tools
# smali-1.3.2.jar
curl -O http://smali.googlecode.com/files/smali-1.3.2.jar
mv smali-1.3.2.jar tmp/tools
# dexopt-wrapper
curl -L "http://forum.xda-developers.com/attachment.php?attachmentid=190382&d=1243739828"|funzip > dexopt-wrapper
mv dexopt-wrapper tmp/tools
# busybox
curl -O http://benno.id.au/android/busybox
mv busybox tmp/tools

adb pull /system/framework/framework.jar tmp/framework.jar
adb pull /system/framework/framework.odex tmp/framework.odex
adb pull /system/framework tmp/framework
java -Xmx512m -jar tmp/tools/baksmali-1.3.2.jar --api-level 14 -d tmp/framework -o tmp/lv14 -x tmp/framework.odex
cp tmp/lv14/com/android/internal/telephony/gsm/GsmServiceStateTracker.smali tmp/lv14/com/android/internal/telephony/gsm/GsmServiceStateTracker.smali.original
# 書き換え
echo "4203c4203
<         :pswitch_1c
---
>         :pswitch_1d
4213c4213
<         :pswitch_1c
---
>         :pswitch_1d"|patch tmp/lv14/com/android/internal/telephony/gsm/GsmServiceStateTracker.smali
java -Xmx512m -jar tmp/tools/smali-1.3.2.jar --api-level 14 -o tmp/classes.dex tmp/lv14
cd tmp
7za u -tzip framework.jar classes.dex
cd ..


adb push tmp/framework.jar /data/local/tmp/
adb push tmp/tools/dexopt-wrapper /data/local/tmp/
adb push tmp/tools/busybox /data/local/tmp/
adb shell chmod 755 /data/local/tmp/dexopt-wrapper
adb shell chmod 755 /data/local/tmp/busybox
adb shell "cd /data/local/tmp && ./dexopt-wrapper framework.jar framework.odex"
adb shell "cd /data/local/tmp && ./busybox dd if=/system/framework/framework.odex of=./framework.odex bs=1 count=20 skip=52 seek=52 conv=notrunc"

echo "boot recovery mode(ex:recovery-clockwork). on boot finished, mount /system and /data."
echo "execute command..."
echo " $ adb shell \"cp /data/local/tmp/framework.odex /system/framework/framework.odex.new && mv /system/framework/framework.odex /system/framework/framework.odex.original && mv /system/framework/framework.odex.new /system/framework/framework.odex && sync && reboot\""
