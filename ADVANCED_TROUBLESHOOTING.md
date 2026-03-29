# 🔧 ADVANCED BUILD TROUBLESHOOTING GUIDE

## Problem Identification Matrix

### ERROR 1: "The system cannot find the path specified"

**Root Cause:** Flutter not in system PATH or downloaded incorrectly

**Solutions:**

**Solution 1A - Check Flutter Exists (5 minutes)**
```
1. Open Command Prompt (cmd)
2. Type: C:\flutter\bin\flutter --version
3. Press Enter
4. Should show: Flutter version X.X.X
```

**If not found:**
```
1. Go to: C:\flutter\bin
2. Should exist (if not, download failed)
3. If missing, rerun FULL_AUTO_BUILD.bat
4. Let it complete fully this time
```

**Solution 1B - Manual Flutter Setup (10 minutes)**
```
1. Download: https://flutter.dev/docs/get-started/install/windows
2. Extract to: C:\flutter
3. Add to PATH:
   a. Windows + R → sysdm.cpl
   b. Advanced → Environment Variables
   c. System variables → PATH → Edit
   d. Add: C:\flutter\bin
   e. Add: C:\flutter\bin\cache\dart-sdk\bin
   f. OK
4. Restart Command Prompt
5. Run: FULL_AUTO_BUILD.bat again
```

**Solution 1C - Permission Issue (5 minutes)**
```
1. Right-click FULL_AUTO_BUILD.bat
2. Select "Run as administrator"
3. Click "Yes" when prompted
4. Build should proceed
```

---

### ERROR 2: "PowerShell is not recognized"

**Root Cause:** PowerShell not in PATH or disabled

**Solutions:**

**Solution 2A - Re-enable PowerShell (5 minutes)**
```
1. Open Command Prompt as Administrator
2. Type: powershell -File download_flutter.ps1
3. If it works, your setup is fine
4. Rerun: FULL_AUTO_BUILD.bat
```

**Solution 2B - Manual Download (15 minutes)**
```
1. Open: https://storage.googleapis.com/flutter_infra_release/windows/flutter_windows_3.x.x-stable.zip
   (Replace 3.x.x with latest version)
2. Save to: C:\flutter_sdk.zip
3. Extract: Right-click → Extract All → C:\
4. Rename: flutter_sdk → flutter
5. Run: FULL_AUTO_BUILD.bat
```

---

### ERROR 3: "Not enough disk space"

**Root Cause:** < 10 GB free space needed

**Solutions:**

**Quick Check:**
```
1. Open File Explorer
2. Right-click C:\ drive
3. Look at "Free space"
4. Need minimum: 10 GB
```

**If Space Is Low:**
```
1. Delete temporary files:
   Temp folder: C:\Users\bheda\AppData\Local\Temp
   Delete everything safely
   
2. Clean Windows cache:
   Settings → System → Storage → Temporary files → Remove
   
3. Uninstall unused programs:
   Settings → Apps → Apps & features
   
4. Delete old builds (if any):
   site_surveyor_compass\build → Delete
   
5. After cleanup, rerun: FULL_AUTO_BUILD.bat
```

---

### ERROR 4: "Internet connection lost"

**Root Cause:** Download interrupted during SDK transfer

**Solutions:**

**Solution 4A - Resume Download (Automatic)**
```
1. Check internet connection
2. Rerun: FULL_AUTO_BUILD.bat
3. Script will check if Flutter exists
4. If partial, may retry from where it stopped
```

**Solution 4B - Manual Resume**
```
1. Make sure Internet is stable
2. Rerun: FULL_AUTO_BUILD.bat
3. Select "Retry" if prompted
4. Wait 30+ minutes for completion
```

**Solution 4C - Use Wired Internet**
```
1. If WiFi is unstable, use Ethernet cable
2. Connects more reliably
3. Rerun: FULL_AUTO_BUILD.bat
```

---

### ERROR 5: "APK build failed with Gradle error"

**Root Cause:** Java/Android SDK version conflict or missing dependencies

**Solutions:**

**Solution 5A - Clean Rebuild (10 minutes)**
```
1. Open Command Prompt
2. Navigate: cd C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass
3. Run: flutter clean
4. Run: FULL_AUTO_BUILD.bat again
5. This removes all cached builds and rebuilds fresh
```

**Solution 5B - Update Android SDK (15 minutes)**
```
1. Open: C:\Users\bheda\AppData\Local\Android\sdk\cmdline-tools\latest\bin
2. Run: sdkmanager.bat --list
3. Should show available tools
4. If errors, download Android Studio:
   https://developer.android.com/studio
5. Run Android Studio → Tools → SDK Manager → Install missing tools
6. Rerun: FULL_AUTO_BUILD.bat
```

