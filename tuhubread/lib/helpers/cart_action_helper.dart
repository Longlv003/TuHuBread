import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/cart/cart_cubit.dart';
import '../blocs/product_detail/product_detail_cubit.dart';
import '../blocs/product_detail/product_detail_state.dart';

/// Helper thêm sản phẩm hiện tại vào giỏ hàng mà không cần sửa logic ProductDetailCubit.
class CartActionHelper {
  CartActionHelper._();

  static bool addCurrentProductToCart(BuildContext context) {
    final detailState = context.read<ProductDetailCubit>().state;
    if (detailState is! ProductDetailLoaded) return false;

    context.read<CartCubit>().addFromProductDetail(detailState);
    return true;
  }
}
