# 🔧 BUILD TROUBLESHOOTING GUIDE

## मुझे APK build नहीं हो रहा! क्या करूँ?

अगर build script में error आ रहा है, तो यह guide follow करो।

---

## ❌ ERROR 1: "Flutter not found" / "command not recognized"

### समस्या:
```
'flutter' is not recognized as an internal or external command
```

### समाधान:

**Option A: Use FULL_AUTO_BUILD.bat (Recommended)**
```
- FULL_AUTO_BUILD.bat को use करो
- यह automatically Flutter download करेगा
- कोई setup नहीं!
```

**Option B: Manual Flutter Install**
```
1. Go to: https://flutter.dev/docs/get-started/install/windows
2. Download Flutter SDK for Windows
3. Extract to: C:\flutter
4. Add C:\flutter\bin to PATH environment variable
5. Restart Command Prompt
6. Try again
```

**How to add to PATH:**
```
1. Windows Key + X
2. System (Environment Variables)
3. Edit environment variables
4. Find PATH
5. Add: C:\flutter\bin
6. Click OK
7. Restart computer
```

---

## ❌ ERROR 2: "The system cannot find the path specified"

### समस्या:
```
The system cannot find the path specified.
```

### समाधान:

**Step 1: Check Script Location**
```
Make sure you're running the script from the correct folder:
C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass
```

**Step 2: Use Absolute Path**
```
Right-click FULL_AUTO_BUILD.bat → Properties
Check if it shows the correct path
```

**Step 3: Try Different Script**
```
अगर FULL_AUTO_BUILD.bat काम नहीं कर रहा, तो:
1. Command Prompt खोलो
2. cd "C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass"
3. flutter pub get
4. flutter build apk --release
```

---

## ❌ ERROR 3: PowerShell Issues / Download Failed

### समस्या:
```
'$' is not recognized as an internal or external command
या
Invoke-WebRequest : Could not create SSL/TLS secure channel
```

### समाधान:

**Step 1: Download Flutter Manually**
```
1. Go to: https://flutter.dev/docs/get-started/install/windows
2. Click "Download for Windows"
3. Download the ZIP file
4. Extract to: C:\flutter
5. Run: FULL_AUTO_BUILD.bat again
```

**Step 2: Enable PowerShell ExecutionPolicy**
```
1. Open PowerShell as Administrator
2. Run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
3. Type: Y (Yes)
4. Try the script again
```

---

## ❌ ERROR 4: "APK build failed" / Compilation Error

### समस्या:
```
❌ APK build failed
```

### समाधान:

**Check 1: Disk Space**
```
1. Right-click C: drive
2. Properties
3. Check free space: Should be at least 10 GB
```

**Check 2: Internet Connection**
```
1. Make sure WiFi or mobile data is ON
2. Check speed: at least 1 Mbps recommended
3. Try running the script again
```

**Check 3: Java Installation**
```
1. Open Command Prompt
2. Type: java -version
3. If not recognized, install JDK:
   - Download from: https://www.oracle.com/java/technologies/downloads/
   - Install: Java SE Development Kit 11 (or higher)
   - Restart computer
```

**Check 4: Android SDK**
```
1. Make sure Android SDK is installed
2. Usually at: C:\Users\USERNAME\AppData\Local\Android\sdk
3. If not found, use FULL_AUTO_BUILD.bat (which installs it)
```

---

## ❌ ERROR 5: "Cannot find build/app/outputs/flutter-apk/app-release.apk"

### समस्या:
```
APK file नहीं मिल रहा build के बाद
```

### समाधान:

**Check 1: Build Actually Completed**
```
अगर build script में ✅ BUILD SUCCESSFUL! message नहीं दिया:
- Build पूरा नहीं हुआ
- Errors ठीक करो और फिर से try करो
```

**Check 2: Look in Right Location**
```
APK का location:
C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass\build\app\outputs\flutter-apk\app-release.apk

या File Explorer से:
1. Windows Key + E
2. Paste: C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass\build\app\outputs\flutter-apk
3. Enter
```

**Check 3: Search for It**
```
Windows Explorer में:
1. आपके project folder में जाओ
2. Search: "app-release.apk"
3. ढूंढ लो!
```

---

## ⚠️ ERROR 6: Gradle Build Errors

### समस्या:
```
FAILURE: Build failed with an exception
```

### समाधान:

**Step 1: Clean Build**
```
1. Open Command Prompt
2. cd "C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass"
3. flutter clean
4. flutter pub get
5. flutter build apk --release
```

**Step 2: Update Flutter**
```
1. flutter upgrade
2. flutter pub get
3. flutter build apk --release
```

---

## 🎯 QUICK CHECKLIST

अगर कोई भी problem हो तो यह check करो:

- [ ] Internet connection working?
- [ ] At least 10 GB free disk space?
- [ ] Running with Administrator rights?
- [ ] Correct folder location?
- [ ] Java installed (java -version)?
- [ ] Flutter downloaded (या FULL_AUTO_BUILD.bat use किया)?
- [ ] Full build script output को पढ़ा?

---

## 🆘 STILL HAVING ISSUES?

अगर problem solve नहीं हुआ:

### Option 1: Start Fresh
```
1. Delete the build folder:
   C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass\build

2. Run again:
   FULL_AUTO_BUILD.bat
```

### Option 2: Manual Build
```
1. Install Flutter manually from https://flutter.dev
2. Open Command Prompt
3. cd "C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass"
4. flutter pub get
5. flutter build apk --release
```

### Option 3: Use Different Script
```
Try different build scripts:
- BUILD_APK.bat
- QUICK_START.bat
- BUILD_AND_INSTALL.bat
```

---

## 📱 ALTERNATIVE: Web Build (For Testing)

अगर Android build नहीं हो रहा, test के लिए web में run कर सकते हो:

```
1. Command Prompt खोलो
2. cd "C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass"
3. flutter run -d chrome

यह browser में app को run करेगा (सभी features नहीं, पर देख सकते हो)
```

---

## ✅ SUCCESS CHECKLIST

Build successful होने के बाद:

- [ ] APK file मिल गई?
- [ ] File size 20-30 MB है?
- [ ] Location: build\app\outputs\flutter-apk\app-release.apk
- [ ] File name: app-release.apk
- [ ] Status: Ready to use ✅

---

## 🚀 NEXT STEPS (After Successful Build)

```
1. APK को phone में install करो
2. App test करो
3. Problems दिखे तो उन्हें fix करो
4. Production के लिए ready!
```

---

**Still stuck? Try FULL_AUTO_BUILD.bat - it handles everything automatically!** 🤖

