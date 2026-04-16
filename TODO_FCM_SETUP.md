# FCM Setup Progress

- [x] Create this TODO file
- [x] Edit functions/package.json to add node-fetch@^2.7.0
- [x] Install dependencies (npm install in functions/)
- [x] Edit functions/index.js to add fetch require and FCM_SERVER_KEY via functions.config()
- [x] Test/deploy instructions provided

**Next**: 
- cd functions && npm install (if not auto-installed)
- firebase functions:config:set fcm.server_key="your_fcm_v1_key_from_firebase_console"
- firebase deploy --only functions
