# ViewStereo
Tiny simple viewer for pre-transformed graphics on iOS.

# Instructions.
* Install Xcode.
* Preferences->Accounts, add iCloud accounts, ManageCertificates, add iOS Development.
* Create Xcode project and close.
* sudo gem install cocoapods (with cocoapods, so we must agree LICENSES before to use.)
* Edit Podfile (Thanks to marmelroy libraries, so we must agree LICENSES before to use (includes zlib)) as:
* * pod 'FileBrowser', git: 'https://github.com/marmelroy/FileBrowser', branch: 'master', submodules: true
* * pod 'Zip', git: 'https://github.com/marmelroy/Zip', branch: ‘master’, submodules: true
* Open xcworkspace, edit main swift file as this repository.
* Edit info.plist 'Application supports iTunes file sharing' to 'YES'
* Edit with Manage Schemes with Pods-... checked.
* Build
* Run with transferred files.
