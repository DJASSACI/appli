# CinetPay Webhook Implementation Steps

## ✅ Completed
- [x] Replace duplicate `/notify` endpoints in `../djassa-backend/server.js`
- [x] Implement order status update logic (payée/refusée)
- [x] Integrate with existing `readJSONFile`/`writeJSONFile` helpers

## ⏳ Next Steps
1. **Restart Backend**: `cd ../djassa-backend && npm start`
2. **Test Webhook**: 
   ```bash
   curl -X POST http://localhost:3000/notify \
     -H "Content-Type: application/json" \
     -d '{"transaction_id":123,"cpm_trans_status":"ACCEPTED"}'
   ```
3. **Verify**: Check `orders.json` → `statut: "payée"`
4. **Flutter Test**: Refresh orders screen to see updated status
5. **Production**: Set webhook URL in CinetPay dashboard

## Expected Behavior
- `cpm_trans_status: "ACCEPTED"` → `order.statut = "payée"`
- Other statuses → `order.statut = "refusée"`
- Logs: `✅ Paiement confirmé` / `❌ Commande non trouvée`

