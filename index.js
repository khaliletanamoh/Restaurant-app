const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
// Keep this in the same region as your Firestore database.
setGlobalOptions({ region: 'europe-west1' });
const db = getFirestore();

const STATUS_TEXT = {
  accepted: 'Your order was accepted.',
  preparing: 'Your food is being prepared.',
  ready: 'Your order is ready!',
  outForDelivery: 'Your order is on its way.',
  completed: 'Order completed. Enjoy your meal!',
  cancelled: 'Your order was cancelled.',
};

// Day key in Addis Ababa time (UTC+3). Must match addisDateKey() in the Flutter app.
function addisDateKey(date = new Date()) {
  return new Date(date.getTime() + 3 * 3600 * 1000).toISOString().slice(0, 10);
}

async function notifyUser(uid, title, body, data = {}) {
  const snap = await db.doc(`users/${uid}`).get();
  const tokens = snap.get('fcmTokens') || [];
  if (!tokens.length) return;
  await getMessaging().sendEachForMulticast({ tokens, notification: { title, body }, data });
}

// 1) Re-price every new order from the menu. Never trust totals sent by the phone.
exports.onOrderCreated = onDocumentCreated('orders/{orderId}', async (event) => {
  const ref = event.data.ref;
  const order = event.data.data();

  const [settingsSnap, ...itemSnaps] = await Promise.all([
    db.doc('settings/restaurant').get(),
    ...order.items.map((l) => db.doc(`menuItems/${l.itemId}`).get()),
  ]);

  let subtotal = 0;
  const items = [];
  for (let i = 0; i < order.items.length; i++) {
    const line = order.items[i];
    const menuItem = itemSnaps[i];
    if (!menuItem.exists || !menuItem.get('isAvailable')) {
      await ref.update({
        status: 'cancelled',
        cancelReason: `${line.name} is not available right now.`,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }
    const unitPrice = menuItem.get('priceEtb');
    const qty = Math.max(1, Math.min(50, Math.floor(Number(line.qty) || 1)));
    subtotal += unitPrice * qty;
    items.push({ itemId: line.itemId, name: menuItem.get('name'), unitPrice, qty, note: line.note || '' });
  }

  const deliveryFee = order.type === 'delivery' ? settingsSnap.get('deliveryFeeEtb') ?? 0 : 0;
  const total = subtotal + deliveryFee;
  await ref.update({ items, subtotal, deliveryFee, total, updatedAt: FieldValue.serverTimestamp() });

  await getMessaging().send({
    topic: 'staff',
    notification: {
      title: 'New order',
      body: `${order.customerName || 'Customer'} \u00b7 ${total} ETB (${order.type})`,
    },
    data: { orderId: ref.id },
  });
});

// 2) Notify the customer on each status change. On completion: loyalty points and daily stats.
exports.onOrderUpdated = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return; // ignore our own total/points updates

  const orderId = event.params.orderId;
  const text = STATUS_TEXT[after.status];
  if (text) {
    const body = after.cancelReason ? `${text} ${after.cancelReason}` : text;
    await notifyUser(after.userId, 'Addis Delight', body, { orderId });
  }
  if (after.status !== 'completed') return;

  const settings = await db.doc('settings/restaurant').get();
  const etbPerPoint = settings.get('etbPerPoint') ?? 10;
  const points = Math.floor(after.total / etbPerPoint);

  const orderRef = event.data.after.ref;
  const userRef = db.doc(`users/${after.userId}`);
  const txRef = db.doc(`loyaltyTransactions/earn_${orderId}`);
  const statsRef = db.doc(`dailyStats/${addisDateKey()}`);

  // Transaction + deterministic id = safe if the function is retried (points awarded once).
  await db.runTransaction(async (tx) => {
    if ((await tx.get(txRef)).exists) return;
    const topItems = {};
    for (const l of after.items) {
      topItems[l.itemId] = { name: l.name, qty: FieldValue.increment(l.qty) };
    }
    tx.set(txRef, {
      userId: after.userId, orderId, points, type: 'earn', createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(orderRef, { pointsEarned: points });
    tx.update(userRef, { loyaltyPoints: FieldValue.increment(points) });
    tx.set(
      statsRef,
      { orderCount: FieldValue.increment(1), revenue: FieldValue.increment(after.total), topItems },
      { merge: true },
    );
  });
});

// 3) Reservations
exports.onReservationCreated = onDocumentCreated('reservations/{id}', async (event) => {
  const r = event.data.data();
  await getMessaging().send({
    topic: 'staff',
    notification: { title: 'New table request', body: `${r.partySize} guests \u00b7 ${r.customerName || 'Customer'}` },
    data: { reservationId: event.params.id },
  });
});

exports.onReservationUpdated = onDocumentUpdated('reservations/{id}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return;
  const text = {
    confirmed: 'Your table is confirmed. We look forward to seeing you!',
    declined: 'Sorry, we could not confirm your table. Please try another time.',
  }[after.status];
  if (text) await notifyUser(after.userId, 'Addis Delight', text, { reservationId: event.params.id });
});
