import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/data/auth_repository.dart';
import '../cart/cart_bloc.dart';
import 'order_models.dart';

class OrderRepository {
  OrderRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');

  /// Generated up front so a retry after a timeout reuses the same id (no duplicate orders).
  String newOrderId() => _orders.doc().id;

  /// The totals sent here are only an estimate. The onOrderCreated Cloud Function
  /// re-prices every line from the menu and writes the real totals.
  Future<void> placeOrder({
    required String orderId,
    required AppUser user,
    required OrderType type,
    required List<CartLine> lines,
    required String phone,
    String? address,
    String? notes,
  }) {
    final subtotal = lines.fold<int>(0, (sum, l) => sum + l.total);
    return _orders.doc(orderId).set({
      'userId': user.uid,
      'customerName': user.name,
      'customerPhone': phone,
      'type': type.name,
      'status': OrderStatus.pending.name,
      'items': [
        for (final l in lines)
          {
            'itemId': l.item.id,
            'name': l.item.name,
            'unitPrice': l.item.priceEtb,
            'qty': l.qty,
            'note': '',
          },
      ],
      'subtotal': subtotal,
      'deliveryFee': 0,
      'total': subtotal,
      'address': address,
      'notes': notes,
      'paymentMethod': 'cash',
      'pointsEarned': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<AppOrder?> watchOrder(String id) =>
      _orders.doc(id).snapshots().map((d) => d.exists ? AppOrder.fromDoc(d) : null);

  /// Needs composite index: orders(userId asc, createdAt desc).
  Stream<List<AppOrder>> watchMyOrders(String uid) => _orders
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs.map(AppOrder.fromDoc).toList());

  /// Staff queue. Needs composite index: orders(status asc, createdAt asc).
  Stream<List<AppOrder>> watchActiveOrders() => _orders
      .where('status', whereIn: [
        OrderStatus.pending.name,
        OrderStatus.accepted.name,
        OrderStatus.preparing.name,
        OrderStatus.ready.name,
        OrderStatus.outForDelivery.name,
      ])
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(AppOrder.fromDoc).toList());

  Future<void> updateStatus(String orderId, OrderStatus status) => _orders.doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Stream<Map<String, dynamic>> watchDailyStats(String dateKey) =>
      _db.collection('dailyStats').doc(dateKey).snapshots().map((d) => d.data() ?? {});
}
