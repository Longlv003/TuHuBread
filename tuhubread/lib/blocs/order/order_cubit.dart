import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../models/order.model.dart';
import '../../models/order_item.model.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final ApiService apiService;

  OrderCubit({required this.apiService}) : super(const OrderInitial());

  Future<void> loadOrders() async {
    emit(const OrderLoading());
    try {
      final res = await apiService.get('/api/orders');
      if (res['data'] != null) {
        final List<dynamic> data = res['data'] as List<dynamic>;
        final orders = data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
        emit(OrderLoaded(orders));
      } else {
        emit(OrderFailure(res['msg'] ?? 'Lỗi tải danh sách đơn hàng'));
      }
    } catch (e) {
      emit(OrderFailure(e.toString()));
    }
  }

  Future<void> loadOrderDetail(String orderId) async {
    emit(const OrderLoading());
    try {
      final res = await apiService.get('/api/orders/$orderId');
      if (res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        
        final orderMap = data['order'] as Map<String, dynamic>;
        final order = OrderModel.fromJson(orderMap);

        final List<dynamic> itemsList = data['items'] as List<dynamic>;
        final items = itemsList.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList();

        emit(OrderDetailLoaded(order: order, items: items));
      } else {
        emit(OrderFailure(res['msg'] ?? 'Lỗi tải chi tiết đơn hàng'));
      }
    } catch (e) {
      emit(OrderFailure(e.toString()));
    }
  }

  /// Lấy danh sách sản phẩm của 1 đơn hàng — dùng khi mở sheet chọn sản phẩm
  /// để đánh giá. Gọi API trực tiếp, KHÔNG emit state, để không làm mất màn
  /// hình danh sách đơn hàng đang hiển thị (OrderLoaded) trong lúc chờ.
  Future<List<OrderItemModel>> fetchOrderItems(String orderId) async {
    try {
      final res = await apiService.get('/api/orders/$orderId');
      if (res['data'] == null) return [];
      final data = res['data'] as Map<String, dynamic>;
      final itemsList = data['items'] as List<dynamic>? ?? [];
      return itemsList
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Gửi đánh giá cho 1 SẢN PHẨM cụ thể trong đơn hàng đã hoàn thành — cập
  /// nhật lại đúng đơn/item đó (không cần tải lại toàn bộ lịch sử).
  Future<bool> submitReview(
    String orderId, {
    required String productId,
    required int rating,
    String? comment,
    List<XFile> images = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'product_id': productId,
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
        'images': [
          for (final img in images)
            await MultipartFile.fromFile(img.path, filename: img.name),
        ],
      });
      final res = await apiService.post('/api/orders/$orderId/review', formData);
      if (res['data'] == null) return false;

      final currentState = state;
      if (currentState is OrderLoaded) {
        final updatedOrders = currentState.orders.map((o) {
          if (o.id != orderId) return o;
          return o.copyWith(reviewedCount: (o.reviewedCount + 1).clamp(0, o.itemsCount));
        }).toList();
        emit(OrderLoaded(updatedOrders));
      } else if (currentState is OrderDetailLoaded &&
          currentState.order.id == orderId) {
        final updatedOrder = currentState.order.copyWith(
          reviewedCount: (currentState.order.reviewedCount + 1)
              .clamp(0, currentState.order.itemsCount),
        );
        final updatedItems = currentState.items.map((it) {
          if (it.productId != productId) return it;
          return it.copyWith(isReviewed: true);
        }).toList();
        emit(currentState.copyWith(order: updatedOrder, items: updatedItems));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    if (state is! OrderDetailLoaded) return false;
    final current = state as OrderDetailLoaded;

    emit(current.copyWith(isCancelling: true));
    try {
      final res = await apiService.put('/api/orders/$orderId/cancel', {});
      if (res['data'] != null) {
        // Cập nhật lại UI sau khi hủy thành công
        final updatedOrderMap = res['data'] as Map<String, dynamic>;
        final updatedOrder = OrderModel.fromJson({
          ...current.order.toJsonMock(), // Dùng helper để giữ lại dữ liệu populate của shop & address
          'order_status': 'cancelled',
          'payment_status': updatedOrderMap['payment_status'] ?? current.order.paymentStatus,
        });

        emit(OrderDetailLoaded(order: updatedOrder, items: current.items, isCancelling: false));
        return true;
      } else {
        emit(OrderDetailLoaded(order: current.order, items: current.items, isCancelling: false));
        return false;
      }
    } catch (e) {
      emit(OrderDetailLoaded(order: current.order, items: current.items, isCancelling: false));
      return false;
    }
  }
}

// Bổ sung helper để dễ clone dữ liệu cũ khi cập nhật trạng thái đơn hàng
extension OrderModelExtension on OrderModel {
  Map<String, dynamic> toJsonMock() {
    return {
      '_id': id,
      'order_code': orderCode,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'order_status': orderStatus,
      'items_total': itemsTotal,
      'discount_amount': discountAmount,
      'delivery_fee': deliveryFee,
      'total_amount': totalAmount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'shop': {
        'shop_name': shopName,
        'logo': shopLogo,
        'phone': shopPhone,
      },
      'address_id': {
        'receiver_name': receiverName,
        'receiver_phone': receiverPhone,
        'address_detail': addressDetail,
      },
      'items_count': itemsCount,
      'reviewed_count': reviewedCount,
    };
  }
}
