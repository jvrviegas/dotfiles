# macOS Configuration Guide for MacBook Pro M4

This guide explains all the settings in the `osx.sh` script, their applicability to the MacBook Pro M4, and the benefits of each configuration.

## Table of Contents
- [General UI/UX](#general-uiux)
- [SSD-Specific Tweaks](#ssd-specific-tweaks)
- [Input Devices](#input-devices)
- [Screen Settings](#screen-settings)
- [Finder](#finder)
- [Dock & Dashboard](#dock--dashboard)
- [Safari & WebKit](#safari--webkit)
- [System Applications](#system-applications)

---

## General UI/UX

### Interface Style
```bash
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Reduces eye strain, especially in low-light environments
- Better battery life on OLED external displays
- Modern, professional appearance

### Highlight Color
```bash
defaults write NSGlobalDomain AppleHighlightColor -string "1.000000 0.380392 0.533333"
```
**Applies to M4:** ✅ Yes  
**Recommended:** 🤷 Personal preference  
**Benefits:**
- Sets a custom pink/red highlight color
- Visual consistency across applications
- Personal customization

### Smart Quotes and Dashes
```bash
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes (especially for developers)  
**Benefits:**
- Prevents automatic conversion of straight quotes to curly quotes
- Essential for coding and technical writing
- Avoids formatting issues in code editors and terminals

---

## SSD-Specific Tweaks

### Disable Local Time Machine Snapshots
```bash
sudo tmutil disablelocal
```
**Applies to M4:** ✅ Yes  
**Recommended:** ⚠️ Consider carefully  
**Benefits:**
- Saves 10-20% of SSD space
- Reduces write operations, extending SSD lifespan
- Eliminates background snapshot creation

**Considerations:**
- Removes local backup protection
- Base M4 model (256GB/512GB) would benefit most from space savings
- Consider if you have external Time Machine backup

### Hibernation Optimization
```bash
sudo pmset -a hibernatemode 0
sudo rm /Private/var/vm/sleepimage
sudo touch /Private/var/vm/sleepimage
sudo chflags uchg /Private/var/vm/sleepimage
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Faster wake from sleep (no disk read required)
- Saves disk space equal to RAM amount (8GB/16GB/24GB)
- Reduces SSD wear from large write operations
- M4's efficient sleep states make hibernation less necessary

### Disable Sudden Motion Sensor
```bash
sudo pmset -a sms 0
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- SSDs don't need motion protection (no moving parts)
- Slight battery life improvement
- Eliminates unnecessary system overhead

---

## Input Devices

### Trackpad Optimization
```bash
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking 0
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Enables tap-to-click (faster, quieter interaction)
- Reduces finger fatigue during long sessions
- More responsive feel with Force Touch trackpad

### Bluetooth Audio Quality
```bash
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Improved audio quality with Bluetooth headphones
- Better utilization of Bluetooth 5.3 capabilities
- Noticeable improvement with high-quality audio equipment

### Keyboard Optimization
```bash
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 20
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes (especially for developers)  
**Benefits:**
- Enables true key repeat instead of accent character popup
- Extremely fast key repeat rate for efficient text editing
- Essential for Vim users and heavy terminal work
- Much more responsive cursor movement and deletion

### Automatic Period Substitution
```bash
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Prevents accidental periods when typing quickly
- Better for coding and technical writing
- Reduces typing interruptions

### Language and Regional Settings
```bash
defaults write NSGlobalDomain AppleLanguages -array "en" "nl"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true
systemsetup -settimezone "America/Fortaleza" > /dev/null
```
**Applies to M4:** ✅ Yes  
**Recommended:** 🤷 Based on location/preference  
**Benefits:**
- Consistent measurement units across applications
- Proper timezone for scheduling and notifications
- Bilingual interface support

---

## Screen Settings

### Security
```bash
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Immediate password requirement after sleep/screensaver
- Enhanced security for sensitive data
- Important for professional/work environments

### Screenshot Location
```bash
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Organized screenshot storage
- Keeps desktop clean
- Easier to find and manage screenshots

### HiDPI Display Support
```bash
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Enables more resolution options for external displays
- Better support for non-Apple monitors
- Improved display scaling options

---

## Finder

### View Options
```bash
defaults write com.apple.finder AppleShowAllFiles -bool false
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool false
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Shows status bar with file count and available space
- Hides hidden files by default (cleaner interface)
- Customized information display

### Network Performance
```bash
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Prevents .DS_Store file creation on network volumes
- Faster network file operations
- Reduces network storage clutter

### Icon Organization
```bash
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Automatic icon grid alignment on desktop
- Cleaner, more organized appearance
- Consistent icon positioning

### Security and Performance
```bash
defaults write com.apple.finder EmptyTrashSecurely -bool true
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true
chflags nohidden ~/Library
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Secure file deletion (important for sensitive data)
- Better network discovery (AirDrop over Ethernet)
- Access to Library folder for troubleshooting

---

## Dock & Dashboard

### Size and Behavior
```bash
defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-process-indicators -bool true
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Compact dock size saves screen space
- Windows minimize to app icon (cleaner dock)
- Visual indicators for running applications

### Performance
```bash
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock showhidden -bool true
defaults write com.apple.dock hide-mirror -bool true
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Spring loading for drag-and-drop operations
- Fixed Space order (more predictable)
- Visual feedback for hidden applications
- More transparent dock appearance

### Cleanup
```bash
find ~/Library/Application\ Support/Dock -name "*.db" -maxdepth 1 -delete
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Resets Launchpad to default layout
- Fixes potential Launchpad issues
- Clean start for app organization

---

## Safari & WebKit

### Performance and Privacy
```bash
defaults write com.apple.Safari HomePage -string "about:blank"
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
defaults write com.apple.Safari ShowFavoritesBar -bool false
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Faster Safari startup (blank homepage)
- Enhanced security (no auto-opening downloads)
- More screen space (hidden bookmarks bar)

### Developer Features
```bash
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes (for developers)  
**Benefits:**
- Access to developer tools and debug options
- Web Inspector for debugging
- Advanced Safari features for development

### Navigation
```bash
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Backspace key navigates to previous page
- Faster browsing navigation
- More intuitive keyboard shortcuts

---

## System Applications

### Activity Monitor
```bash
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor IconType -int 5
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Shows main window on launch
- CPU usage visualization in dock
- All processes visible by default
- Sorted by CPU usage for performance monitoring

### Terminal
```bash
defaults write com.apple.terminal StringEncodings -array 4
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- UTF-8 encoding for international character support
- Better compatibility with modern development tools
- Proper display of special characters

### Spotlight
```bash
killall mds > /dev/null 2>&1
sudo mdutil -i on / > /dev/null
sudo mdutil -E / > /dev/null
```
**Applies to M4:** ✅ Yes  
**Recommended:** ✅ Yes  
**Benefits:**
- Rebuilds search index for better performance
- Fixes potential search issues
- Optimizes Spotlight database

---

## MacBook Pro M4 Specific Recommendations

### Highly Recommended Settings:
1. **SSD optimizations** - Base models (256GB/512GB) benefit significantly from space savings
2. **Keyboard settings** - Essential for the excellent M4 keyboard experience
3. **Trackpad tap-to-click** - Maximizes the Force Touch trackpad capabilities
4. **Bluetooth audio quality** - Takes advantage of Bluetooth 5.3
5. **Security settings** - Important for protecting your investment

### Consider Carefully:
1. **Time Machine local snapshots** - Weigh space savings vs. backup protection
2. **Language/regional settings** - Adjust based on your location
3. **Safari developer tools** - Only if you do web development

### Performance Impact:
- **Minimal impact** on M4 performance - these are mostly interface preferences
- **Positive impact** on storage space and user experience
- **No negative impact** on M4's efficiency or battery life

### Storage Considerations for Base Models:
- Hibernation file removal saves 8-24GB (depending on RAM configuration)
- Time Machine snapshots can save 10-30GB
- Total space savings: 20-50GB on base storage configurations

## Application and Restart
After running the script, restart these applications for changes to take effect:
- Finder
- Dock
- Safari
- System UI Server
- Activity Monitor

Some changes require a full logout/restart to take effect completely.
