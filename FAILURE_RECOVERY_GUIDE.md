# 🆘 FAILURE RECOVERY GUIDES - ALL SCENARIOS

Use this document when something goes wrong. Find your scenario and follow the solution.

---

## SCENARIO 1: Build Fails at [3/5] Dependencies (Again)

**Error message you see:**
```
❌ Failed to get dependencies
Because site_surveyor_compass depends on permission_handler...
```

**This should NOT happen (we fixed it!)**

### Recovery:

**Step 1: Delete cache completely**
```
cd "C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass"
rmdir /s /q build
rmdir /s /q .dart_tool
flutter clean
```

**Step 2: Verify fix is in place**
```
Open: pubspec.yaml
Look for: permission_handler: ^11.3.1
(Should say 11.3.1, NOT 11.4.0)
```

**Step 3: Rebuild**
```
FULL_AUTO_BUILD.bat
```

---

## SCENARIO 2: Build Fails with "Flutter not found"

**Error message:**
```
'flutter' is not recognized as an internal or external command
```

### Recovery:

**Option A: Manual Flutter Setup (Fastest)**
```
1. Go to: https://flutter.dev/docs/get-started/install/windows
2. Download Flutter SDK
3. Extract to: C:\flutter
4. Add to PATH:
   - Windows key → sysdm.cpl
   - Advanced → Environment Variables
   - Add: C:\flutter\bin
   - Add: C:\flutter\bin\cache\dart-sdk\bin
5. Restart Command Prompt
6. Try: FULL_AUTO_BUILD.bat again
```

**Option B: Rerun Script (Let it download again)**
```
1. Right-click: FULL_AUTO_BUILD.bat
2. Run as administrator
3. Let it download Flutter again
```

---

## SCENARIO 3: Build Stuck (No Progress 15+ Minutes)

**What you see:**
```
[3/5] Getting dependencies...
(and then nothing for 15+ minutes)
```

### Recovery:

**Step 1: Check if internet is working**
```
Open: https://google.com
Should load
If not: Fix internet, then retry build
```

**Step 2: Kill the build**
```
In Command Prompt: Press Ctrl+C
Or close the window
```

**Step 3: Clean and restart**
```
flutter clean
FULL_AUTO_BUILD.bat
```

---

## SCENARIO 4: Disk Space Error

**Error message:**
```
No space left on device
Insufficient storage
```

### Recovery:

**Step 1: Check disk space**
```
File Explorer → Right-click C: drive → Properties
Need minimum: 3 GB free
```

**Step 2: Free up space**
```
Delete: Temp files
- C:\Users\bheda\AppData\Local\Temp\
- Everything in folder can be deleted

Or:
- Delete unused programs
- Delete old downloads
- Empty Recycle Bin
```

**Step 3: Retry build**
```
flutter clean
FULL_AUTO_BUILD.bat
```

---

## SCENARIO 5: APK Build Fails (Gradle Error)

**Error message contains:**
```
FAILURE: Build failed
Gradle build failed
```

### Recovery:

**Step 1: Clean build**
```
flutter clean
```

**Step 2: Try again**
```
FULL_AUTO_BUILD.bat
```

**Step 3: If still fails, reset everything**
```
rmdir /s /q build
rmdir /s /q .dart_tool
flutter clean
flutter pub get
flutter build apk --release
```

---

## SCENARIO 6: APK File Not Found After "SUCCESS"

**Build said "BUILD SUCCESSFUL!" but APK is missing**

### Recovery:

**Step 1: Search for APK**
```
Windows key + F
Search: app-release.apk
Search in: C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass\
```

**Step 2: Check alternate locations**
```
Might be in:
- build\app\outputs\flutter-apk\
- build\app\outputs\bundle\
- build\app\intermediates\
```

**Step 3: If found**
```
Copy it to Desktop for backup
Use for installation
```

**Step 4: If NOT found anywhere**
```
Build says success but no APK = partial build
Solution:
1. flutter clean
2. rmdir /s /q build
3. FULL_AUTO_BUILD.bat (full rebuild)
```

---

## SCENARIO 7: APK Installation Fails (USB)

**Error:**
```
adb: command not found
adb install failed
Device not found
```

### Recovery:

**Step 1: Verify USB debugging enabled on phone**
```
Phone → Settings → About → Build Number (tap 7x)
Phone → Settings → Developer Options
USB Debugging: Must be ON
```

**Step 2: Check phone is connected**
```
Command Prompt:
adb devices

Should show your phone listed
If not: Reconnect USB cable
```

**Step 3: Try manual method instead**
```
1. Copy app-release.apk to phone storage via File Explorer
2. On phone: File Manager → tap APK
3. Install dialog appears
4. Tap INSTALL
```

---

## SCENARIO 8: App Crashes Immediately After Opening

**What happens:**
```
Tap app icon
App starts
Crashes instantly
```

### Recovery:

