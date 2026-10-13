import 'package:flutter/material.dart' show IconData, Icons;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum OrderType { takeaway, dineIn, delivery }

enum OrderStatus { pending, accepted, preparing, ready, outForDelivery, completed, cancelled }

extension OrderTypeX on OrderType {
  String get label => switch (this) {
        OrderType.takeaway => 'Takeaway',
        OrderType.dineIn => 'Dine-in',
        OrderType.delivery => 'Delivery',
      };
}

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending => 'Pending',
        OrderStatus.accepted => 'Accepted',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready',
        OrderStatus.outForDelivery => 'Out for delivery',
        OrderStatus.completed => 'Completed',
        OrderStatus.cancelled => 'Cancelled',
      };

  IconData get iconData => switch (this) {
        OrderStatus.pending => Icons.hourglass_empty,
        OrderStatus.accepted => Icons.thumb_up_alt_outlined,
        OrderStatus.preparing => Icons.soup_kitchen_outlined,
        OrderStatus.ready => Icons.check_circle_outline,
        OrderStatus.outForDelivery => Icons.delivery_dining,
        OrderStatus.completed => Icons.done_all,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };

  /// Next status in the kitchen workflow, or null when the order is finished.
  OrderStatus? next(OrderType type) => switch (this) {
        OrderStatus.pending => OrderStatus.accepted,
        OrderStatus.accepted => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.ready,
        OrderStatus.ready =>
          type == OrderType.delivery ? OrderStatus.outForDelivery : OrderStatus.completed,
        OrderStatus.outForDelivery => OrderStatus.completed,
        _ => null,
      };

  /// Button text staff see for moving an order forward.
  String get actionLabel => switch (this) {
        OrderStatus.pending => 'Accept',
        OrderStatus.accepted => 'Start preparing',
        OrderStatus.preparing => 'Mark ready',
        OrderStatus.ready => 'Hand over',
        OrderStatus.outForDelivery => 'Mark delivered',
        _ => '',
      };
}

class OrderLine extends Equatable {
  const OrderLine({
    required this.itemId,
    required this.name,
    required this.unitPrice,
    required this.qty,
    this.note = '',
  });

  final String itemId;
  final String name;
  final int unitPrice;
  final int qty;
  final String note;

  factory OrderLine.fromMap(Map<String, dynamic> m) => OrderLine(
        itemId: m['itemId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        unitPrice: (m['unitPrice'] as num?)?.toInt() ?? 0,
        qty: (m['qty'] as num?)?.toInt() ?? 1,
        note: m['note'] as String? ?? '',
      );

  @override
  List<Object?> get props => [itemId, name, unitPrice, qty, note];
}

class AppOrder extends Equatable {
  const AppOrder({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.type,
    required this.status,
    required this.lines,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    this.address,
    this.notes,
    this.pointsEarned = 0,
    this.cancelReason,
  });

  final String id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final OrderType type;
  final OrderStatus status;
  final List<OrderLine> lines;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final DateTime createdAt;
  final String? address;
  final String? notes;
  final int pointsEarned;
  final String? cancelReason;

  factory AppOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return AppOrder(
      id: doc.id,
      userId: m['userId'] as String? ?? '',
      customerName: m['customerName'] as String? ?? '',
      customerPhone: m['customerPhone'] as String? ?? '',
      type: OrderType.values.firstWhere((t) => t.name == m['type'], orElse: () => OrderType.takeaway),
      status: OrderStatus.values
          .firstWhere((s) => s.name == m['status'], orElse: () => OrderStatus.pending),
      lines: ((m['items'] as List?) ?? const [])
          .map((e) => OrderLine.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: (m['subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (m['deliveryFee'] as num?)?.toInt() ?? 0,
      total: (m['total'] as num?)?.toInt() ?? 0,
      // createdAt is null for a moment while the server timestamp is pending.
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      address: m['address'] as String?,
      notes: m['notes'] as String?,
      pointsEarned: (m['pointsEarned'] as num?)?.toInt() ?? 0,
      cancelReason: m['cancelReason'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, lines, total, deliveryFee, pointsEarned, cancelReason];
}