**Solution 5C - Check Java Version (5 minutes)**
```
1. Open Command Prompt
2. Run: java -version
3. Should show version 8 or higher
4. If not, download:
   https://www.oracle.com/java/technologies/downloads/
5. Install Java JDK
6. Rerun: FULL_AUTO_BUILD.bat
```

---

### ERROR 6: "Build successful but APK not found"

**Root Cause:** APK generated in wrong location or build partially failed

**Solutions:**

**Solution 6A - Search for APK (5 minutes)**
```
1. File Explorer → Search (Windows + F)
2. Type: app-release.apk
3. Search in: C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass\
4. Should find it in: build\app\outputs\flutter-apk\
5. If found, copy to Desktop for backup
6. If not found, try Solution 6B
```

**Solution 6B - Check Build Output (5 minutes)**
```
1. Open: C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass\build\
2. Explore subfolders:
   - app\outputs\flutter-apk\ (APK should be here)
   - app\outputs\bundle\ (or here if problem)
   - app\intermediates\ (build artifacts)
3. If you find .apk anywhere, that's your APK
4. If nothing found, rebuild with: flutter clean && flutter build apk --release
```

---

## Advanced Debugging

### View Full Build Logs

```
1. During build, copy all text from window
2. Save to: build_log.txt
3. Share with support if needed
```

### Enable Verbose Output

```
1. Open Command Prompt
2. cd site_surveyor_compass
3. Run: flutter build apk --release -v
4. Shows detailed build steps
5. Error messages will be more detailed
```

### Check Flutter Configuration

```
1. Command Prompt
2. Run: flutter doctor -v
3. Shows all tools, versions, and problems
4. Read output carefully - errors listed clearly
5. Follow Flutter's suggested fixes
```

---

## Performance Optimization

### If Build Is Very Slow (Faster Next Time)

**Slow First Build (Normal):** 40-60 minutes
**Slow Second Build (Abnormal):** 20-40 minutes

**If second build is slow:**
```
1. Disk I/O might be slow
2. Run: flutter clean
3. Run: FULL_AUTO_BUILD.bat
4. Next time should be faster
```

**If cache is bloated:**
```
1. Run: flutter cache repair
2. Waits for healing
3. Then rebuild: FULL_AUTO_BUILD.bat
```

---

## Testing APK Validity

### Check APK Is Actually Built

```
1. Command Prompt
2. cd C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass\build\app\outputs\flutter-apk
3. Run: dir
4. Should show: app-release.apk (not showing = build failed)
5. Check size: > 20 MB
```

### Verify APK Signature

```
1. Command Prompt
2. Navigate to: C:\Program Files\Android\android-sdk\build-tools\<latest>\
3. Run: zipalign -v 4 app-release.apk app-release-aligned.apk
4. Then: apksigner verify app-release-aligned.apk
5. Should show: "Verified"
```

---

## When All Else Fails

### Complete Reset (Nuclear Option)

```
1. Delete: C:\flutter
2. Delete: C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass\build
3. Delete: C:\Users\bheda\.gradle
4. Delete: C:\Users\bheda\.android
5. Empty Recycle Bin
6. Restart computer
7. Run: FULL_AUTO_BUILD.bat (completely fresh start)
```

### Reinstall Everything

```
1. Uninstall Android Studio
2. Delete: C:\Program Files\Android
3. Delete: C:\Users\bheda\AppData\Local\Android
4. Delete: C:\Users\bheda\.android
5. Reinstall from: https://developer.android.com/studio
6. Run: FULL_AUTO_BUILD.bat
```

---

## Getting Help

### If Still Stuck After Trying All Solutions:

**Provide This Information:**
```
1. Screenshot of error message
2. Full build log (copy window text)
3. System info:
   - Windows version
   - Disk space available
   - Internet connection (Mbps)
   - Antivirus program (if any)
   
4. What you already tried:
   - Solutions from this guide
   - Results of each attempt
```

**Common Questions:**

Q: "How long should build really take?"
A: First build 40-60 min, second build 15-20 min (normal)

Q: "Why so slow?"
A: Flutter SDK is 2.5 GB, first download is always slow

Q: "Can I speed it up?"
A: Use wired internet, close other apps, don't interrupt

Q: "What if interrupted?"
A: Flutter usually resumes from cache, just rerun script

---

**Last Updated:** March 29, 2026
**Status:** Ready for troubleshooting 🔧