**Step 1: Grant permissions**
```
Phone → Settings → Apps → Site Surveyor Compass
Permissions: Turn ON
- Location
- Sensors
```

**Step 2: Clear app cache**
```
Phone → Settings → Apps → Site Surveyor Compass
Storage → Clear Cache
Restart app
```

**Step 3: Reinstall app**
```
Phone → Settings → Apps → Site Surveyor Compass
Uninstall
Reinstall APK
Grant all permissions when asked
```

---

## SCENARIO 9: Compass Doesn't Work

**Symptoms:**
```
Compass needle doesn't move
Stuck pointing one direction
```

### Recovery:

**Step 1: Restart app**
```
Close app completely
Reopen it
Test again
```

**Step 2: Run calibration**
```
Open app
Tap: Menu (≡)
Select: Calibrate
Follow on-screen guide (move phone in 8-shape)
Try compass again
```

**Step 3: Check sensors enabled**
```
Phone → Settings → Apps → Site Surveyor Compass
Permissions → Sensors: must be ON
```

---

## SCENARIO 10: GPS Doesn't Work

**Symptoms:**
```
GPS shows no coordinates
Stuck at 0, 0
```

### Recovery:

**Step 1: Go outdoors**
```
GPS needs clear sky view
Must be outside
Wait 30-60 seconds
```

**Step 2: Enable Location Services**
```
Phone → Settings → Location: must be ON
Change to: High accuracy mode
```

**Step 3: Check app permissions**
```
Phone → Settings → Apps → Site Surveyor Compass
Permissions → Location: must be ON
Try again
```

---

## SCENARIO 11: Level Doesn't Work

**Symptoms:**
```
Level app shows no bubble
Bubble doesn't move
```

### Recovery:

**Step 1: Check sensors**
```
Phone → Settings → Apps → Site Surveyor Compass
Permissions → Sensors: must be ON
```

**Step 2: Restart phone**
```
Power off
Wait 10 seconds
Power on
Open app again
```

**Step 3: Clear app cache**
```
Settings → Apps → Site Surveyor Compass
Storage → Clear Cache
Restart app
```

---

## SCENARIO 12: Can't Add Waypoints

**Symptoms:**
```
Tap "Add Waypoint"
Nothing happens
Or app crashes
```

### Recovery:

**Step 1: Enable Location Permission**
```
Phone → Settings → Apps → Site Surveyor Compass
Permissions → Location: must be ON
Specifically: "Allow only while using the app"
```

**Step 2: Try again**
```
Open app
Go outdoors (GPS needs to work)
Tap Add Waypoint
Should work now
```

**Step 3: Restart app**
```
Close completely
Reopen
Try adding waypoint
```

---

## SCENARIO 13: Can't Export Data

**Symptoms:**
```
Tap Export Waypoints
Nothing happens
Or error appears
```

### Recovery:

**Step 1: Enable Storage Permission**
```
Phone → Settings → Apps → Site Surveyor Compass
Permissions → Storage: must be ON
```

**Step 2: Try again**
```
Open app
Tap Menu (≡)
Select Export Waypoints
Should work
```

**Step 3: Check email app**
```
Might have sent to Email app instead
Check your email account
Look for: Site Surveyor Compass waypoints
```

---

## NUCLEAR OPTION: Complete Reset

**Use this if nothing else works:**

### On Computer:

**Step 1: Delete everything**
```
1. Delete: C:\flutter
2. Delete: C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass\build\
3. Delete: C:\Users\bheda\.gradle\
4. Delete: C:\Users\bheda\.android\
5. Empty: Recycle Bin
6. Restart computer
```

**Step 2: Rebuild from scratch**
```
1. Right-click: FULL_AUTO_BUILD.bat
2. Run as administrator
3. Wait 60 minutes (full download + build)
```

### On Phone:

**Step 1: Uninstall app**
```
Settings → Apps → Site Surveyor Compass → Uninstall
```

**Step 2: Reinstall**
```
When APK ready, install fresh
Grant all permissions
Test all features
```

---

## GETTING HELP

**Before asking for help, provide:**

1. **Exact error message** (screenshot it)
2. **What step you were on** (1-9)
3. **What you already tried**
4. **Output from `flutter doctor -v`** if build-related

**Then check:**
1. ADVANCED_TROUBLESHOOTING.md
2. BUILD_TROUBLESHOOTING.md
3. Contact support with info above

---

## DECISION TREE FOR YOUR SCENARIO

```
What happened?
│
├─ Build error (red text) → Find your error in scenarios 1-5
├─ APK file issues → See scenario 6
├─ Installation failed → See scenario 7
├─ App crashes on open → See scenario 8
├─ Feature doesn't work → See scenario 9-13
└─ Nothing above → Try "Nuclear Option" scenario
```

---

**Remember: Most issues have simple fixes. Just follow the scenario that matches your problem!** ✅

