# TODO Backend Commission Update

✅ **Step 1: Replace commission calculation** - ✅ DONE: Replaced subtotal/total calculation in `../djassa-backend/server.js` with new logic: added `sellerAmount = subtotal - commission` and set `total = subtotal`.

Remaining steps:
- ☐ Restart backend server: `cd ../djassa-backend && node server.js`
- ☐ Test order creation via app/API to verify new totals
- ☐ Optionally add `sellerAmount` to `newOrder` object and response for frontend use

