// Usage: node tools/seed.js      (same credentials setup as set_role.js)
// Sample data only. Prices are placeholders, replace them with your real menu.
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

const categories = [
  { id: 'main', name: 'Main dishes', sortOrder: 1 },
  { id: 'fasting', name: 'Fasting (\u133e\u121d)', sortOrder: 2 },
  { id: 'breakfast', name: 'Breakfast', sortOrder: 3 },
  { id: 'drinks', name: 'Drinks', sortOrder: 4 },
];

const items = [
  { id: 'doro-wat', name: 'Doro Wat', description: 'Spicy chicken stew with egg, served with injera.', priceEtb: 450, categoryId: 'main' },
  { id: 'kitfo', name: 'Kitfo', description: 'Minced beef with mitmita and niter kibbeh.', priceEtb: 500, categoryId: 'main' },
  { id: 'tibs', name: 'Beef Tibs', description: 'Sauteed beef with onion, pepper and rosemary.', priceEtb: 420, categoryId: 'main' },
  { id: 'shiro', name: 'Shiro', description: 'Chickpea stew, a fasting favorite.', priceEtb: 220, categoryId: 'fasting', isFasting: true },
  { id: 'beyaynetu', name: 'Beyaynetu', description: 'Fasting platter with assorted vegan stews.', priceEtb: 300, categoryId: 'fasting', isFasting: true },
  { id: 'firfir', name: 'Firfir', description: 'Shredded injera in spicy sauce.', priceEtb: 200, categoryId: 'breakfast' },
  { id: 'macchiato', name: 'Macchiato', description: 'Ethiopian coffee with steamed milk.', priceEtb: 60, categoryId: 'drinks' },
  { id: 'spris', name: 'Spris juice', description: 'Layered avocado and mango juice.', priceEtb: 90, categoryId: 'drinks' },
];

(async () => {
  const batch = db.batch();
  categories.forEach(({ id, ...c }) => batch.set(db.doc(`menuCategories/${id}`), { ...c, isActive: true }));
  items.forEach(({ id, ...i }, idx) =>
    batch.set(db.doc(`menuItems/${id}`), { isAvailable: true, isFasting: false, imageUrl: null, sortOrder: idx + 1, ...i }));
  batch.set(db.doc('settings/restaurant'), { deliveryFeeEtb: 60, etbPerPoint: 10, openTime: '08:00', closeTime: '22:00' });
  await batch.commit();
  console.log('Seeded menu and settings.');
})();
